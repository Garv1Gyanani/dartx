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
  
  /// The global exception handler used to transform errors into responses.
  ExceptionHandler exceptionHandler = DefaultExceptionHandler();

  /// Provides access to the [Router] instance for manual route manipulation.
  Router get router => _router;

  /// Provides access to the global [WebSocketHub].
  WebSocketHub get wsHub => _wsHub;

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
    _setupDefaultRoutes();
  }

  void _setupDefaultRoutes() {
    get('/health', (ctx) async => ctx.json({'status': 'ok'}));
    get('/ready', (ctx) async => ctx.json({'status': _isShuttingDown ? 'down' : 'ok'}));
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
    
    _server = await HttpServer.bind(serverHost, serverPort);
    Logger.staticInfo('🚀 Server started on http://$serverHost:$serverPort');

    _handleGracefulShutdown();

    await for (HttpRequest rawRequest in _server!) {
      if (_isShuttingDown) continue;
      _handleRequest(rawRequest);
    }
  }

  /// Stops the server and releases all bound resources.
  Future<void> stop() async {
     _isShuttingDown = true;
     await _server?.close(force: true);
  }

  void _handleGracefulShutdown() {
    ProcessSignal.sigint.watch().listen((_) => _shutdown());
    if (!Platform.isWindows) {
      ProcessSignal.sigterm.watch().listen((_) => _shutdown());
    }
  }

  Future<void> _shutdown() async {
    if (_isShuttingDown) return;
    Logger.staticInfo('🛑 Shutting down server...');
    await stop();
    Logger.staticInfo('👋 Server stopped.');
    // Only exit if not in test environment or explicitly requested
    if (Config.get('APP_ENV') != 'test') {
      exit(0);
    }
  }

  Future<void> _handleRequest(HttpRequest rawRequest) async {
    final isWebSocket = WebSocketTransformer.isUpgradeRequest(rawRequest);
    final (routeData, params) = _router.match(isWebSocket ? 'WS' : rawRequest.method, rawRequest.uri);

    if (routeData == null) {
      if (isWebSocket) {
         rawRequest.response.statusCode = 404;
         await rawRequest.response.close();
         return;
      }
      rawRequest.response.statusCode = 404;
      rawRequest.response.headers.set('content-type', 'application/json');
      rawRequest.response.write(jsonEncode({'message': 'Not Found'}));
      await rawRequest.response.close();
      return;
    }

    // Parse body for non-WS requests
    Map<String, dynamic> body = {};
    Map<String, UploadedFile> files = {};
    
    if (!isWebSocket && rawRequest.contentLength > 0) {
      try {
        final (parsedBody, parsedFiles) = await _parseRequestContent(rawRequest);
        body = parsedBody;
        files = parsedFiles;
      } catch (e) {
        rawRequest.response.statusCode = 400;
        rawRequest.response.headers.set('content-type', 'application/json');
        rawRequest.response.write(jsonEncode({'message': 'Malformed request body', 'error': e.toString()}));
        await rawRequest.response.close();
        return;
      }
    }

    final request = Request(
      rawRequest: rawRequest,
      params: params,
      query: rawRequest.uri.queryParameters,
      body: body,
      files: files,
    );

    // Create a child container for this request scope
    final requestContainer = di.child();
    final ctx = Context(request, container: requestContainer);
    final logger = Logger.withContext(ctx);
    
    try {
      if (isWebSocket && routeData.isWebSocket) {
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
       if (isWebSocket) {
          logger.error('WebSocket Error: $e', error: e);
          try {
            await rawRequest.response.close();
          } catch (_) {}
          return;
       }
      final response = exceptionHandler.render(ctx, e);
      try {
        await _sendResponse(rawRequest, ctx, response, logger);
      } catch (sendError) {
        // If we failed to send the error response, the connection is likely dead
        logger.error('Critical failure: Could not send error response: $sendError', error: sendError);
      }
    } finally {
      await ctx.dispose();
    }
  }

  Future<void> _handleWebSocket(Context ctx, RouteData routeData) async {
    // Run global middleware, then route middleware, then the upgrade
    try {
      // NOTE: Traditional middleware might not work as expected with WebSocket upgrades 
      // because they expect to return a Response object. 
      // For now, we allow them to run, and if any aborts/returns a response, we stop.
      
      final result = await _pipeline.exec(ctx, (lvlCtx) async {
        final routePipeline = Pipeline();
        for (var m in routeData.middleware) {
          routePipeline.use(m);
        }
        
        // We need a dummy handler to return a "null" response or similar if we reach the end
        return await routePipeline.exec(lvlCtx, (c) async => Response(statusCode: 101));
      });

      if (result.statusCode != 101) {
        // One of the middlewares returned a response (e.g. Auth failure)
        await _sendResponse(ctx.request.rawRequest, ctx, result, Logger.withContext(ctx));
        return;
      }

      final socket = await WebSocketTransformer.upgrade(ctx.request.rawRequest);
      final connection = WebSocketConnection(socket, ctx);
      
      // Register in global hub for broadcasting
      _wsHub.register(connection);
      
      await routeData.wsHandler!(connection);
    } catch (e) {
      Logger.withContext(ctx).error('WebSocket upgrade failed: $e', error: e);
      await ctx.request.rawRequest.response.close();
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
        await for (final part in parts) {
          final header = part.headers['content-disposition'];
          if (header == null) continue;

          final disp = HeaderValue.parse(header);
          final name = disp.parameters['name'];
          final filename = disp.parameters['filename'];

          if (filename != null && name != null) {
            final bytes = await part.fold<List<int>>([], (p, e) => p..addAll(e));
            files[name] = UploadedFile(
              filename: filename,
              contentType: part.headers['content-type'] ?? 'application/octet-stream',
              bytes: bytes,
            );
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
