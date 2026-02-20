# 🚀 DartX

**A high-performance, enterprise-grade web framework for Dart.**

DartX is a batteries-included backend framework inspired by **Laravel**, **Spring Boot**, and **NestJS** — built from the ground up in pure Dart. It provides a complete ecosystem for building production-ready APIs with clean architecture, robust error handling, and developer-first tooling.

---

## ✨ Features

| Layer | Feature | Description |
| :--- | :--- | :--- |
| 🛣 **Routing** | Trie-based Router | Named params, query params, nested groups, prefixes |
| 💉 **DI** | Hierarchical Containers | Singletons, factories, scoped services, request isolation |
| ✅ **Validation** | FormRequest System | Declarative rules (`required\|email\|min:8`), custom messages, auto 422 |
| 🛡 **Exceptions** | Exception Transformer | `HttpException` hierarchy (401–500), environment-aware rendering |
| 🗄 **Database** | PostgreSQL Adapter | Connection pooling, fluent Query Builder, scoped transactions |
| 📦 **Migrations** | Migration Runner | Timestamped migrations, batch rollback, CLI execution |
| ⚙ **Config** | `.env` Support | Typed config access with defaults |
| 📝 **Logging** | Structured Logger | Request correlation IDs, TTY-aware colors, pluggable drivers |
| 🔐 **Auth** | JWT Support | Token generation and verification |
| 🛠 **CLI** | Code Generator | Scaffold apps, controllers, services, middleware, requests, migrations |
| ♻ **Lifecycle**| Resource Disposal | Deterministic `Disposable` hook and async cleanup for request-scoped services |
| 📡 **Kernel** | Hardened Loop | Deterministic response closure and awaited lifecycle phases |
| 🧬 **Plugin** | Extensible | Native support for CORS, Rate Limiting, and Request Sizing |

---

## 🚀 Quick Start

```bash
# Scaffold a new app
dart run bin/dartx.dart create my_app

# Navigate and install
cd my_app
dart pub get

# Start with hot reload
dart run bin/dartx.dart watch
```

---

## 📖 Usage

### Routing
```dart
final app = App();

app.get('/hello', (ctx) async => ctx.json({'message': 'Hello DartX!'}));

app.group('/api/v1', callback: (router) {
  router.add('GET', '/users/:id', (ctx) async {
    return ctx.json({'userId': ctx.params['id']});
  });
});

await app.listen(port: 3000);
```

### Validation
```dart
class RegisterRequest extends FormRequest {
  @override
  Map<String, String> rules() => {
    'email': 'required|email',
    'password': 'required|min:8',
  };
}

app.post('/register', (ctx) async {
  final data = ctx.validate(RegisterRequest());
  return ctx.json({'user': data['email']});
});
```

### Exception Handling
```dart
// Throw semantic exceptions — the framework handles the rest
app.get('/admin', (ctx) async {
  throw ForbiddenException('Admin access only');
  // → 403 {"message": "Admin access only"}
});
```

### Database
```dart
final users = await db.table('users')
    .where('active', '=', true)
    .orderBy('created_at', 'DESC')
    .limit(10)
    .get();
```

### Migrations
```bash
dart run bin/dartx.dart make:migration CreateUsersTable
dart run bin/dartx.dart migrate
dart run bin/dartx.dart migrate:rollback
```

---

## 🏗 Architecture

```
dartx/
├── lib/
│   ├── core/           # Kernel: Server, Router, Context, Logger, Config
│   ├── database/       # Adapter, Query Builder, Migrations
│   ├── di/             # Dependency Injection Container
│   ├── http/           # Request & Response
│   ├── auth/           # JWT Authentication
│   ├── orm/            # Model Layer
│   └── plugins/        # Rate Limiter, CORS, Size Limit
├── bin/
│   ├── dartx.dart      # CLI Tool
│   └── templates.dart  # Code Generation Templates
└── example/            # Demo & Test Files
```

---

## 🧪 Test Results

```
========================================
   DARTX FRAMEWORK - MEGA TEST SUITE
========================================

--- ROUTING ---          9/9  ✅
--- VALIDATION ---       9/9  ✅
--- EXCEPTIONS ---       6/6  ✅
--- DI & SCOPING ---     2/2  ✅
--- DATABASE & ORM ---   3/3  ✅
--- MIDDLEWARE ---        2/2  ✅
--- CONFIG ---           1/1  ✅

========================================
   RESULTS: 32 PASSED / 0 FAILED
========================================
```

---

## 📄 License

MIT

---

Built with ❤️ in Dart.
