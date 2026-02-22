# 🚀 Kronix Framework

[![Pub Version](https://img.shields.io/pub/v/kronix?color=blue&logo=dart)](https://pub.dev/packages/kronix)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**Kronix** is a high-performance, architecturally hardened web framework for Dart. Inspired by the best patterns from Laravel, NestJS, and Go's Gin, it brings enterprise-grade features like **Distributed Queues**, **Type-Safe DI**, and **Fluent Database Interactions** to the Dart ecosystem.

---

## 🔥 Key Features

### 1. 🏗️ **Architectural Hardening**
*   **Hierarchical DI**: Request-scoped containers prevent state leakage.
*   **Deterministic Cleanup**: Auto-disposal of resources (DB connections, sockets).
*   **Context-Aware**: Access everything via `ctx` — request, response, di, storage, and queue.

### 2. ⚡ **API-First Routing**
Trie-based Radix router optimized for JSON APIs:
*   **Nested Groups**: Shared prefixes and middleware chains.
*   **Named Parameters**: Extract `/users/:id` or `/posts/:slug` instantly.
*   **Response Helpers**: `ctx.json()`, `ctx.html()`, `ctx.text()`, and `ctx.redirect()`.

### 3. 📤 **Multi-Part & File Uploads**
Native support for `multipart/form-data` without external parsing configuration:
*   **Auto-Parsed Files**: Access via `ctx.request.files['key']`.
*   **Storage Abstraction**: Save to local disk or cloud with one line: `file.saveAs('path')`.
*   **Validation**: Validate file sizes and MIME types effortlessly.

### 4. 🔌 **WebSocket Masterclass**
Full-duplex real-time communication with built-in state management:
*   **Rooms**: `connection.join('room_name')` for targeted broadcasting.
*   **Hub Management**: Global access to all active connections from any HTTP handler.
*   **Auto-JSON**: Send Maps/Lists directly without manual `jsonEncode`.

### 5. 📦 **Advanced Queue System (Enterprise Platinum)**
*   **Distributed Locking**: Atomic dequeue using `SKIP LOCKED`.
*   **Dead Letter Queue**: Automatically persist and retry failed jobs from a dashboard.
*   **Rate Limiting**: Control throughput via `maxJobsPerSecond`.
*   **Timeout Protection**: Kill hanging jobs automatically.

### 6. 🗄️ **Database & ORM**
*   **Fluent Query Builder**: Construct complex SQL with a chainable API.
*   **Batch Migrations**: Schema evolution with atomic tracking and rollbacks.
*   **Transactions**: Middleware support to wrap entire requests in a rollback-safe transaction.

---

## 🚀 Show Me The Code

### 📂 Handling Multi-Part Uploads
```dart
app.post('/upload', (ctx) async {
  final file = ctx.request.files['avatar'];
  
  if (file != null) {
    // Standardized file handling
    final path = await ctx.storage.put('avatars/${file.filename}', file.bytes);
    return ctx.json({'url': ctx.storage.url(path), 'size': file.size});
  }
  
  return ctx.json({'error': 'No file uploaded'}, status: 400);
});
```

### 🛰️ Real-Time Chat (WebSockets)
```dart
app.ws('/chat/:room', (connection) async {
  final room = connection.context.params['room'];
  connection.join(room);

  connection.listen((data) {
    // Broadcast to everyone in THIS room
    connection.context.wsHub.toRoom(room, {
      'from': connection.id,
      'message': data,
      'received_at': DateTime.now().toIso8601String(),
    });
  });
});
```

### 🛡️ Secure JSON API
```dart
app.group('/api', middleware: [Auth().verify()], callback: (router) {
  router.post('/posts', (ctx) async {
    // Automatic Validation
    final data = ctx.validate(PostRequest());
    
    // Database Interaction
    final id = await db.table('posts').insert(data);
    
    return ctx.json({'id': id, 'message': 'Post created!'}, status: 201);
  });
});
```

---

## 📊 Monitoring & Visibility

*   **Route Explorer**: Built-in UI to visualize all registered endpoints.
*   **Contextual Logging**: Every log entry is tagged with a unique `requestId`.
*   **Metrics Engine**: Track Queue throughput, P95 processing times, and failure rates.

---

## 📊 Installation

Add `kronix` to your `pubspec.yaml`:

```yaml
dependencies:
  kronix: ^0.1.4
```

---

## 📚 Documentation
- [Architecture Overview](KRONIX_OVERVIEW.md)
- [Queue System Guide](doc/queue.md)
- [Database & Migrations](doc/database.md)

---

## 📄 License
Kronix is open-source software licensed under the [MIT license](LICENSE).
