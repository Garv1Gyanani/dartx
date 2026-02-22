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

### 2. ⚡ **High-Performance Routing**
Trie-based Radix router with support for:
*   Named parameters (`/users/:id`) and wildcards (`/files/*`).
*   Route grouping with inherited middleware.
*   Route naming for reverse URL generation.

### 3. 📦 **Advanced Queue System (Enterprise Platinum)**
Built for robustness and scale:
*   **Distributed Locking**: Atomic dequeue using `SKIP LOCKED` (supports multiple workers).
*   **Dead Letter Queue**: Automatically persist and retry failed jobs from a dashboard.
*   **Rate Limiting**: Control throughput via `maxJobsPerSecond`.
*   **Timeout Protection**: Automatically kill and retry hanging jobs.

### 4. 🗄️ **Database & Migrations**
*   **Fluent Query Builder**: Construct complex SQL without writing a line of it.
*   **Migrations**: Batch-based tracking with atomic rollbacks.
*   **Transactions**: Middleware support to wrap entire requests in a rollback-safe transaction.

### 5. 🔌 **Real-Time WebSockets**
Built-in `WebSocketHub` for managed real-time communication:
*   **Rooms**: Targeted broadcasting to specific groups.
*   **JSON Encoding**: Auto-serialization of Maps and Lists.
*   **Presence**: Track active connections globally.

### 6. 🛡️ **Validation & Auth**
*   **Declarative Rules**: `required|email|min:8|regex:...`
*   **JWT Auth**: Seamless token generation and middleware verification.
*   **Plugin System**: Rate limiting, CORS, and Body size limits included.

---

## 🚀 Quick Start

### 1. Define a Job
```dart
class SendEmailJob extends Job with SerializableJob {
  final String email;
  SendEmailJob(this.email);

  @override
  String get name => 'SendEmailJob';

  @override
  String serialize() => jsonEncode({'email': email});

  @override
  Future<void> handle() async {
    // Business logic...
  }
}
```

### 2. Start the Server
```dart
void main() async {
  final app = App();

  // Route with Validation & Middleware
  app.post('/register', (ctx) async {
    final data = ctx.validate(RegisterRequest());
    
    // Dispatch to background queue
    await ctx.queue.dispatch(SendEmailJob(data['email']));
    
    return ctx.json({'status': 'queued'});
  }, middleware: [auth.verify()]);

  // Start background worker
  await app.listen(port: 3000);
}
```

---

## 📊 Monitoring & Visibility

Kronix is built for production observability.

*   **Queue Metrics**: Real-time throughput, P95 processing times, and failure rates.
*   **Route Explorer**: Built-in UI to visualize all registered endpoints.
*   **Contextual Logging**: Every log entry is tagged with a unique `requestId` for easy tracing.

---

## 🛠 Installation

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
