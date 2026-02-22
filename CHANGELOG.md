# 0.1.4

- **Fluent Functional Testing** — `app.test().get('/api').assertStatus(200).assertJsonPath('data.id', 1)`.
- **Route Explorer** — Auto-generated API docs at `/docs` (HTML) and `/docs/json` (JSON).
- **Route metadata** — Fluent `.setSummary()`, `.setDescription()`, `.setMeta()` on route registrations.
- **`App.stop()`** for clean test teardown without `exit(0)`.
- **Fixed** UTF-8 response encoding crash on multi-byte characters (emojis in HTML).
- All route registration methods now return `RouteData` for chaining.

# 0.1.3

- Added `multipart/form-data` request parsing for file uploads.
- Introduced `Storage` abstraction with `LocalStorage` support.
- Added `UploadedFile` class for easy file manipulation.
- Integrated `ctx.storage` for disk operations in handlers.
- Added `App.stop()` for graceful testing and shutdown.

# 0.1.2

- Refactored and improved the primary example to showcase WebSockets and Validation better.
- Added `example/example.dart` for better pub.dev compatibility.

# 0.1.1

- Added matured WebSocket support with `WebSocketHub` and Rooms.
- Enhanced API documentation for all public members.
- Updated dependencies for improved pub score.
- Integrated WebSocket middleware protection.

# 0.1.0

- Initial release of the Kronix framework.
- High-performance Radix-Trie router with middleware support.
- Hierarchical Dependency Injection with request scoping.
- Declarative FormRequest validation system.
- Fluent SQL Query Builder for PostgreSQL.
- Atomic Database Migrations with batching.
- Typed Configuration and Environment management.
- Structured Logging with Request-ID correlation.
- Deterministic Exception Transformation.
- Built-in CLI for project scaffolding and watching.
