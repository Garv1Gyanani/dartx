# Routing in Kronix

Kronix features a high-performance Radix-Trie based router that supports static routes, dynamic parameters, and wildcards.

## Basic Routing

You can define routes directly on the `App` instance:

```dart
app.get('/hello', (ctx) async {
  return ctx.text('Hello World');
});

app.post('/users', (ctx) async {
  final data = ctx.body;
  // ... create user
  return ctx.json({'status': 'created'}, status: 201);
});
```

## Dynamic Parameters

Parameters are defined with a colon `:` prefix and are available in `ctx.params`.

```dart
app.get('/users/:id', (ctx) async {
  final id = ctx.params['id'];
  return ctx.json({'user_id': id});
});
```

## Route Groups

Groups allow you to apply common prefixes and middleware to a set of routes.

```dart
app.group('/api/v1', callback: (router) {
  router.get('/users', (ctx) async {
    return ctx.json([]);
  });
  
  router.get('/posts', (ctx) async {
    return ctx.json([]);
  });
});
```

## Wildcards

Use `*` to capture everything after a certain segment.

```dart
app.get('/files/*', (ctx) async {
  final p = ctx.params['*'];
  return ctx.text('Fetching file at path: $p');
});
```

## HTTP Methods

Supported methods: `GET`, `POST`, `PUT`, `PATCH`, `DELETE`, `HEAD`, `OPTIONS`.

```dart
app.patch('/users/:id', (ctx) async => ...);
app.delete('/users/:id', (ctx) async => ...);
```
