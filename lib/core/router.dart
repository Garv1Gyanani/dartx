import 'dart:async';
import '../http/response.dart';
import 'middleware.dart';
import 'context.dart';
import 'logger.dart';
import 'websocket.dart';

/// A function that handles a standard HTTP request and returns a response.
typedef Handler = Future<Response> Function(Context ctx);

/// A function that handles an active [WebSocketConnection].
typedef WebSocketHandler = FutureOr<void> Function(WebSocketConnection connection);

/// Holds the handler and metadata for a specific route.
class RouteData {
  /// The HTTP handler for this route, if applicable.
  final Handler? handler;

  /// The WebSocket handler for this route, if applicable.
  final WebSocketHandler? wsHandler;

  /// The list of middleware to be executed for this specific route.
  final List<Middleware> middleware;

  /// The optional name of the route, used for URL generation.
  final String? name;

  /// The HTTP method (GET, POST, etc.) or 'WS' for WebSockets.
  final String method;

  /// The full path pattern for this route.
  final String path;

  /// Creates a new [RouteData] instance.
  RouteData({
    this.handler,
    this.wsHandler,
    this.middleware = const [],
    this.name,
    required this.method,
    required this.path,
  });

  /// Returns `true` if this route is a WebSocket entry point.
  bool get isWebSocket => wsHandler != null;
}

class RouteNode {
  String segment;
  Map<String, RouteNode> children = {};
  Map<String, RouteData> handlers = {}; // method -> route data
  String? paramName;
  RouteNode? dynamicChild;
  RouteNode? wildcardChild;

  RouteNode(this.segment);
}

/// The core routing engine for Kronix.
/// 
/// The [Router] uses a Trie-based structure to efficiently match incoming
/// paths to their registered [RouteData]. It supports route grouping, 
/// middleware, and named parameters.
class Router {
  final RouteNode _root = RouteNode('/');
  final Map<String, String> _namedRoutes = {};
  final List<RouteData> _allRoutes = [];
  
  // Internal state for building routes
  String _buildingPrefix = '';
  List<Middleware> _buildingMiddleware = [];

  /// Registers a group of routes sharing a common [prefix] and set of [middleware].
  void group(String prefix, {List<Middleware> middleware = const [], required void Function(Router) callback}) {
    final oldPrefix = _buildingPrefix;
    final oldMiddleware = List<Middleware>.from(_buildingMiddleware);

    _buildingPrefix = '$oldPrefix$prefix'.replaceAll('//', '/');
    _buildingMiddleware.addAll(middleware);

    callback(this);

    _buildingPrefix = oldPrefix;
    _buildingMiddleware = oldMiddleware;
  }

  /// Registers a standard HTTP route.
  void add(String method, String path, Handler handler, {List<Middleware> middleware = const [], String? name}) {
    final fullPath = '$_buildingPrefix$path'.replaceAll('//', '/');
    final allMiddleware = List<Middleware>.from(_buildingMiddleware)..addAll(middleware);

    if (name != null) {
      _namedRoutes[name] = fullPath;
    }

    final data = RouteData(
      handler: handler, 
      middleware: allMiddleware, 
      name: name,
      method: method.toUpperCase(),
      path: fullPath
    );
    _registerRoute(fullPath, method, data);
  }

  /// Registers a WebSocket route.
  /// 
  /// WebSocket routes are matched when an incoming request has the 
  /// `Upgrade: websocket` header.
  void ws(String path, WebSocketHandler handler, {List<Middleware> middleware = const [], String? name}) {
    final fullPath = '$_buildingPrefix$path'.replaceAll('//', '/');
    final allMiddleware = List<Middleware>.from(_buildingMiddleware)..addAll(middleware);

    if (name != null) {
      _namedRoutes[name] = fullPath;
    }

    final data = RouteData(
      wsHandler: handler,
      middleware: allMiddleware,
      name: name,
      method: 'WS',
      path: fullPath
    );
    _registerRoute(fullPath, 'WS', data);
  }

  void _registerRoute(String path, String method, RouteData data) {
    _allRoutes.add(data);

    List<String> segments = path.split('/').where((s) => s.isNotEmpty).toList();
    RouteNode current = _root;

    for (String segment in segments) {
      if (segment.startsWith(':')) {
        String paramName = segment.substring(1);
        current.dynamicChild ??= RouteNode(segment)..paramName = paramName;
        current = current.dynamicChild!;
      } else if (segment == '*') {
        current.wildcardChild ??= RouteNode('*');
        current = current.wildcardChild!;
      } else {
        current.children[segment] ??= RouteNode(segment);
        current = current.children[segment]!;
      }
    }
    
    current.handlers[method.toUpperCase()] = data;
  }

  // Shorthands
  void get(String path, Handler handler, {List<Middleware> middleware = const [], String? name}) => add('GET', path, handler, middleware: middleware, name: name);
  void post(String path, Handler handler, {List<Middleware> middleware = const [], String? name}) => add('POST', path, handler, middleware: middleware, name: name);
  void put(String path, Handler handler, {List<Middleware> middleware = const [], String? name}) => add('PUT', path, handler, middleware: middleware, name: name);
  void delete(String path, Handler handler, {List<Middleware> middleware = const [], String? name}) => add('DELETE', path, handler, middleware: middleware, name: name);
  void patch(String path, Handler handler, {List<Middleware> middleware = const [], String? name}) => add('PATCH', path, handler, middleware: middleware, name: name);

  String? url(String name, {Map<String, dynamic> params = const {}}) {
    String? path = _namedRoutes[name];
    if (path == null) return null;

    params.forEach((key, value) {
      path = path!.replaceFirst(':$key', value.toString());
    });
    return path;
  }

  (RouteData?, Map<String, String>) match(String method, Uri uri) {
    List<String> segments = uri.path.split('/').where((s) => s.isNotEmpty).toList();
    Map<String, String> params = {};
    RouteNode current = _root;

    for (int i = 0; i < segments.length; i++) {
      String segment = segments[i];
      if (current.children.containsKey(segment)) {
        current = current.children[segment]!;
      } else if (current.dynamicChild != null) {
        current = current.dynamicChild!;
        params[current.paramName!] = segment;
      } else if (current.wildcardChild != null) {
        current = current.wildcardChild!;
        // Capture trailing path for wildcard
        params['*'] = segments.sublist(i).join('/');
        break;
      } else {
        return (null, {});
      }
    }

    RouteData? data = current.handlers[method.toUpperCase()];
    return (data, params);
  }

  void printRoutes() {
    Logger.staticInfo('--- Registered Routes ---');
    for (var r in _allRoutes) {
      Logger.staticInfo('${r.method.padRight(7)} ${r.path} ${r.name != null ? "[${r.name}]" : ""}');
    }
    Logger.staticInfo('------------------------');
  }
}

