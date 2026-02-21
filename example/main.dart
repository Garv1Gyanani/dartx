import 'package:kronix/kronix.dart';

class LoggerMiddleware {
  static Future<Response> handle(Context ctx, Next next) async {
    print('[${DateTime.now()}] ${ctx.request.method} ${ctx.request.uri}');
    final response = await next();
    print('[${DateTime.now()}] Status: ${response.statusCode}');
    return response;
  }
}

void main() async {
  final app = App();

  // Middleware
  app.use(LoggerMiddleware.handle);

  // Routes
  app.get('/', (ctx) async {
    return ctx.text('Welcome to kronix Framework! 🚀');
  });

  app.get('/hello/:name', (ctx) async {
    final name = ctx.params['name'];
    return ctx.json({'message': 'Hello, $name!'});
  });

  app.post('/data', (ctx) async {
    final body = ctx.body;
    return ctx.json({
      'received': body,
      'status': 'success'
    });
  });

  await app.listen(port: 3000);
}
