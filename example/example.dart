import 'package:kronix/kronix.dart';

/// This is the primary example for the Kronix framework.
/// 
/// It demonstrates the most common features used to build robust backends.
/// To run this example:
/// 1. Install dependencies: `dart pub get`
/// 2. Start the server: `dart run example/example.dart`
/// 3. Visit: `http://localhost:3000`

void main() async {
  final app = App();

  // --- Middleware ---
  // Apply a global logging middleware to track request performance.
  app.use((ctx, next) async {
    final start = DateTime.now();
    final response = await next();
    final ms = DateTime.now().difference(start).inMilliseconds;
    print('[${ctx.requestId}] ${ctx.request.method} ${ctx.request.uri} - ${response.statusCode} (${ms}ms)');
    return response;
  });

  // --- Basic Routing ---
  app.get('/', (ctx) async {
    return ctx.json({
      'framework': 'Kronix',
      'version': '0.1.2',
      'status': 'ready'
    });
  });

  // --- Route Groups & Validation ---
  app.group('/api/v1', callback: (router) {
    
    // Dynamic routing with parameters
    router.add('GET', '/user/:id', (ctx) async {
      final id = ctx.params['id'];
      return ctx.json({'user_id': id, 'status': 'active'});
    });

    // POST request with declarative validation
    router.add('POST', '/login', (ctx) async {
      final errors = ctx.validate({
        'username': 'required|min:3',
        'password': 'required|min:6',
      });

      if (errors.isNotEmpty) {
        return ctx.json({'errors': errors}, status: 422);
      }

      return ctx.json({'token': 'jwt_token_stub'});
    });
  });

  // --- WebSockets ---
  // Kronix provides first-class WebSocket support with room-based broadcasting.
  app.ws('/ws/chat', (conn) {
    print('WebSocket Client Connected: ${conn.id}');

    // Register interest in a room
    conn.join('global_chat');

    conn.listen((message) {
      // Broadcast specifically to the room
      app.wsHub.toRoom('global_chat', {
        'sender': conn.id,
        'message': message,
        'time': DateTime.now().toIso8601String()
      });
    });
  });

  // --- Start Server ---
  // The server will bind to the specified port and host.
  await app.listen(port: 3000, host: '0.0.0.0');
}
