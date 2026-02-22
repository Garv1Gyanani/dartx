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
    int index = 0;

    Future<Response> next() async {
      if (index < _middlewares.length) {
        final middleware = _middlewares[index++];
        return await middleware(ctx, next);
      } else {
        return await handler(ctx);
      }
    }

    return await next();
  }
}
