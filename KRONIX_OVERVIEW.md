# 🚀 Kronix Framework: Comprehensive Overview

Kronix is a high-performance, architecturally hardened web framework for Dart, inspired by the best patterns from Laravel, NestJS, and Go's Gin.

---

## 🛠 Features & Example Snippets

### 1. **Core HTTP & Routing**
Trie-based routing with support for middleware, groups, and named parameters.
```dart
final app = App();

app.group('/api/v1', middleware: [auth.verify()], callback: (router) {
  router.get('/users/:id', (ctx) async {
    final id = ctx.params['id'];
    return ctx.json({'id': id, 'name': 'John Doe'});
  }).setName('user.show');
});

app.listen(port: 8080);
```

### 2. **Dependency Injection (DI)**
Request-scoped container hierarchy. Services can be registered as singletons, factories, or unique to a single request lifecycle.
```dart
// Global registration
di.singleton<MailService>(MailService());
di.scoped<UserRepository>((c) => UserRepository(c.resolve<DatabaseExecutor>()));

// Usage in Handler
app.post('/profile', (ctx) async {
  final repo = ctx.resolve<UserRepository>();
  final user = await repo.find(ctx.body['id']);
  return ctx.json(user);
});
```

### 3. **The Queue System (v2)**
Enterprise-ready background job processing with distributed locking and dead letters.
```dart
class SendWelcomeEmail extends Job with SerializableJob {
  final String email;
  SendWelcomeEmail(this.email);

  @override
  Duration? get timeout => Duration(seconds: 30); // Timeout protection

  @override
  Future<void> handle() async {
    // Logic here...
  }
}

// Dispatching
await ctx.queue.dispatch(SendWelcomeEmail('[email protected]'));

// Starting Worker
await queue.work(concurrency: 4, maxJobsPerSecond: 10);
```

### 4. **Database: Query Builder & Migrations**
Fluent SQL construction with built-in migration batch tracking.
```dart
// Query Builder
final users = await db.table('users')
  .where('active', '=', true)
  .orderBy('created_at', 'DESC')
  .limit(10)
  .get();

// Transaction Middleware
app.post('/transfer', (ctx) async {
  // Whole request is automatically wrapped in a rollback-safe transaction
}, middleware: [transactionMiddleware()]);
```

### 5. **WebSocket Hub**
Real-time communication with built-in room support.
```dart
app.ws('/chat', (connection) async {
  connection.join('lobby');
  connection.listen((msg) {
    // Broadcast to everyone in the room
    connection.context.wsHub.toRoom('lobby', {'from': connection.id, 'msg': msg});
  });
});
```

### 6. **Validation**
Strongly typed `FormRequest` validation.
```dart
class RegisterRequest extends FormRequest {
  @override
  Map<String, String> rules() => {
    'email': 'required|email',
    'password': 'required|min:8',
    'age': 'numeric|min:18'
  };
}

app.post('/register', (ctx) async {
  final data = ctx.validate(RegisterRequest());
  // ... proceed with valid data
});
```

### 7. **Authentication (JWT)**
Seamless token generation and verification.
```dart
final auth = Auth(secret: 'super-secret');

app.get('/dashboard', (ctx) async {
  final user = ctx.request.attributes['auth'];
  return ctx.text('Welcome user ${user['id']}');
}, middleware: [auth.verify()]);
```

### 8. **Testing API**
Fluent, functional testing suite.
```dart
test('it updates user profile', () async {
  final client = app.test();
  await client.post('/profile', body: {'name': 'New Name'})
    .then((res) => res
      .assertStatus(200)
      .assertJsonPath('user.name', 'New Name'));
});
```

### 9. **Filesystem & Storage**
Abstracted storage facade for local or cloud file management.
```dart
// Saving an uploaded file
app.post('/upload', (ctx) async {
  final file = ctx.request.files['avatar'];
  if (file != null) {
    final path = await ctx.storage.put('avatars/${file.filename}', file.bytes);
    return ctx.json({'url': ctx.storage.url(path)});
  }
});
```

### 10. **Advanced Logging**
Context-aware, color-coded logging with request correlation IDs.
```dart
final logger = Logger.withContext(ctx);
logger.info('User accessed sensitive resource'); 
// Output: [2026-02-23] [abc12345] INFO: User accessed...
```

### 11. **Route Explorer**
Automatic documentation of your entire API.
```dart
final explorer = RouteExplorer(app);
app.get('/debug/routes', explorer.htmlHandler()); // Renders a beautiful UI
```

### 12. **Graceful Shutdown**
Automatically cleans up database pools, stops workers, and drains HTTP connections.
```dart
// App automatically listens for SIGINT/SIGTERM
// You can also trigger it manually
await app.stop(); 
```

---

## 🛑 What's Missing?

While Kronix is robust, the following areas are currently missing for a full "Enterprise Platinum" experience:

1.  **ORM Relationships**: The `Model` class is very basic. It lacks `belongsTo`, `hasMany`, and eager loading (`with('comments')`).
2.  **CLI Tool (Artisan Proxy)**: No command-line interface to run migrations (`dx migrate`) or scaffold controllers/models.
3.  **Caching Layer**: No unified `Cache` facade with Redis/Memcached drivers.
4.  **Scheduled Tasks**: No built-in Cron/Scheduler for periodic tasks.
5.  **Native Session Support**: Currently relies on JWT. No support for traditional server-side sessions/cookies out of the box.
6.  **Mail Facade**: No built-in SMTP/SES integration.
7.  **PubSub WebSocket Driver**: The WebSocket Hub is in-memory only. It won't work across multiple server instances without a Redis adapter.

---

## ⭐ Rating & Review

### **Rating: 8.5 / 10**

### **Review:**
Kronix is an exceptionally well-architected framework for Dart. It solves the "fragmentation" problem by providing a cohesive, battery-included experience. 

**Strengths:**
*   **The Queue system is world-class**: Distributed locking (SKIP LOCKED) and Dead Letter management are features usually reserved for mature frameworks.
*   **DI Integration**: The way the Container is passed through the Context and even into the Database Transaction is highly sophisticated.
*   **Performance**: Trie-based routing and the use of the Postgres Pool make it incredibly fast.
*   **Safety**: Automatic UTF-8 handling and structured Exception Transfomers make it hard to "break" the server with bad user input.

**Verdict:**
Excellent for high-performance microservices and real-time backends. It feels like "Laravel for Dart." Once it gets a CLI and ORM relationships, it will be a 10/10.

---
*Created on: 2026-02-23*
