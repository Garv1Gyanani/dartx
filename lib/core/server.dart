import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'router.dart';
import 'middleware.dart';
import 'context.dart';
import 'logger.dart';
import 'config.dart';
import 'exception_handler.dart';
import '../di/container.dart';
import '../http/request.dart';
import '../http/response.dart';

import 'websocket.dart';
import 'package:mime/mime.dart';
import '../http/file.dart';
import '../filesystem/storage.dart';
import '../queue/queue.dart';
import '../queue/driver.dart';

/// The main entry point for a kronix application.
/// 
/// The [App] class manages the HTTP server lifecycle, routing registration,
/// and the global middleware pipeline.
class App {
  final Router _router = Router();
  final Pipeline _pipeline = Pipeline();
  final WebSocketHub _wsHub = WebSocketHub();
  HttpServer? _server;
  bool _isShuttingDown = false;
  int _activeHttpCounter = 0;
  int _activeWSCounter = 0;

  /// The global exception handler used to transform errors into responses.
  ExceptionHandler exceptionHandler = DefaultExceptionHandler();

  /// Provides access to the [Router] instance for manual route manipulation.
  Router get router => _router;

  /// Provides access to the global [WebSocketHub].
  WebSocketHub get wsHub => _wsHub;
  
  /// Returns the total number of active connections (HTTP + WebSocket).
  int get activeRequests => _activeHttpCounter + _activeWSCounter;

  /// Returns the number of active HTTP requests.
  int get activeHttpRequests => _activeHttpCounter;

  /// Returns the number of active WebSocket connections.
  int get activeWebSockets => _activeWSCounter;
  
  /// Initializes a new kronix application.
  /// 
  /// During initialization, the framework:
  /// 1. Loads configuration from `.env`.
  /// 2. Registers the [Router], [ExceptionHandler], and [WebSocketHub] into the global DI container.
  /// 3. Sets up system health and readiness routes.
  App() {
    Config.load();
    di.singleton(_router);
    di.singleton<ExceptionHandler>(exceptionHandler);
    di.singleton(_wsHub);
    di.singleton<Storage>(LocalStorage(
      root: Config.get('STORAGE_ROOT', 'storage')!,
      baseUrl: Config.get('STORAGE_URL', '/storage')!,
    ));
    
    // Resolve Queue driver from config
    final queueDriverName = Config.get('QUEUE_DRIVER', 'memory')!;
    final QueueDriver driver = _resolveQueueDriver(queueDriverName);
    di.singleton<Queue>(Queue(driver: driver));

    _setupDefaultRoutes();
  }

  QueueDriver _resolveQueueDriver(String name) {
    switch (name.toLowerCase()) {
      case 'memory':
        return MemoryQueueDriver();
      // In a real app, we'd have 'redis', 'db', etc. here
      default:
        Logger.staticWarning('Unknown queue driver "$name", falling back to memory.');
        return MemoryQueueDriver();
    }
  }

  void _setupDefaultRoutes() {
    get('/health', (ctx) async => ctx.json({'status': 'ok'}));
    get('/ready', (ctx) async => ctx.json({
      'status': _isShuttingDown ? 'down' : 'ok',
      'active_requests': activeRequests,
      'http_requests': _activeHttpCounter,
      'websockets': _activeWSCounter,
    }));
  }

  /// Registers a global [middleware] to be executed for every request.
  void use(Middleware middleware) {
    _pipeline.use(middleware);
  }

  /// Groups routes under a common [prefix] with optional [middleware].
  void group(String prefix, {List<Middleware> middleware = const [], required void Function(Router) callback}) {
    _router.group(prefix, middleware: middleware, callback: callback);
  }

  /// Registers a GET route.
  RouteData get(String path, Handler handler, {List<Middleware> middleware = const [], String? name}) => 
    _router.add('GET', path, handler, middleware: middleware, name: name);

  /// Registers a POST route.
  RouteData post(String path, Handler handler, {List<Middleware> middleware = const [], String? name}) => 
    _router.add('POST', path, handler, middleware: middleware, name: name);

  /// Registers a PUT route.
  RouteData put(String path, Handler handler, {List<Middleware> middleware = const [], String? name}) => 
    _router.add('PUT', path, handler, middleware: middleware, name: name);

  /// Registers a DELETE route.
  RouteData delete(String path, Handler handler, {List<Middleware> middleware = const [], String? name}) => 
    _router.add('DELETE', path, handler, middleware: middleware, name: name);

