# DartX Framework

DartX is a high-performance, architecturally hardened web framework for the Dart ecosystem. It is designed for developers who require a structured, batteries-included environment for building scalable APIs with a focus on clean architecture, deterministic resource management, and robust error handling.

The framework draws inspiration from established patterns found in Laravel and NestJS, bringing type-safe dependency injection, fluent database interactions, and a declarative validation system to the Dart backend.

---

## Core Principles

*   **Deterministic Lifecycle**: Every request follows a strictly awaited lifecycle phase, ensuring that resource cleanup is predictable and socket closures are reliable.
*   **Hierarchical Dependency Injection**: Service isolation is maintained through request-scoped containers, preventing state leakage across concurrent requests.
*   **Developer Productivity**: Comprehensive CLI tools enable rapid scaffolding of controllers, models, and migrations, following standard naming conventions.
*   **Operational Integrity**: Built-in micro-benchmarking and structured logging provide immediate visibility into system performance and health.

---

## Technical Features

### Routing and Middleware
The framework utilizes a high-performance Trie-based router supporting named parameters, wildcard matching, and nested route groups. Every route can be protected by a chain of middleware, executed through an asynchronous pipeline.

### Validation System
DartX provides a declarative `FormRequest` system. Validation rules are defined using a descriptive string syntax (e.g., `required|email|min:8`) and are validated before reaching the controller logic, returning standardized 422 responses on failure.

### Database and Migrations
The database layer includes a fluent Query Builder for PostgreSQL. The migration system ensures schema evolution is atomic, utilizing a batch-based execution model that allows for reliable rollbacks.

### Resource Management
Services can implement the `Disposable` interface to hook into the framework's cleanup phase. When a request ends, the framework automatically triggers the disposal of all scoped resources, such as database sessions or file handles.

---

## Installation and Usage

### Project Scaffolding
Initialize a new project using the DartX CLI:

```bash
dart run bin/dartx.dart create project_name
cd project_name
dart pub get
```

### Server Implementation
Define routes and start the server:

```dart
import 'package:dartx/dartx.dart';

void main() async {
  final app = App();

  app.get('/api/status', (ctx) async {
    return ctx.json({'status': 'operational'});
  });

  await app.listen(port: 3000);
}
```

### Starting the Development Server
Use the built-in watcher for hot-reloading during development:

```bash
dart run bin/dartx.dart watch
```

---

## Performance Benchmarks

Based on internal micro-benchmarks conducted on standard hardware:

*   **Routing Latency**: ~1.3µs per match (tested against 1,000 routes).
*   **Validation Overhead**: ~2.7µs per object validation.
*   **Memory Footprint**: Optimized garbage collection through deterministic container disposal.

---

## License

This project is licensed under the MIT License.
