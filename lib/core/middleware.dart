import '../http/response.dart';
import 'context.dart';
import 'router.dart';

/// A callback that invokes the next middleware in the pipeline.
typedef Next = Future<Response> Function();

/// A function used to intercept and process HTTP requests before they reach the final handler.
typedef Middleware = Future<Response> Function(Context ctx, Next next);

/// Manages a sequence of [Middleware] functions and their execution order.
class Pipeline {
  /// Creates a new [Pipeline] instance.
  Pipeline();

  final List<Middleware> _middlewares = <Middleware>[];

  /// Composes a list of [middlewares] and a final [handler] into a single [Handler].
  /// This pre-builds the execution chain for better performance.
  static Handler compose(List<Middleware> middlewares, Handler handler) {
    return (Context ctx) {
      var index = 0;

      Future<Response> next() {
        if (index < middlewares.length) {
          return middlewares[index++](ctx, next);
        }
        return handler(ctx);
      }

      return next();
    };
  }

  /// Adds a [middleware] to the end of the pipeline.
  void use(Middleware middleware) {
    _middlewares.add(middleware);
  }

  /// Executes the pipeline for the given [ctx], finishing with the [handler].
  Future<Response> exec(Context ctx, Handler handler) {
    return compose(_middlewares, handler)(ctx);
  }
}

/// Utility class for middleware operations.
class MiddlewareHelper {
  /// Creates a [MiddlewareHelper] instance.
  MiddlewareHelper();

  /// Wraps a [middleware] to ONLY execute if the request path matches [path].
  static Middleware only(String path, Middleware middleware) {
    return (ctx, next) async {
      if (ctx.request.uri.path == path) {
        return middleware(ctx, next);
      }
      return next();
    };
  }

  /// Wraps a [middleware] to execute for all paths EXCEPT those starting with [prefix].
  static Middleware except(String prefix, Middleware middleware) {
    return (ctx, next) async {
      if (ctx.request.uri.path.startsWith(prefix)) {
        return next();
      }
      return middleware(ctx, next);
    };
  }

  /// Wraps a [middleware] to execute for all paths EXCEPT those in the [paths] list.
  static Middleware exceptMany(List<String> paths, Middleware middleware) {
    return (ctx, next) async {
      if (paths.contains(ctx.request.uri.path)) {
        return next();
      }
      return middleware(ctx, next);
    };
  }
}
