import 'context.dart';
import '../http/response.dart';
import 'router.dart';

typedef Next = Future<Response> Function();
typedef Middleware = Future<Response> Function(Context ctx, Next next);

class Pipeline {
  final List<Middleware> _middlewares = [];

  void use(Middleware middleware) {
    _middlewares.add(middleware);
  }

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
