# 🚀 Kronix Framework

[![Pub Version](https://img.shields.io/pub/v/kronix?color=blue&logo=dart)](https://pub.dev/packages/kronix)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**Kronix** is a high-performance, architecturally hardened web framework for Dart. Inspired by the best patterns from Laravel, NestJS, and Go's Gin, it brings enterprise-grade features like **Distributed Queues**, **Type-Safe ORM**, and **Stress-Tested Concurrency** to the Dart ecosystem.

---

## 🔥 Key Features

### 1. 🛡️ **Type-Safe Database & ORM**
*   **Model Base Class**: Automatic ID and timestamp (`created_at`, `updated_at`) management.
*   **Fluent Schema Builder**: Define migrations declaratively without raw SQL.
*   **Type-Safe Queries**: `ctx.query<User>(User.fromRow)` returns typed objects, not just maps.
*   **Atomic Transactions**: Request-scoped database executors with automatic rollback.

### 2. 🏗️ **Architectural Hardening**
*   **Hierarchical DI**: Parent/Child containers ensure 100% isolation between requests.
*   **Deterministic Cleanup**: Automatically deletes temp files and closes resources after response.
*   **Extreme Backpressure**: Configurable concurrency limits (rejection with 503) to prevent server crashes.

### 3. ✅ **Elite Validation Engine**
*   **Wildcard Support**: Validate complex nested structures like `items.*.price`.
*   **Clean Data**: Returns coerced and validated data types (booleans, integers) ready for use.
*   **Form Requests**: Decouple validation logic from controllers.

### 4. 📤 **Enterprise Queue System**
*   **SKIP LOCKED Dequeue**: Perfectly safe for distributed worker environments.
*   **Dead Letter Queue**: Built-in persistence for failing jobs with retry tracking.
*   **Metrics**: Real-time throughput and failure rate monitoring.

---

## 📦 Installation

Add `kronix` to your `pubspec.yaml`:

```yaml
dependencies:
  kronix: ^0.1.5
```

Then run:
```bash
dart pub get
```

---

## 🏁 Getting Started

### 1. Simple API
```dart
import 'package:kronix/kronix.dart';

void main() async {
  final app = App();

  app.get('/hello', (ctx) async {
    return ctx.json({'message': 'Hello, Kronix!'});
  });

  await app.listen(port: 3000);
}
```

### 2. Type-Safe Model Interaction
```dart
class User extends Model {
  @override String get tableName => 'users';
  String name;

  User({super.id, required this.name});

  factory User.fromRow(Map<String, dynamic> row) => 
      User(id: row['id'], name: row['name']);

  @override
  Map<String, dynamic> toMap() => {'name': name};
}

// In your controller
app.get('/users/:id', (ctx) async {
  final id = int.parse(ctx.params['id']);
  final user = await ctx.query<User>(User.fromRow).find(id);
  
  return user != null ? ctx.json(user) : ctx.json({'error': 'Not found'}, status: 404);
});
```

### 3. Fluent Migrations
```dart
class CreateUsersTable extends Migration {
  @override
  Future<void> up(DatabaseExecutor db) async {
    await Schema(db).create('users', (table) {
      table.id();
      table.string('name');
      table.string('email').unique();
      table.timestamps();
    });
  }
}
```

---

## 📊 Performance Benchmark
Kronix is built for scale. In our latest **Extreme Load** stress tests:
- **Concurrency**: Handled **10,000+** requests in a single burst with zero drops.
- **Throughput**: Peaked at **400+ req/s** on a single-thread local environment.
- **Draining**: Graceful shutdown drains active connections automatically before exit.

---

## 📄 License
Kronix is open-source software licensed under the [MIT license](LICENSE).
