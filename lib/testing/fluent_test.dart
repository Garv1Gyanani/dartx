import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import '../core/config.dart';
import '../core/server.dart';

/// A fluent wrapper around HTTP responses for easier assertions in tests.
class TestResponse {
  /// Creates a new [TestResponse] from an underlying [http.Response].
  TestResponse(this.raw);

  /// The raw HTTP response from the test client.
  final http.Response raw;

  /// Returns the status code of the response.
  int get statusCode => raw.statusCode;

  /// Returns the body content of the response.
  String get body => raw.body;

  /// Returns the headers of the response.
  Map<String, String> get headers => raw.headers;

  /// Asserts that the response status code matches [expected].
  TestResponse assertStatus(int expected) {
    expect(
      raw.statusCode,
      expected,
      reason: 'Expected status $expected but got ${raw.statusCode}.\nBody: ${raw.body}',
    );
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
    var current = decoded;
    
    for (final segment in segments) {
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
}

/// A client for making fluent, functional requests to a Kronix [App].
class TestClient {
  /// Creates a [TestClient] for the given [app].
  TestClient(this.app);

  /// The application instance being tested.
  final App app;
  late int _port;
  bool _isRunning = false;

  /// Starts the app on a random port for testing.
  Future<void> _ensureStarted() async {
    if (_isRunning) return;
    
    // Find a random available port
    final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    _port = socket.port;
    await socket.close();

    Config.set('APP_ENV', 'test');
    // The listen call starts the server in an infinite loop.
    // We add a small delay to ensure it's ready.
    // ignore: unawaited_future
    app.listen(port: _port, host: 'localhost');
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _isRunning = true;
  }

  /// Stops the app.
  Future<void> stop() async {
    if (!_isRunning) return;
    await app.stop();
    _isRunning = false;
  }

  /// Makes a `GET` request to the given [path].
  Future<TestResponse> get(String path, {Map<String, String>? headers}) async {
    await _ensureStarted();
    final res = await http.get(Uri.parse('http://localhost:$_port$path'), headers: headers);
    return TestResponse(res);
  }

  /// Makes a `POST` request with an optional [body].
  Future<TestResponse> post(String path, {Map<String, String>? headers, dynamic body}) async {
    await _ensureStarted();
    final res = await http.post(
      Uri.parse('http://localhost:$_port$path'), 
      headers: headers, 
      body: body is Map ? jsonEncode(body) : body,
    );
    return TestResponse(res);
  }

  /// Makes a `PUT` request with an optional [body].
  Future<TestResponse> put(String path, {Map<String, String>? headers, dynamic body}) async {
    await _ensureStarted();
    final res = await http.put(
      Uri.parse('http://localhost:$_port$path'), 
      headers: headers, 
      body: body is Map ? jsonEncode(body) : body,
    );
    return TestResponse(res);
  }

  /// Makes a `DELETE` request to the given [path].
  Future<TestResponse> delete(String path, {Map<String, String>? headers}) async {
    await _ensureStarted();
    final res = await http.delete(Uri.parse('http://localhost:$_port$path'), headers: headers);
    return TestResponse(res);
  }
}

/// Extension to easily create a [TestClient] from an [App].
extension AppTestExtension on App {
  /// Returns a [TestClient] instance for the current [App].
  TestClient test() => TestClient(this);
}
