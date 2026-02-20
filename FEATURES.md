# 🚀 DartX Framework Documentation

DartX is a high-performance, enterprise-grade web framework for Dart, designed with a focus on **stability**, **productivity**, and **clean architecture**.

---

## 🛠 1. CLI & Scaffolding
The `dartx` CLI is the heart of the developer experience.

### Commands
| Command | Result |
| :--- | :--- |
| `dartx create <app_name>` | Scaffolds a complete project structure. |
| `dartx watch [file]` | Starts the server with high-performance hot reload. |
| `dartx make:controller <Name>` | Generates a controller in `app/controllers/`. |
| `dartx make:request <Name>` | Generates a validation class in `app/requests/`. |
| `dartx make:migration <Name>` | Generates a timestamped SQL migration. |
| `dartx migrate` | Executes all pending database migrations. |

---

## 🛣 2. Routing System
A Trie-based router supporting groups, prefixes, and named parameters.

```dart
final app = App();

app.group('/api/v1', callback: (router) {
  // Named parameter and group prefix
  router.get('/products/:id', (ctx) async {
    final id = ctx.params['id'];
    return ctx.json({'id': id});
  });
});

// URL generation by name
final path = di.resolve<Router>().url('user.show', params: {'id': '42'});
```

---

## 💉 3. Dependency Injection (DI)
Hierarchical containers for true **Request Isolation**.

```dart
// 1. Global Registration
di.singleton(PaymentService());
di.scoped((container) => RequestCounter());

// 2. Usage in Controller
app.get('/test', (ctx) async {
  // Resolved from the request-specific child container
  final counter = ctx.resolve<RequestCounter>();
  counter.increment();
  return ctx.json({'count': counter.count});
});
```

---

## 🛡 4. Validation & Form Requests
"The DartX Way" of handling input hygiene.

```dart
// app/requests/register_request.dart
class RegisterRequest extends FormRequest {
  @override
  Map<String, String> rules() => {
    'email': 'required|email',
    'password': 'required|min:8',
  };
}

// In Controller
app.post('/register', (ctx) async {
  // Short-circuits with 422 JSON if validation fails
  final data = ctx.validate(RegisterRequest());
  return ctx.json({'message': 'Passed!'});
});
```

---

## 📊 5. Database & ORM
A fluent SQL engine with automatic transaction management.

### Query Builder
```dart
final user = await db.table('users')
    .where('status', '=', 'active')
    .orderBy('created_at', 'DESC')
    .limit(10)
    .get();
```

### Automatic Transactions
Use the `transactionMiddleware` to ensure atomicity across your request.
```dart
app.post('/transfer', (ctx) async {
  return await db.transaction((tx) async {
    await tx.query('UPDATE accounts SET bal = bal - 10');
    await tx.query('UPDATE accounts SET bal = bal + 10');
    return ctx.json({'status': 'ok'});
  });
});
```

---

## 🛑 6. Exception Transformer
Deterministic error handling that varies by environment (`APP_ENV`).

```dart
app.get('/crash', (ctx) async {
  // This is automatically caught and turned into a JSON response
  throw NotFoundException('Item not found');
});

// Production Response: {"message": "Internal Server Error"}
// Dev Response: {"message": "...", "stack": "...", "type": "..."}
```

---

## 📝 7. Logging & Metrics
Structured logs with Request Correlation IDs.

```dart
// [2026-02-20T23:42:56] [requestId_123] INFO: GET /api - 200 (2ms)
Logger.staticInfo('Standard log');
Logger.withContext(ctx).info('Scoped log'); // Includes Request ID
```

---

## ⚙ 8. Configuration & Env
Typed access to your `.env` file.

```dart
final port = Config.getInt('PORT', 3000);
final isProd = Config.get('APP_ENV') == 'production';
```

---

## 🚪 9. Graceful Shutdown
Supports `SIGINT`/`SIGTERM` to safely close database pools and finish pending requests before exiting.
