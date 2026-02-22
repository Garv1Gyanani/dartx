# Middleware in Kronix

Middleware provides a convenient mechanism for filtering HTTP requests entering your application.

## Defining Middleware

Middleware is a simple function that receives a `Context` and a `Next` function.

```dart
import 'package:kronix/kronix.dart';

Future<Response> authMiddleware(Context ctx, Next next) async {
  final token = ctx.request.rawRequest.headers.value('Authorization');
  
  if (token == null || !token.startsWith('Bearer ')) {
    return ctx.json({'error': 'Unauthorized'}, status: 401);
  }
  
  // Proceed to the next middleware or handler
  return await next();
}
```

## Applying Middleware

### Global Middleware
Applies to every route in the application.

```dart
app.use(authMiddleware);
```

### Route-Level Middleware
Applies only to a specific route.

```dart
app.get('/admin', (ctx) async {
  return ctx.json({'msg': 'Welcome Admin'});
}, middleware: [authMiddleware]);
```

### Group Middleware
Applies to all routes within a group.

```dart
app.group('/admin', middleware: [authMiddleware], callback: (router) {
  router.get('/dashboard', (ctx) async => ...);
  router.get('/settings', (ctx) async => ...);
});
```

## Built-in Middleware

Kronix comes with several built-in plugins/middleware:

- **CORS**: `cors()`
- **Rate Limiter**: `RateLimiter(maxRequests: 100).handle()`
- **Request Size Limit**: `sizeLimit('1mb')`
- **JWT Auth**: `jwtAuth(secret: 'my-secret')`
