<p align="center">
  <img src="https://raw.githubusercontent.com/Garv1Gyanani/dartx/main/assets/kronix_logo.png" width="300" alt="Kronix Logo">
</p>

# 🐍 Kronix
### The Architecturally Hardened Web Framework for Dart.

[![pub package](https://img.shields.io/pub/v/kronix.svg)](https://pub.dev/packages/kronix)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Build Status](https://img.shields.io/badge/Performance-Optimized-brightgreen)](https://github.com/garv/kronix)

Kronix is a high-performance, batteries-included web framework for the Dart ecosystem. It is designed for developers who demand **speed**, **type-safety**, and **architectural integrity** without the boilerplate of traditional enterprise frameworks.

---

## 🚀 Key Features

- **⚡ Radix-Trie Router**: O(log n) path matching with pre-compiled middleware chains.
- **🏗️ Sophisticated DI**: Hierarchical Dependency Injection with automatic request scoping.
- **📦 Advanced ORM**: Active Record pattern with typed relationships (`belongsTo`, `hasMany`).
- **🛡️ HARDENED Security**: Built-in backpressure control, body size limits, and JWT/Session support.
- **🚄 Unified Caching**: Elegant `Cache` facade supporting Memory and Redis drivers.
- **⚙️ CLI Power**: Rapid scaffolding of controllers, models (with migrations), and services.
- **🚥 Real-time**: First-class WebSocket support with Hubs, Rooms, and Middleware protection.

---

## 🏁 Quick Start

### 1. Installation

Add Kronix to your `pubspec.yaml`:

```yaml
dependencies:
  kronix: ^0.2.0
```

### 2. A Simple Server

```dart
import 'package:kronix/kronix.dart';

void main() async {
  final app = App();

  // Basic Route
  app.get('/welcome', (ctx) async {
    return Response.json({'message': 'Welcome to Kronix!'});
  });

  // Typed Validation
  app.post('/register', (ctx) async {
    final data = await ctx.validate({
      'email': 'required|email',
      'password': 'required|min:8',
    });
    
    return Response.json({'status': 'registered', 'user': data['email']});
  });

  await app.listen(port: 3000);
}
```

---

## 🛠️ Deep Dive

### 📦 The ORM (Model)
Define your relationships easily:

```dart
class User extends Model {
  @override String get tableName => 'users';
  
  // Relationship: User has many Posts
  Future<List<Post>> posts() => hasMany<Post>(Post.fromRow);
}
```

### 🚄 Caching
Switch from Memory to Redis with one line in `.env`:

```dart
// Fetch from cache or compute and store for 1 hour
final stats = await Cache.remember('users.count', Duration(hours: 1), () async {
  return await User.query().count();
});
```

### 🚥 Middleware
Compose logic across routes globally or in groups:

```dart
app.group('/api/v1', middleware: [AuthMiddleware()], callback: (router) {
  router.get('/profile', ProfileController().show);
});
```

---

## 💎 Why Kronix?

In a world of micro-frameworks, Kronix provides the **structure** needed for long-term maintainability. It is not just a router; it's a foundation that handles the "boring" parts of web development—security, concurrency, and data integrity—so you can focus on building your product.

- **Drained Gracefully**: Handles `SIGINT`/`SIGTERM` to allow active requests to finish.
- **Isolated Tests**: Built-in `MockHttpRequest` and container-swapping for 100% test coverage.
- **Type Casting**: Automatic conversion of query/body parameters to `int`, `double`, or `bool`.

---

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) to get started.

## 📄 License

Kronix is open-sourced software licensed under the [MIT license](LICENSE).
