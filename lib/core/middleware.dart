import 'context.dart';
import '../http/response.dart';
import 'router.dart';

/// A callback that invokes the next middleware in the pipeline.
typedef Next = Future<Response> Function();

/// A function used to intercept and process HTTP requests before they reach the final handler.
typedef Middleware = Future<Response> Function(Context ctx, Next next);

/// Manages a sequence of [Middleware] functions and their execution order.
class Pipeline {
  final List<Middleware> _middlewares = [];

  /// Adds a [middleware] to the end of the pipeline.
  void use(Middleware middleware) {
    _middlewares.add(middleware);
  }

  /// Executes the pipeline for the given [ctx], finishing with the [handler].
  Future<Response> exec(Context ctx, Handler handler) async {
    return compose(_middlewares, handler)(ctx);
  }

  /// Composes a list of [middlewares] and a final [handler] into a single [Handler].
  /// This pre-builds the execution chain for better performance.
  static Handler compose(List<Middleware> middlewares, Handler handler) {
    return (Context ctx) {
      int index = 0;
      
      Future<Response> next() async {
        if (index < middlewares.length) {
          return await middlewares[index++](ctx, next);
        }
        return await handler(ctx);
      }

      return next();
    };
  }
}

/// Utility class for middleware operations.
class MiddlewareHelper {
/// Wraps a [middleware] to ONLY execute if the request path matches [path].
static Middleware only(String path, Middleware middleware) {
  return (ctx, next) async {
    if (ctx.request.uri.path == path) {
      return await middleware(ctx, next);
    }
    return await next();
  };
}

/// Wraps a [middleware] to execute for all paths EXCEPT those starting with [prefix].
static Middleware except(String prefix, Middleware middleware) {
  return (ctx, next) async {
    if (ctx.request.uri.path.startsWith(prefix)) {
      return await next();
    }
    return await middleware(ctx, next);
  };
}

/// Wraps a [middleware] to execute for all paths EXCEPT those in the [paths] list.
static Middleware exceptMany(List<String> paths, Middleware middleware) {
  return (ctx, next) async {
    if (paths.contains(ctx.request.uri.path)) {
      return await next();
    }
    return await middleware(ctx, next);
  };
}
}
