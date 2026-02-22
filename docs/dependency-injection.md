# Dependency Injection in Kronix

Kronix features a hierarchical inversion of control (IoC) container that supports different service lifecycles.

## Basic Registration

You can register services in the global `di` container.

```dart
import 'package:kronix/kronix.dart';

class DatabaseService {
  void connect() => print('Connected');
}

void main() {
  // Register as singleton
  di.singleton(DatabaseService());
  
  // Register with a factory (created every time)
  di.factory((container) => Logger());
}
```

## Lifecycles

1.  **Singleton**: Created once and shared across the entire application.
2.  **Lazy Singleton**: Created only when first requested, then shared.
3.  **Factory**: A new instance is created every time it's resolved.
4.  **Scoped**: Created once per HTTP request and disposed of at the end of the request.

```dart
// Scoped service
di.scoped((container) => TransactionRepository());
```

## Resolving Services

### Global Resolution
```dart
final db = di.resolve<DatabaseService>();
```

### Per-Request Resolution (Recommended)
Resolving from `ctx` ensures you get the request-scoped instance if one exists.

```dart
app.get('/users', (ctx) async {
  final repo = ctx.resolve<UserRepository>();
  return ctx.json(await repo.all());
});
```

## Named Registrations

```dart
di.singleton(MailService('smtp'), name: 'smtp');
di.singleton(MailService('sendgrid'), name: 'sendgrid');

// Resolve by name
final mail = di.resolve<MailService>(name: 'smtp');
```
