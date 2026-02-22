# WebSockets in Kronix

Kronix provides a first-class, matured WebSocket implementation that integrates seamlessly with the framework's routing, middleware, and dependency injection systems.

## Features

- **Protocol Upgrade Handling**: Automatic detection and upgrading of HTTP requests.
- **WebSocketConnection Wrapper**: High-level API for sending/receiving data with automatic JSON encoding.
- **Global WebSocketHub**: Centralized registry for managing all active connections.
- **Room Support**: Channel-based broadcasting for building chat rooms or scoped updates.
- **Middleware Integration**: Protect WebSocket entry points with same authentication and validation logic as HTTP routes.

## Basic Usage

Define a WebSocket route using `app.ws()`:

```dart
app.ws('/chat', (conn) {
  print('New connection: ${conn.id}');

  conn.listen((data) {
    print('Received: $data');
    conn.send({'status': 'received', 'echo': data});
  });
});
```

## The WebSocketHub

The `WebSocketHub` is a singleton service registered in the global container that tracks all active connections.

### Global Broadcast

```dart
app.wsHub.broadcast('System maintenance starting in 5 minutes.');
```

### Room Broadcasting

Clients can join "rooms" to receive targeted messages:

```dart
app.ws('/rooms', (conn) {
  conn.join('news_updates');
});

// Elsewhere in your app
app.wsHub.toRoom('news_updates', 'New article published!');
```

## Middleware Protection

Apply middleware to WebSocket routes to handle authentication:

```dart
app.ws('/secure-chat', (conn) {
  // Only reached if authMiddleware passes
}, middleware: [authMiddleware()]);
```

If a middleware returns a `Response` (e.g., 401 Unauthorized), the WebSocket upgrade is aborted, and the HTTP response is sent instead.

## Lifecycle and Cleanup

When a client disconnects, the connection is automatically removed from the `WebSocketHub`. You can also listen for the `onDone` event:

```dart
conn.listen((data) => ..., onDone: () {
  print('Client left.');
});
```
