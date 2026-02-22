# File Storage & Uploads

Kronix provides a powerful storage abstraction and built-in support for multipart request parsing (file uploads).

## 📁 File Uploads

When a client sends a `multipart/form-data` request, Kronix automatically parses the files and makes them available via `ctx.request.files`.

### Basic Upload Example

```dart
app.post('/upload', (ctx) async {
  final file = ctx.request.files['avatar'];

  if (file != null) {
    // Save to a specific path
    await file.saveAs('uploads/${file.filename}');
    
    return ctx.json({
      'message': 'Uploaded!',
      'size': file.size,
      'type': file.contentType
    });
  }

  return ctx.json({'error': 'No file'}, status: 400);
});
```

The `UploadedFile` object contains:
- `filename`: The original name of the file.
- `contentType`: The MIME type (e.g., `image/png`).
- `bytes`: The raw file content.
- `size`: The size in bytes.

---

## ☁️ Storage Abstraction

The `Storage` module allows you to swap between different storage backends (Local, S3, etc.) without changing your application logic.

### Configuration

By default, Kronix uses the `LocalStorage` driver. You can configure the root directory and base URL in your `.env`:

```env
STORAGE_ROOT=storage
STORAGE_URL=/storage
```

### Common Operations

You can access the default storage disk via `ctx.storage` or the global `storage` helper.

#### Putting a file

```dart
await ctx.storage.put('documents/report.txt', 'Hello World'.codeUnits);
```

#### Checking for existence

```dart
if (await ctx.storage.exists('old_file.zip')) {
  // ...
}
```

#### Deleting a file

```dart
await ctx.storage.delete('temp/trash.tmp');
```

#### Getting a public URL

```dart
final url = ctx.storage.url('avatars/user_1.png');
// Returns "/storage/avatars/user_1.png"
```

---

## 🛠️ Advanced: Custom Storage Drivers

You can implement the `Storage` interface to support other providers like Amazon S3 or Google Cloud Storage.

```dart
class S3Storage implements Storage {
  @override
  Future<String> put(String path, List<int> bytes) async {
    // S3 implementation here...
    return path;
  }
  // ... implement other methods
}
```

Then, register it in your `App` startup (or via DI):

```dart
void main() {
  final app = App();
  
  // Override the default storage driver
  di.singleton<Storage>(S3Storage(...));
  
  app.listen();
}
```