  /// Registers a PATCH route.
  RouteData patch(String path, Handler handler, {List<Middleware> middleware = const [], String? name}) => 
    _router.add('PATCH', path, handler, middleware: middleware, name: name);

  /// Registers a HEAD route.
  RouteData head(String path, Handler handler, {List<Middleware> middleware = const [], String? name}) => 
    _router.add('HEAD', path, handler, middleware: middleware, name: name);

  /// Registers an OPTIONS route.
  RouteData options(String path, Handler handler, {List<Middleware> middleware = const [], String? name}) => 
    _router.add('OPTIONS', path, handler, middleware: middleware, name: name);

  /// Registers a WebSocket endpoint at the specified [path].
  RouteData ws(String path, WebSocketHandler handler, {List<Middleware> middleware = const [], String? name}) => 
    _router.ws(path, handler, middleware: middleware, name: name);

  /// Starts the HTTP/WebSocket server and listens for incoming requests.
  Future<void> listen({int? port, String? host}) async {
    final serverPort = port ?? Config.getInt('PORT', 3000)!;
    final serverHost = host ?? Config.get('HOST', '0.0.0.0')!;
    
    try {
      _server = await HttpServer.bind(serverHost, serverPort, shared: true);
      Logger.staticInfo('🚀 Server started on http://$serverHost:$serverPort');
    } catch (e) {
      if (e is SocketException && (e.osError?.errorCode == 10048 || e.osError?.errorCode == 98)) {
        Logger.staticError('❌ Port $serverPort is already in use. Please ensure no other instances of the server are running.');
        // On Windows, errorCode 10048 is "Only one usage of each socket address is normally permitted"
        // On Linux, errorCode 98 is "Address already in use"
      } else {
        Logger.staticError('❌ Failed to start server: $e');
      }
      rethrow;
    }

    _handleGracefulShutdown();

    await for (HttpRequest rawRequest in _server!) {
      if (_isShuttingDown) {
        rawRequest.response.statusCode = 503;
        rawRequest.response.headers.set('content-type', 'application/json');
        rawRequest.response.write(jsonEncode({'message': 'Server is shutting down'}));
        await rawRequest.response.close();
        continue;
      }
      _handleRequest(rawRequest);
    }
  }

  /// Stops the server and releases all bound resources.
  Future<void> stop({bool force = false}) async {
  
     _isShuttingDown = true;
     await _server?.close(force: force);
  }

  void _handleGracefulShutdown() {
    ProcessSignal.sigint.watch().listen((_) => _shutdown());
    if (!Platform.isWindows) {
      ProcessSignal.sigterm.watch().listen((_) => _shutdown());
    }
  }

  Future<void> _shutdown() async {
    if (_isShuttingDown) return;
    _isShuttingDown = true;
    Logger.staticInfo('🛑 Shutting down server... Draining $activeRequests total connections.');

    // Stop accepting new connections but keep the socket pool alive for now
    final stopFuture = stop(force: false);
    
    int timeoutSeconds = 15;
    while (activeRequests > 0 && timeoutSeconds > 0) {
      await Future.delayed(Duration(seconds: 1));
      timeoutSeconds--;
      if (timeoutSeconds % 5 == 0 && timeoutSeconds > 0) {
        Logger.staticInfo('⏳ Waiting for $activeRequests connections... ($timeoutSeconds s remaining)');
      }
    }

    if (activeRequests > 0) {
      Logger.staticWarning('⚠️ Timeout reached. Forcing closure of $activeRequests connections.');
      await stop(force: true);
    } else {
      await stopFuture;
      Logger.staticInfo('👋 All connections drained. Server stopped.');
    }

    // Only exit if not in test environment or explicitly requested
    if (Config.get('APP_ENV') != 'test') {
      exit(0);
    }
  }

