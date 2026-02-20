import '../http/response.dart';
import 'middleware.dart';
import 'context.dart';

typedef Handler = Future<Response> Function(Context ctx);

class RouteData {
  final Handler handler;
  final List<Middleware> middleware;
  final String? name;

  RouteData(this.handler, {this.middleware = const [], this.name});
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

class Router {
  final RouteNode _root = RouteNode('/');
  final Map<String, String> _namedRoutes = {};
  
  // Internal state for building routes
  String _buildingPrefix = '';
  List<Middleware> _buildingMiddleware = [];

  void group(String prefix, {List<Middleware> middleware = const [], required void Function(Router) callback}) {
    final oldPrefix = _buildingPrefix;
    final oldMiddleware = List<Middleware>.from(_buildingMiddleware);

    _buildingPrefix = '$oldPrefix$prefix'.replaceAll('//', '/');
    _buildingMiddleware.addAll(middleware);

    callback(this);

    _buildingPrefix = oldPrefix;
    _buildingMiddleware = oldMiddleware;
  }

  void add(String method, String path, Handler handler, {List<Middleware> middleware = const [], String? name}) {
    final fullPath = '$_buildingPrefix$path'.replaceAll('//', '/');
    final allMiddleware = List<Middleware>.from(_buildingMiddleware)..addAll(middleware);

    if (name != null) {
      _namedRoutes[name] = fullPath;
    }

    List<String> segments = fullPath.split('/').where((s) => s.isNotEmpty).toList();
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
    
    // Pre-calculate the compiled handler for performance
    current.handlers[method.toUpperCase()] = RouteData(
      handler, 
      middleware: allMiddleware, 
      name: name
    );
  }

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

    for (String segment in segments) {
      if (current.children.containsKey(segment)) {
        current = current.children[segment]!;
      } else if (current.dynamicChild != null) {
        current = current.dynamicChild!;
        params[current.paramName!] = segment;
      } else if (current.wildcardChild != null) {
        current = current.wildcardChild!;
        break;
      } else {
        return (null, {});
      }
    }

    RouteData? data = current.handlers[method.toUpperCase()];
    return (data, params);
  }
}
