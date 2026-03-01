export const docs = [
  {
    id: 'getting-started',
    title: 'Getting Started',
    sections: [
      {
        id: 'introduction',
        title: 'Introduction',
        content: `kronix is a high-performance, architecturally hardened web framework for the Dart ecosystem. It is designed for developers who require a structured, batteries-included environment for building scalable APIs.

### Core Philosophy
kronix draws inspiration from established patterns found in Laravel and NestJS, bringing type-safe dependency injection, fluent database interactions, and a declarative validation system to the Dart backend.

### Key Benefits
- **Deterministic Lifecycle**: Predictable resource cleanup and socket management.
* **Type-Safe DI**: Hierarchical containers prevent state leakage.
* **Production Ready**: Built-in micro-benchmarking and structured logging.
* **V0.2.0 "Venom"**: Now with Native ORM Relationships and Unified Caching.`
      },
      {
        id: 'installation',
        title: 'Installation',
        content: `To get started with kronix, you need to install the CLI tool globally or run it via the Dart SDK.

### Using the CLI
The fastest way to start is using the scaffold command:

\`\`\`bash
# Create a new project
dart run bin/kronix.dart create my_api

# Navigate into project
cd my_api

# Install dependencies
dart pub get
\`\`\`

### Requirements
- Dart SDK 3.0.0 or higher
- PostgreSQL (for the ORM features)
- Redis (Optional, for Redis Cache driver)`
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
        content: `kronix uses a high-performance Trie-based router. This ensures that route matching remains O(n) relative to path segments, not total route count.

### Basic Routing
\`\`\`dart
final app = App();

app.get('/welcome', (ctx) async {
  return ctx.text('Hello World');
});
\`\`\`

### Pre-compiled Pipelines
In v0.2.0, kronix automatically pre-compiles your middleware chains during server startup. This eliminates the overhead of building the execution stack for every request, resulting in extreme throughput.

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
\`\`\``
      },
      {
        id: 'dependency-injection',
        title: 'Dependency Injection',
        content: `The DI system in kronix is hierarchical. There is a global container for singletons and request-specific child containers for scoped services.

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
    title: 'Database & ORM',
    sections: [
      {
        id: 'query-builder',
        title: 'Query Builder',
        content: `kronix features a fluent Query Builder that makes working with PostgreSQL intuitive and type-safe.

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
\`\`\``
      },
      {
        id: 'orm-relationships',
        title: 'ORM Relationships',
        content: `Kronix ORM supports native relationships, allowing you to traverse your database naturally.

### Defining Relationships
\`\`\`dart
class User extends Model {
  @override String get tableName => 'users';

  // Has Many
  Future<List<Post>> posts() => hasMany<Post>(Post.fromRow);

  // Has One
  Future<Profile?> profile() => hasOne<Profile>(Profile.fromRow);
}

class Post extends Model {
  @override String get tableName => 'posts';

  // Belongs To
  Future<User?> author() => belongsTo<User>(User.fromRow);
}
\`\`\`

### Usage
\`\`\`dart
final user = await User.query().find(1);
final posts = await user.posts(); // Resolves relationships
\`\`\``
      }
    ]
  },
  {
    id: 'services',
    title: 'Services & Auth',
    sections: [
      {
        id: 'caching',
        title: 'Unified Caching',
        content: `The \`Cache\` facade provides a consistent API for temporary data storage across multiple drivers.

### Configuration
Set \`CACHE_DRIVER=redis\` or \`CACHE_DRIVER=memory\` in your \`.env\`.

### Fluent API
\`\`\`dart
// Basic get/set
await Cache.put('key', 'value', Duration(minutes: 10));
final val = await Cache.get('key');

// The "Remember" Pattern
final userCount = await Cache.remember('users.count', Duration(hour: 1), () async {
    return await User.query().count();
});
\`\`\``
      },
      {
        id: 'sessions',
        title: 'Native Sessions',
        content: `Kronix provides server-side sessions managed via cookies.

### Setup
Add the \`SessionMiddleware\` to your app globally or to specific groups.

\`\`\`dart
app.use(SessionMiddleware());

app.get('/dashboard', (ctx) async {
  final session = ctx.session;
  session.set('last_visit', DateTime.now().toString());
  
  return ctx.text('Welcome back!');
});
\`\`\`

By default, sessions are stored in memory but can be persisted to Redis for distributed environments.`
      },
      {
        id: 'validation',
        title: 'Validation Engine',
        content: `Validation in kronix is declarative and extremely fast (~3.6µs per object).

### Inline Validation
\`\`\`dart
app.post('/register', (ctx) async {
  final data = await ctx.validate({
    'email': 'required|email',
    'password': 'required|min:8',
    'age': 'numeric|min:18',
  });
});
\`\`\`

### Complex Data
Supports nested arrays and wildcard validation:
\`\`\`dart
'items.*.id': 'required|numeric',
'items.*.qty': 'required|min:1',
\`\`\``
      }
    ]
  },
  {
    id: 'advanced',
    title: 'Advanced & CLI',
    sections: [
      {
        id: 'cli-tool',
        title: 'CLI Scaffolding 2.0',
        content: `The \`kronix\` CLI is your primary tool for rapid development.

### Automated Migrations
When creating a model, you can automatically generate a migration file:

\`\`\`bash
kronix make:model Product -m
\`\`\`

This creates:
1. \`lib/models/product.dart\`
2. \`lib/database/migrations/[timestamp]_create_products_table.dart\`

### Watch Mode
Rebuild and restart your server automatically on file changes:
\`\`\`bash
kronix watch
\`\`\`

### Production Build
\`\`\`bash
kronix build
\`\`\``
      },
      {
        id: 'security-harden',
        title: 'Security Hardening',
        content: `Kronix includes built-in protections against common web vulnerabilities.

### Payload Size Limits
Global enforcement of \`MAX_BODY_SIZE\` prevents OOM attacks from massive request bodies.

### Backpressure Control
Configure \`MAX_CONCURRENT_REQUESTS\` to gracefully reject traffic with a 503 response when the server is under extreme load.

### Case-Insensitive Headers
Seamless header handling ensures your middleware works regardless of client implementation (e.g., \`Authorization\` vs \`authorization\`).`
      }
    ]
  }
];

