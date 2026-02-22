import 'dart:io';
import 'dart:async';
import 'package:test/test.dart';
import 'package:kronix/kronix.dart';
import 'package:http/http.dart' as http;

void main() {
  group('File Upload & Storage', () {
    late App app;
    final port = 3005;

    setUp(() async {
      app = App();
      Config.set('STORAGE_ROOT', 'test_storage');
      
      app.post('/upload', (ctx) async {
        final file = ctx.request.files['image'];
        if (file == null) return ctx.json({'error': 'No file'}, status: 400);

        // Test saveAs
        final savedPath = 'uploads/${file.filename}';
        await file.saveAs(savedPath);

        // Test Storage abstraction
        await ctx.storage.put('storage_test.txt', 'Hello Storage'.codeUnits);

        return ctx.json({
          'filename': file.filename,
          'size': file.size,
          'type': file.contentType,
          'saved': await File(savedPath).exists(),
          'storage_exists': await ctx.storage.exists('storage_test.txt'),
        });
      });

      // Simple form data test
      app.post('/form', (ctx) async {
        return ctx.json({
          'name': ctx.body['name'],
          'email': ctx.body['email'],
        });
      });

      unawaited(app.listen(port: port, host: 'localhost'));
      await Future.delayed(Duration(milliseconds: 200));
    });

    tearDown(() async {
      await app.stop();
      // Cleanup
      if (Directory('uploads').existsSync()) {
        Directory('uploads').deleteSync(recursive: true);
      }
      if (Directory('test_storage').existsSync()) {
        Directory('test_storage').deleteSync(recursive: true);
      }
    });

    test('should parse multipart form data and files', () async {
      final request = http.MultipartRequest('POST', Uri.parse('http://localhost:$port/upload'));
      request.fields['title'] = 'My Image';
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        [1, 2, 3, 4],
        filename: 'test.png',
      ));

      final response = await request.send();
      final body = await response.stream.bytesToString();
      
      expect(response.statusCode, 200);
      expect(body, contains('"filename":"test.png"'));
      expect(body, contains('"size":4'));
      expect(body, contains('"saved":true'));
      expect(body, contains('"storage_exists":true'));
    });

    test('should parse multipart text fields', () async {
      final request = http.MultipartRequest('POST', Uri.parse('http://localhost:$port/form'));
      request.fields['name'] = 'John Doe';
      request.fields['email'] = 'john@example.com';

      final response = await request.send();
      final body = await response.stream.bytesToString();

      expect(response.statusCode, 200);
      expect(body, contains('"name":"John Doe"'));
      expect(body, contains('"email":"john@example.com"'));
    });
  });
}