  Future<void> _handleRequest(HttpRequest rawRequest) async {
    final isWebSocket = WebSocketTransformer.isUpgradeRequest(rawRequest);
    
    // Strict Concurrency Control (Pre-increment to avoid races)
    if (isWebSocket) {
      _activeWSCounter++;
      final maxWS = Config.getInt('MAX_WS_CONNECTIONS', 1000)!;
      if (_activeWSCounter > maxWS) {
        _activeWSCounter--;
        rawRequest.response.statusCode = 503;
        await rawRequest.response.close();
        return;
      }
    } else {
      _activeHttpCounter++;
      final maxHttp = Config.getInt('MAX_CONCURRENT_REQUESTS', 100)!;
      if (_activeHttpCounter > maxHttp) {
        _activeHttpCounter--;
        rawRequest.response.statusCode = 503;
        rawRequest.response.headers.set('content-type', 'application/json');
        rawRequest.response.write(jsonEncode({
          'message': 'Service Unavailable',
          'error': 'Server is under high load. Please try again later.'
        }));
        await rawRequest.response.close();
        return;
      }
    }
    
    Context? ctx;
    bool isWSUpgradeHandled = false;

    try {
      final (routeData, params) = _router.match(isWebSocket ? 'WS' : rawRequest.method, rawRequest.uri);

      if (routeData == null) {
        rawRequest.response.statusCode = 404;
        if (!isWebSocket) {
          rawRequest.response.headers.set('content-type', 'application/json');
          rawRequest.response.write(jsonEncode({'message': 'Not Found'}));
        }
        await rawRequest.response.close();
        return;
      }

      // Parse body for non-WS requests
      Map<String, dynamic> body = {};
      Map<String, UploadedFile> files = {};
      
      if (!isWebSocket && (rawRequest.contentLength > 0 || rawRequest.headers.chunkedTransferEncoding)) {
        final (parsedBody, parsedFiles) = await _parseRequestContent(rawRequest);
        body = parsedBody;
        files = parsedFiles;
      }

      final request = Request(
        rawRequest: rawRequest,
        params: params,
        query: rawRequest.uri.queryParameters,
        body: body,
        files: files,
      );

      final requestContainer = di.child();
      ctx = Context(request, container: requestContainer);
      final logger = Logger.withContext(ctx);

      if (isWebSocket && routeData.isWebSocket) {
        isWSUpgradeHandled = true;
        // WS keeps the counter and context until socket is closed
        await _handleWebSocket(ctx, routeData);
        return;
      }

      final response = await _pipeline.exec(ctx, (lvlCtx) async {
        final routePipeline = Pipeline();
        for (var m in routeData.middleware) {
          routePipeline.use(m);
        }
        return await routePipeline.exec(lvlCtx, routeData.handler!);
      });
      
      await _sendResponse(rawRequest, ctx, response, logger);
    } catch (e) {
      if (isWebSocket && !isWSUpgradeHandled) {
        // WS upgrade failed before we handed off to _handleWebSocket
        try { await rawRequest.response.close(); } catch (_) {}
      } else if (!isWebSocket) {
        final response = ctx != null 
          ? exceptionHandler.render(ctx, e)
          : Response.json({'message': 'Bad Request', 'error': e.toString()}, status: 400);

        try {
          if (ctx != null) {
            await _sendResponse(rawRequest, ctx, response, Logger.withContext(ctx));
          } else {
            // Context-less response
            rawRequest.response.statusCode = response.statusCode;
            rawRequest.response.headers.set('content-type', 'application/json');
            rawRequest.response.write(jsonEncode(response.body ?? {'message': 'Error'}));
            await rawRequest.response.close();
          }
        } catch (_) {}
      }
    } finally {
      if (!isWSUpgradeHandled) {
        if (isWebSocket) {
          _activeWSCounter--;
        } else {
          _activeHttpCounter--;
        }
        if (ctx != null) {
          await ctx.dispose();
        }
      }
    }
  }

  Future<void> _handleWebSocket(Context ctx, RouteData routeData) async {
    try {
      final result = await _pipeline.exec(ctx, (lvlCtx) async {
        final routePipeline = Pipeline();
        for (var m in routeData.middleware) {
          routePipeline.use(m);
        }
        return await routePipeline.exec(lvlCtx, (c) async => Response(statusCode: 101));
      });

      if (result.statusCode != 101) {
        await _sendResponse(ctx.request.rawRequest, ctx, result, Logger.withContext(ctx));
        return;
      }

      final socket = await WebSocketTransformer.upgrade(ctx.request.rawRequest);
      final connection = WebSocketConnection(socket, ctx);
      _wsHub.register(connection);
      
      await routeData.wsHandler!(connection);
      
      // Wait for the socket to truly close
      await socket.done;
    } catch (e) {
      Logger.withContext(ctx).error('WebSocket upgrade failed: $e', error: e);
      try {
        await ctx.request.rawRequest.response.close();
      } catch (_) {}
    } finally {
      _activeWSCounter--;
      await ctx.dispose();
    }
  }

