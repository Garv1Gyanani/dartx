import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import '../core/server.dart';
import '../core/config.dart';

/// A fluent wrapper around HTTP responses for easier assertions in tests.
class TestResponse {
  final http.Response raw;

  TestResponse(this.raw);

  /// Asserts that the response status code matches [expected].
  TestResponse assertStatus(int expected) {
    expect(raw.statusCode, expected, reason: 'Expected status $expected but got ${raw.statusCode}.\nBody: ${raw.body}');
    return this;
  }

  /// Asserts that the response body contains [nest].
  TestResponse assertBodyContains(String nest) {
    expect(raw.body, contains(nest));
    return this;
  }

  /// Asserts that the response JSON contains the exact [data].
  TestResponse assertJson(Map<String, dynamic> data) {
    final decoded = jsonDecode(raw.body);
    expect(decoded, data);
    return this;
  }

  /// Asserts that a specific JSON path matches [expected].
  /// Supports simple dot notation (e.g., 'user.id').
  TestResponse assertJsonPath(String path, dynamic expected) {
    final decoded = jsonDecode(raw.body);
    final segments = path.split('.');
    dynamic current = decoded;
    
    for (var segment in segments) {
      if (current is Map && current.containsKey(segment)) {
        current = current[segment];
      } else if (current is List) {
        final index = int.tryParse(segment);
        if (index != null && index >= 0 && index < current.length) {
          current = current[index];
        } else {
          fail('Index "$segment" invalid for List at path "$path"');
        }
      } else {
        fail('Path "$path" not found in JSON response: ${raw.body}');
      }
    }
    
    expect(current, expected);
    return this;
  }

  /// Asserts that a header [key] matches [value].
  TestResponse assertHeader(String key, String value) {
    expect(raw.headers[key.toLowerCase()], value);
    return this;
  }

  int get statusCode => raw.statusCode;
  String get body => raw.body;
  Map<String, String> get headers => raw.headers;
}

/// A client for making fluent, functional requests to a Kronix [App].
class TestClient {
  final App app;
  late int _port;
  bool _isRunning = false;

  TestClient(this.app);

  /// Starts the app on a random port for testing.
  Future<void> _ensureStarted() async {
    if (_isRunning) return;
    
    // Find a random available port
    final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    _port = socket.port;
    await socket.close();

    Config.set('APP_ENV', 'test');
    // We don't use unawaited here to avoid lint issues, 
    // but the listen loop is infinite so we use a small delay.
    final future = app.listen(port: _port, host: 'localhost');
    await Future.delayed(Duration(milliseconds: 200));
    _isRunning = true;
  }

  /// Stops the app.
  Future<void> stop() async {
    if (!_isRunning) return;
    await app.stop();
    _isRunning = false;
  }

  Future<TestResponse> get(String path, {Map<String, String>? headers}) async {
    await _ensureStarted();
    final res = await http.get(Uri.parse('http://localhost:$_port$path'), headers: headers);
    return TestResponse(res);
  }

  Future<TestResponse> post(String path, {Map<String, String>? headers, dynamic body}) async {
    await _ensureStarted();
    final res = await http.post(
      Uri.parse('http://localhost:$_port$path'), 
      headers: headers, 
      body: body is Map ? jsonEncode(body) : body
    );
    return TestResponse(res);
  }

  Future<TestResponse> put(String path, {Map<String, String>? headers, dynamic body}) async {
    await _ensureStarted();
    final res = await http.put(
      Uri.parse('http://localhost:$_port$path'), 
      headers: headers, 
      body: body is Map ? jsonEncode(body) : body
    );
    return TestResponse(res);
  }

  Future<TestResponse> delete(String path, {Map<String, String>? headers}) async {
    await _ensureStarted();
    final res = await http.delete(Uri.parse('http://localhost:$_port$path'), headers: headers);
    return TestResponse(res);
  }
}

/// Extension to easily create a [TestClient] from an [App].
extension AppTestExtension on App {
  TestClient test() => TestClient(this);
}
