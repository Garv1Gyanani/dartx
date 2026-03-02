import 'dart:async';
import '../http/response.dart';
import 'context.dart';
import 'logger.dart';
import 'middleware.dart';
import 'websocket.dart';

/// A function that handles a standard HTTP request and returns a response.
typedef Handler = Future<Response> Function(Context ctx);

/// A function that handles an active [WebSocketConnection].
typedef WebSocketHandler = FutureOr<void> Function(WebSocketConnection connection);

/// Holds the handler and metadata for a specific route.
class RouteData {
  /// Creates a new [RouteData] instance.
  RouteData({
    this.handler,
    this.wsHandler,
    this.middleware = const [],
    this.name,
    required this.method,
    required this.path,
  });

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

  /// A short summary of what the route does.
  String? summary;

  /// A detailed description of the route.
  String? description;

  /// Arbitrary metadata for the route (e.g., tags, security requirements).
  final Map<String, dynamic> metadata = <String, dynamic>{};

  /// Pre-built execution chain for this route.
  Handler? _compiledHandler;

  /// Compiles the route's middleware into a single executable chain.
  void compile() {
    final h = handler;
    if (h != null) {
      _compiledHandler = Pipeline.compose(middleware, h);
    }
  }

  /// Returns the pre-compiled execution chain.
  Handler? get compiledHandler => _compiledHandler;

  /// Returns `true` if this route is a WebSocket entry point.
  bool get isWebSocket => wsHandler != null;

  /// Fluent method to set the route [summary].
  RouteData setSummary(String text) {
    summary = text;
    return this;
  }

  /// Fluent method to set the route [description].
  RouteData setDescription(String text) {
    description = text;
    return this;
  }

  /// Fluent method to add custom [metadata] entries.
  RouteData setMeta(String key, dynamic value) {
    metadata[key] = value;
    return this;
  }
}

/// A node in the routing trie.
class RouteNode {
  /// Creates a new [RouteNode] for the given [segment].
  RouteNode(this.segment);

  /// The path segment this node represents.
  final String segment;

  /// Static children of this node.
  final Map<String, RouteNode> children = <String, RouteNode>{};

  /// Handlers registered at this path, indexed by HTTP method.
  final Map<String, RouteData> handlers = <String, RouteData>{};

  /// The parameter name if this is a dynamic segment (e.g., "id" for ":id").
  String? paramName;

  /// The child node for dynamic segments.
  RouteNode? dynamicChild;

  /// The child node for wildcard segments.
  RouteNode? wildcardChild;
}

/// The core routing engine for Kronix.
///
/// The [Router] uses a Trie-based structure to efficiently match incoming
/// paths to their registered [RouteData]. It supports route grouping,
/// middleware, and named parameters.
class Router {
  /// Creates a new [Router] instance.
  Router();

  final RouteNode _root = RouteNode('/');
  final Map<String, String> _namedRoutes = <String, String>{};
  final List<RouteData> _allRoutes = <RouteData>[];

  /// Returns all registered routes and their metadata.
  List<RouteData> get allRoutes => List<RouteData>.unmodifiable(_allRoutes);

  // Internal state for building routes
  String _buildingPrefix = '';
  List<Middleware> _buildingMiddleware = <Middleware>[];

  /// Registers a group of routes sharing a common [prefix] and set of [middleware].
  void group(
    String prefix, {
    List<Middleware> middleware = const [],
    required void Function(Router) callback,
  }) {
    final oldPrefix = _buildingPrefix;
    final oldMiddleware = List<Middleware>.from(_buildingMiddleware);

    _buildingPrefix = '$oldPrefix$prefix'.replaceAll('//', '/');
    _buildingMiddleware.addAll(middleware);

    callback(this);

    _buildingPrefix = oldPrefix;
    _buildingMiddleware = oldMiddleware;
  }

  /// Registers a standard HTTP route and returns its [RouteData].
  RouteData add(
    String method,
    String path,
    Handler handler, {
    List<Middleware> middleware = const [],
    String? name,
  }) {
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
      path: fullPath,
    );
    _registerRoute(fullPath, method, data);
    return data;
  }

  /// Registers a WebSocket route and returns its [RouteData].
  ///
  /// WebSocket routes are matched when an incoming request has the
  /// `Upgrade: websocket` header.
  RouteData ws(
    String path,
    WebSocketHandler handler, {
    List<Middleware> middleware = const [],
    String? name,
  }) {
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
      path: fullPath,
    );
    _registerRoute(fullPath, 'WS', data);
    return data;
  }

  void _registerRoute(String path, String method, RouteData data) {
    _allRoutes.add(data);

    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    var current = _root;

    for (final segment in segments) {
      if (segment.startsWith(':')) {
        final paramName = segment.substring(1);
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

    data.compile();
    current.handlers[method.toUpperCase()] = data;
  }

  /// Shorthand to register a GET route.
  RouteData get(
    String path,
    Handler handler, {
    List<Middleware> middleware = const [],
    String? name,
  }) =>
      add('GET', path, handler, middleware: middleware, name: name);

  /// Shorthand to register a POST route.
  RouteData post(
    String path,
    Handler handler, {
    List<Middleware> middleware = const [],
    String? name,
  }) =>
      add('POST', path, handler, middleware: middleware, name: name);

  /// Shorthand to register a PUT route.
  RouteData put(
    String path,
    Handler handler, {
    List<Middleware> middleware = const [],
    String? name,
  }) =>
      add('PUT', path, handler, middleware: middleware, name: name);

  /// Shorthand to register a DELETE route.
  RouteData delete(
    String path,
    Handler handler, {
    List<Middleware> middleware = const [],
    String? name,
  }) =>
      add('DELETE', path, handler, middleware: middleware, name: name);

  /// Shorthand to register a PATCH route.
  RouteData patch(
    String path,
    Handler handler, {
    List<Middleware> middleware = const [],
    String? name,
  }) =>
      add('PATCH', path, handler, middleware: middleware, name: name);

  /// Generates a URL for the given route [name] and [params].
  String? url(String name, {Map<String, dynamic> params = const {}}) {
    final path = _namedRoutes[name];
    if (path == null) return null;

    var result = path;
    params.forEach((key, value) {
      result = result.replaceFirst(':$key', value.toString());
    });
    return result;
  }

  /// Matches the given [method] and [uri] against registered routes.
  ///
  /// Returns a tuple containing the [RouteData] and a map of path parameters.
  (RouteData?, Map<String, String>) match(String method, Uri uri) {
    final segments = uri.path.split('/').where((s) => s.isNotEmpty).toList();
    final params = <String, String>{};
    var current = _root;

    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];
      if (current.children.containsKey(segment)) {
        current = current.children[segment]!;
      } else if (current.dynamicChild != null) {
        current = current.dynamicChild!;
        params[current.paramName!] = segment;
      } else if (current.wildcardChild != null) {
        current = current.wildcardChild!;
        params['*'] = segments.sublist(i).join('/');
        break;
      } else {
        return (null, <String, String>{});
      }
    }

    final data = current.handlers[method.toUpperCase()];
    return (data, params);
  }

  /// Prints all registered routes to the logger.
  void printRoutes() {
    Logger.staticInfo('--- Registered Routes ---');
    for (final r in _allRoutes) {
      Logger.staticInfo(
        '${r.method.padRight(7)} ${r.path} ${r.name != null ? "[${r.name}]" : ""}',
      );
    }
    Logger.staticInfo('------------------------');
  }
}
