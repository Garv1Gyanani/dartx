# 🧠 Kronix: Technical Insights & Best Practices

This guide documents technical nuances, common challenges, and recommended patterns discovered during real-world implementations of the Kronix framework.

---

## 🛑 1. Dependency Management (Crypto & JWT)

**The Challenge:**
When using security-heavy packages like `encrypt` alongside `kronix` (which uses `dart_jsonwebtoken`), you may encounter version conflicts with the `pointycastle` package.

**The Solution:**
Implement a `dependency_override` in your `pubspec.yaml` to unify the versions. Kronix requires `^4.0.0` for maximum security and performance.

```yaml
dependency_overrides:
  pointycastle: ^4.0.0
```

---

## ⛑ 2. Port Management & Server Lifecycle

**The Challenge:**
On some operating systems (notably Windows), restarting the server rapidly can lead to a `SocketException (errno = 10048)` because the OS holds the port in a `TIME_WAIT` state.

**Our Approach:**
Kronix now uses `shared: true` by default in `app.listen()` to allow for smoother socket handovers. However, if you still encounter busy ports, we recommend:
1.  Using a process manager like PM2.
2.  Ensuring a clean shutdown by listening for `SIGINT` (handled automatically by the framework).
3.  In development, you can use the following command to force-clear Dart processes:
    `taskkill /F /IM dart.exe /T`

---

## 🛡 3. Middleware Gating (Public vs Private)

**The Challenge:**
Global middleware can sometimes accidentally shield public routes (like `/` or `/login`) if not carefully configured.

**The Solution:**
Use the `MiddlewareHelper` utility to wrap your middleware with path-based exclusions.

```dart
// Shield all of /api/ but allow public access elsewhere
app.use(MiddlewareHelper.except('/api/', auth.verify()));

// Or explicitly allow certain paths
app.use(MiddlewareHelper.exceptMany(['/', '/login'], auth.verify()));
```

---

## ⚡ 4. Parameter Casting & Validation

**The Challenge:**
Route parameters and query strings are strings by default. Manually parsing them in every controller leads to boilerplate.

**The Solution:**
Use the built-in casting helpers on the `Context` object.

```dart
app.get('/accounts/:id', (ctx) async {
  // Automatically parsed or returns null/default
  final id = ctx.paramInt('id'); 
  final page = ctx.queryInt('page', 1);
  final activeOnly = ctx.queryBool('active');
  
  return ctx.json({'id': id, 'page': page});
});
```

---

## 📝 5. Configuration Precedence

**The Challenge:**
Confusion between `Env` and `Config`.

**The Solution:**
Always use `Config.get()` for retrieving variables. `Env` is provided as a semantic alias for developers coming from other ecosystems, but they both point to the same global configuration manager.

Precedence:
1.  **Runtime Overrides**: `Config.set('KEY', 'VALUE')` (highest)
2.  **Environment Variables**: OS-level env vars.
3.  **.env File**: Local file values (lowest).

---

## 📊 6. Handling JSON Body

**The Challenge:**
Clients forgetting to set `Content-Type: application/json` can lead to unparsed body maps.

**Best Practice:**
1.  Always ensure your client sends the correct header.
2.  In Kronix, if the header is missing, the raw body is available via `ctx.body['_raw']`.
3.  You can also enforce the header using a global middleware:
```dart
app.use((ctx, next) async {
  if (ctx.request.method != 'GET' && ctx.request.headers.contentType?.mimeType != 'application/json') {
    return ctx.json({'error': 'Content-Type must be application/json'}, status: 415);
  }
  return await next();
});
```

---

## 📂 7. Efficient Static File Serving

**The Challenge:**
Manual file reading (e.g., `File().readAsString()`) is memory-intensive for large files and requires manual MIME type detection.

**The Solution:**
Kronix now supports efficient streaming via `ctx.file()`. It automatically handles MIME types and streams the file directly to the response socket.

```dart
// Serve an index file
app.get('/', (ctx) async => ctx.file('public/index.html'));

// Force a download
app.get('/report', (ctx) async => ctx.download('storage/report.pdf', 'Monthly_Report.pdf'));
```