  Future<(Map<String, dynamic>, Map<String, UploadedFile>)> _parseRequestContent(HttpRequest request) async {
    final contentType = request.headers.contentType;
    final mimeType = contentType?.mimeType;
    final body = <String, dynamic>{};
    final files = <String, UploadedFile>{};

    if (mimeType == 'application/json') {
      final content = await utf8.decodeStream(request);
      if (content.isNotEmpty) {
        body.addAll(jsonDecode(content));
      }
    } else if (mimeType == 'application/x-www-form-urlencoded') {
      final content = await utf8.decodeStream(request);
      if (content.isNotEmpty) {
        body.addAll(Uri.splitQueryString(content));
      }
    } else if (mimeType == 'multipart/form-data') {
      final boundary = contentType?.parameters['boundary'];
      if (boundary != null) {
        final transformer = MimeMultipartTransformer(boundary);
        final parts = transformer.bind(request);
        
        final maxPartSize = Config.getInt('MAX_UPLOAD_SIZE_PER_PART', 10 * 1024 * 1024)!; 
        final maxTotalSize = Config.getInt('MAX_TOTAL_UPLOAD_SIZE', 50 * 1024 * 1024)!;

        int totalBytesAcrossParts = 0;

        await for (final part in parts) {
          final header = part.headers['content-disposition'];
          if (header == null) continue;

          final disp = HeaderValue.parse(header);
          final name = disp.parameters['name'];
          final filename = disp.parameters['filename'];

          if (filename != null && name != null) {
            // Create a temp directory that will be deleted along with the file
            final tempDir = Directory.systemTemp.createTempSync('kronix_');
            final safeFilename = 'up_${DateTime.now().millisecondsSinceEpoch}_${name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')}';
            final tempPath = '${tempDir.path}${Platform.pathSeparator}$safeFilename';
            
            final file = File(tempPath);
            final sink = file.openWrite();
            int currentPartBytes = 0;
            
            try {
              await for (final chunk in part) {
                currentPartBytes += chunk.length;
                totalBytesAcrossParts += chunk.length;
                
                if (currentPartBytes > maxPartSize) {
                  throw Exception('File "$filename" exceeds part limit of $maxPartSize bytes');
                }
                if (totalBytesAcrossParts > maxTotalSize) {
                  throw Exception('Total request upload exceeds limit of $maxTotalSize bytes');
                }
                sink.add(chunk);
              }
              await sink.close();

              files[name] = UploadedFile(
                filename: filename,
                contentType: part.headers['content-type'] ?? 'application/octet-stream',
                tempPath: tempPath,
                tempDir: tempDir.path,
                size: currentPartBytes,
              );
            } catch (e) {
              await sink.close();
              if (await tempDir.exists()) await tempDir.delete(recursive: true);
              rethrow;
            }
          } else if (name != null) {
            final content = await utf8.decodeStream(part);
            body[name] = content;
          }
        }
      }
    } else {
       // Default to raw content if unknown
       final content = await utf8.decodeStream(request);
       body['_raw'] = content;
    }

    return (body, files);
  }

  Future<void> _sendResponse(HttpRequest rawRequest, Context ctx, Response response, Logger logger) async {
    final duration = ctx.elapsed;
    
    try {
      final res = rawRequest.response;
      res.statusCode = response.statusCode;
      
      // Apply response headers
      for (final entry in response.headers.entries) {
        final k = entry.key.toLowerCase();
        if (k == 'content-type') {
          // Ensure charset=utf-8 is set for text types
          final ct = entry.value;
          if (ct.startsWith('text/') && !ct.contains('charset')) {
            res.headers.contentType = ContentType.parse('$ct; charset=utf-8');
          } else if (ct == 'application/json' && !ct.contains('charset')) {
            res.headers.contentType = ContentType.parse('$ct; charset=utf-8');
          } else {
            res.headers.contentType = ContentType.parse(ct);
          }
        } else if (k == 'location') {
          res.headers.set('location', entry.value);
        } else {
          res.headers.set(entry.key, entry.value);
        }
      }
      
      // Write body as UTF-8 bytes to avoid latin1 encoding errors
      if (response.body != null) {
        res.add(utf8.encode(response.body.toString()));
      }
      await res.close();
      
      logger.info('${rawRequest.method} ${rawRequest.uri.path} - ${response.statusCode} (${duration.inMilliseconds}ms)');
    } catch (e) {
      logger.error('Error writing response to socket: $e', error: e);
      rethrow;
    }
  }
}
