import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'router.dart';
import 'middleware.dart';
import 'context.dart';
import 'logger.dart';
import 'config.dart';
import 'exceptions.dart';
import 'exception_handler.dart';
import '../di/container.dart';
import '../http/request.dart';
import '../http/response.dart';

class App {
  final Router _router = Router();
  final Pipeline _pipeline = Pipeline();
  HttpServer? _server;
  bool _isShuttingDown = false;
  ExceptionHandler exceptionHandler = DefaultExceptionHandler();

  Router get router => _router;

  App() {
    Config.load();
    di.singleton(_router);
    di.singleton<ExceptionHandler>(exceptionHandler);
    _setupDefaultRoutes();
  }

  void _setupDefaultRoutes() {
    get('/health', (ctx) async => ctx.json({'status': 'ok'}));
    get('/ready', (ctx) async => ctx.json({'status': _isShuttingDown ? 'down' : 'ok'}));
  }

  void use(Middleware middleware) {
    _pipeline.use(middleware);
  }

  void group(String prefix, {List<Middleware> middleware = const [], required void Function(Router) callback}) {
    _router.group(prefix, middleware: middleware, callback: callback);
  }

  void get(String path, Handler handler, {List<Middleware> middleware = const [], String? name}) => 
    _router.add('GET', path, handler, middleware: middleware, name: name);
  void post(String path, Handler handler, {List<Middleware> middleware = const [], String? name}) => 
    _router.add('POST', path, handler, middleware: middleware, name: name);
  void put(String path, Handler handler, {List<Middleware> middleware = const [], String? name}) => 
    _router.add('PUT', path, handler, middleware: middleware, name: name);
  void delete(String path, Handler handler, {List<Middleware> middleware = const [], String? name}) => 
    _router.add('DELETE', path, handler, middleware: middleware, name: name);

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

  void _handleGracefulShutdown() {
    ProcessSignal.sigint.watch().listen((_) => _shutdown());
    if (!Platform.isWindows) {
      ProcessSignal.sigterm.watch().listen((_) => _shutdown());
    }
  }

  Future<void> _shutdown() async {
    if (_isShuttingDown) return;
    _isShuttingDown = true;
    Logger.staticInfo('🛑 Shutting down server...');
    await _server?.close(force: false);
    Logger.staticInfo('👋 Server stopped.');
    exit(0);
  }

  Future<void> _handleRequest(HttpRequest rawRequest) async {
    final (routeData, params) = _router.match(rawRequest.method, rawRequest.uri);

    if (routeData == null) {
      rawRequest.response.statusCode = 404;
      rawRequest.response.write('Not Found');
      await rawRequest.response.close();
      return;
    }

    // Parse body...
    Map<String, dynamic> body = {};
    if (rawRequest.contentLength > 0 && rawRequest.headers.contentType?.mimeType == 'application/json') {
      try {
        final content = await utf8.decodeStream(rawRequest);
        body = jsonDecode(content);
      } catch (_) {}
    }

    final request = Request(
      rawRequest: rawRequest,
      params: params,
      query: rawRequest.uri.queryParameters,
      body: body,
    );

    // Create a child container for this request scope
    final requestContainer = di.child();
    final ctx = Context(request, container: requestContainer);
    final logger = Logger.withContext(ctx);
    
    try {
      final response = await _pipeline.exec(ctx, (lvlCtx) async {
        final routePipeline = Pipeline();
        for (var m in routeData.middleware) {
          routePipeline.use(m);
        }
        return await routePipeline.exec(lvlCtx, routeData.handler);
      });
      
      _sendResponse(rawRequest, ctx, response, logger);
    } catch (e) {
      final response = exceptionHandler.render(ctx, e);
      _sendResponse(rawRequest, ctx, response, logger);
    }
  }

  void _sendResponse(HttpRequest rawRequest, Context ctx, Response response, Logger logger) async {
    final duration = ctx.elapsed;
    logger.info('${rawRequest.method} ${rawRequest.uri.path} - ${response.statusCode} (${duration.inMilliseconds}ms)');

    rawRequest.response.statusCode = response.statusCode;
    response.headers.forEach((key, value) {
      rawRequest.response.headers.set(key, value);
    });
    
    if (response.body != null) {
      rawRequest.response.write(response.body);
    }
    await rawRequest.response.close();
  }
}
