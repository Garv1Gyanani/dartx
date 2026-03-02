import 'package:kronix/kronix.dart';

/// A comprehensive example showing the core features of Kronix:
/// Routing, Middleware, Validation, Dependency Injection, and WebSockets.

void main() async {
  final app = App();

  // 1. Global Middleware
  app.use((ctx, next) async {
    final start = DateTime.now();
    final response = await next();
    final ms = DateTime.now().difference(start).inMilliseconds;
    print('[${ctx.requestId}] ${ctx.request.method} ${ctx.request.uri} - ${response.statusCode} (${ms}ms)');
    return response;
  });

  // 2. Simple Routing
  app.get('/', (ctx) async {
    return ctx.json({
      'framework': 'Kronix',
      'status': 'operational',
      'documentation': 'https://pub.dev/packages/kronix'
    });
  });

  // 3. Route Group with Middleware
  app.group('/api', callback: (router) {
    // Parameterized route
    router.add('GET', '/hello/:name', (ctx) async {
      final name = ctx.params['name'];
      return ctx.text('Hello, $name!');
    });

    // Validation Example
    router.add('POST', '/register', (ctx) async {
      final data = await ctx.validateData({
        'email': 'required|email',
        'password': 'required|min:8',
        'age': 'numeric|min:18'
      });

      return ctx.json({'message': 'User registered successfully', 'email': data['email']});
    });
  });

  // 4. WebSocket Implementation
  app.ws('/chat', (conn) {
    print('Client connected: ${conn.id}');

    // Join a room
    conn.join('lobby');

    conn.listen((data) {
      // Broadcast to everyone in the 'lobby'
      app.wsHub.toRoom('lobby', {
        'from': conn.id,
        'message': data,
        'timestamp': DateTime.now().toIso8601String(),
      });
    });

    // Handle disconnection
    conn.socket.done.then((_) => print('Client disconnected: ${conn.id}'));
  });

  // 5. Start Server
  // Default port is 3000 or from PORT env variable
  await app.listen(port: 3000);
}
