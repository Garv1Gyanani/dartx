export const docs = [
    {
        id: 'getting-started',
        title: 'Getting Started',
        sections: [
            {
                id: 'introduction',
                title: 'Introduction',
                content: `DartX is a high-performance, architecturally hardened web framework for the Dart ecosystem. It is designed for developers who require a structured, batteries-included environment for building scalable APIs.

### Core Philosophy
DartX draws inspiration from established patterns found in Laravel and NestJS, bringing type-safe dependency injection, fluent database interactions, and a declarative validation system to the Dart backend.

### Key Benefits
- **Deterministic Lifecycle**: Predictable resource cleanup and socket management.
* **Type-Safe DI**: Hierarchical containers prevent state leakage.
* **Production Ready**: Built-in micro-benchmarking and structured logging.
* **CLI Driven**: Rapid scaffolding for high productivity.`
            },
            {
                id: 'installation',
                title: 'Installation',
                content: `To get started with DartX, you need to install the CLI tool globally or run it via the Dart SDK.

### Using the CLI
The fastest way to start is using the scaffold command:

\`\`\`bash
# Create a new project
dart run bin/dartx.dart create my_api

# Navigate into project
cd my_api

# Install dependencies
dart pub get
\`\`\`

### Requirements
- Dart SDK 3.0.0 or higher
- PostgreSQL (for the ORM features)`
            }
        ]
    },
    {
        id: 'core-concepts',
        title: 'Core Concepts',
        sections: [
            {
                id: 'routing',
                title: 'Routing & Groups',
                content: `DartX uses a high-performance Trie-based router. This ensures that route matching remains O(n) relative to path segments, not total route count.

### Basic Routing
\`\`\`dart
final app = App();

app.get('/welcome', (ctx) async {
  return ctx.text('Hello World');
});
\`\`\`

### Route Groups
Groups allow you to apply middleware and path prefixes to multiple routes at once.

\`\`\`dart
app.group('/api/v1', middleware: [AuthMiddleware()], callback: (router) {
  router.get('/profile', (ctx) async {
    return ctx.json(ctx.user);
  });
});
\`\`\`

### Named Parameters
Extract values directly from the URL.

\`\`\`dart
app.get('/users/:id', (ctx) async {
  final userId = ctx.params['id'];
  return ctx.json({'userId': userId});
});
\`\`\`

### Performance
The router is optimized for low latency, with an average match time of **~1.3µs** for a 1,000 route table.`
            },
            {
                id: 'dependency-injection',
                title: 'Dependency Injection',
                content: `The DI system in DartX is hierarchical. There is a global container for singletons and request-specific child containers for scoped services.

### Registration
\`\`\`dart
// Global singleton
di.singleton(PaymentService());

// Request-scoped factory
di.scoped((container) => UserSession());
\`\`\`

### Resolution
Services can be resolved from the global \`di\` or the request \`ctx\`.

\`\`\`dart
app.get('/pay', (ctx) async {
  final session = ctx.resolve<UserSession>();
  final billing = ctx.resolve<PaymentService>();
});
\`\`\`

### Resource Disposal
Any service implementing the \`Disposable\` interface will be automatically cleaned up when the request lifecycle ends.`
            }
        ]
    },
    {
        id: 'data-layer',
        title: 'Data & Validation',
        sections: [
            {
                id: 'database-orm',
                title: 'Query Builder & ORM',
                content: `DartX features a fluent Query Builder that makes working with PostgreSQL intuitive and type-safe.

### Basic Queries
\`\`\`dart
final users = await db.table('users')
    .where('active', '=', true)
    .orderBy('created_at', 'DESC')
    .get();
\`\`\`

### Automatic Transactions
Atomicity is built-in. Use the \`transaction\` wrapper to ensure your database operations either all succeed or all fail.

\`\`\`dart
await db.transaction((tx) async {
  await tx.table('orders').insert(data);
  await tx.table('inventory').decrement('stock');
});
\`\`\`

### Migrations
The migration system uses a batch-based execution model. Run \`dartx migrate\` to update your schema.`
            },
            {
                id: 'validation',
                title: 'Form Request Validation',
                content: `Validation in DartX is declarative. Instead of manual checks in your controllers, you define \`FormRequest\` classes.

### Defining Rules
\`\`\`dart
class CreateUserRequest extends FormRequest {
  @override
  Map<String, String> rules() => {
    'email': 'required|email',
    'password': 'required|min:8',
  };
}
\`\`\`

### Usage
\`\`\`dart
app.post('/register', (ctx) async {
  final data = await ctx.validate(CreateUserRequest());
  // If validation fails, a 422 JSON response is sent automatically.
});
\`\`\`

### Latency
Validation is extremely lightweight, with an overhead of only **~2.7µs** per object validation.`
            }
        ]
    },
    {
        id: 'advanced',
        title: 'Advanced Features',
        sections: [
            {
                id: 'exception-handling',
                title: 'Exception Handling',
                content: `DartX handles errors deterministically through an Exception Transformer.

### Typed Exceptions
Throwing a \`NotFoundException\` or \`UnauthorizedException\` will automatically result in the correct HTTP status code and a standardized JSON body.

### Environment Awareness
In development (\`APP_ENV=local\`), exceptions include full stack traces and debug info. In production, these are silenced to avoid information leakage.`
            },
            {
                id: 'middleware-pipelines',
                title: 'Middleware Pipelines',
                content: `Middleware in DartX follows the Onion Pattern. Each layer can execute logic before and after the next handler in the stack.

\`\`\`dart
class LoggerMiddleware extends Middleware {
  @override
  Future<Response> handle(Context ctx, Next next) async {
    print('Start');
    final res = await next();
    print('End');
    return res;
  }
}
\`\`\``
            }
        ]
    }
];
