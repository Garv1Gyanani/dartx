# 0.2.0

- Added support for ORM relationships (`belongsTo`, `hasMany`, `hasOne`).
- Added a unified caching layer with Memory and Redis drivers.
- Added session support via `SessionMiddleware`.
- Improved CLI scaffolding for models and migrations.
- Optimized middleware execution chains.
- Performance and security improvements (body limits, headers).
- Fixed port exhaustion in concurrency tests.

# 0.1.5

- Improved database flow with typed model instances.
- Added a fluent schema builder for migrations.
- Added wildcard validation support.
- Added request backpressure control.
- Improved dependency injection isolation.
- Fixed model export conflicts.
- Renamed `ctx.query` to `ctx.queryParams`.

# 0.1.4

- Added functional testing utilities.
- Added a route explorer to view registered routes.
- Added metadata support for routes.
- Added `App.stop()` for clean shutdowns.
- Fixed UTF-8 encoding issues in responses.

# 0.1.3

- Added file upload support.
- Added storage abstraction (local storage).
- Added `UploadedFile` class.

# 0.1.2

- Improved examples and documentation.
- Better pub.dev compatibility.

# 0.1.1

- Improved WebSocket support with rooms.
- API documentation updates.
- Dependency updates.

# 0.1.0

- Initial release.
- Radix-Trie router.
- Dependency Injection with scoping.
- Form validation.
- Query Builder.
- Database migrations.
- Logging and config management.

