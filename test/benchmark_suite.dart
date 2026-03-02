import 'dart:io';
import 'package:kronix/kronix.dart';

void main() async {
  stdout.writeln('============================================');
  stdout.writeln('   KRONIX FRAMEWORK - BENCHMARK & VERIFY');
  stdout.writeln('============================================\n');

  // 1. Verify Fixes
  await verifyFixes();

  // 2. Performance Benchmarks
  await runRoutingBenchmark();
  await runValidationBenchmark();
  
  stdout.writeln('\nAll tests complete.');
  exit(0);
}

/// Verifies that known bugs have been fixed.
Future<void> verifyFixes() async {
  stdout.writeln('=== VERIFYING BUG FIXES ===');
  
  // Config Override Fix
  Config.set('TEST_KEY', 'override');
  if (Config.get('TEST_KEY') == 'override') {
    stdout.writeln('✅ [FIXED] Config overrides now work correctly.');
  } else {
    stdout.writeln('❌ [STILL BROKEN] Config overrides failed.');
  }

  // Response Headers Mutability
  final res = Response();
  try {
    res.headers['X-Verify'] = 'Internal';
    stdout.writeln('✅ [FIXED] Response headers are now mutable (not const).');
  } catch (e) {
    stdout.writeln('❌ [STILL BROKEN] Response headers are still immutable.');
  }

  // Auth response format
  final auth = Auth('secret');
  final rawReq = MockHttpRequest('GET', '/');
  final ctx = Context(Request(rawRequest: rawReq), container: Container());
  // We just want to see if verify() returns a Response.json or plain Response
  final verifyMiddleware = auth.verify();
  final response = await verifyMiddleware(ctx, () async => Response.ok('next'));
  if (response.headers['Content-Type'] == 'application/json; charset=utf-8') {
    stdout.writeln('✅ [FIXED] Auth middleware now returns JSON responses.');
  } else {
    stdout.writeln('❌ [STILL BROKEN] Auth middleware still returns plain text.');
  }
  
  stdout.writeln('');
}

/// Benchmarks the routing engine's performance.
Future<void> runRoutingBenchmark() async {
  stdout.writeln('=== ROUTING PERFORMANCE ===');
  final router = Router();
  
  // Register 1000 routes
  for (var i = 0; i < 1000; i++) {
    router.add('GET', '/route/$i/detail/:id', (ctx) async => Response.ok('ok'));
  }
  
  final sw = Stopwatch()..start();
  const iterations = 50000;
  for (var i = 0; i < iterations; i++) {
    router.match('GET', Uri.parse('/route/500/detail/42'));
  }
  sw.stop();
  
  final avg = sw.elapsedMicroseconds / iterations;
  stdout.writeln('Matched $iterations routes in ${sw.elapsedMilliseconds}ms');
  stdout.writeln('Average match time: ${avg.toStringAsFixed(2)}µs');
  
  if (avg < 5.0) {
    stdout.writeln('🚀 Performance: EXCELLENT (< 5µs)');
  } else if (avg < 20.0) {
    stdout.writeln('⚡ Performance: GOOD (< 20µs)');
  } else {
    stdout.writeln('🐢 Performance: NEEDS OPTIMIZATION (> 20µs)');
  }
  stdout.writeln('');
}

/// Benchmarks the validation engine's performance.
Future<void> runValidationBenchmark() async {
  stdout.writeln('=== VALIDATION PERFORMANCE ===');
  final rules = {
    'email': 'required|email',
    'password': 'required|min:8',
    'name': 'required|min:2|max:50',
    'age': 'numeric',
  };
  
  final data = <String, dynamic>{
    'email': 'test@example.com',
    'password': 'password123',
    'name': 'Kronix Tester',
    'age': '25',
  };
  
  final sw = Stopwatch()..start();
  const iterations = 10000;
  for (var i = 0; i < iterations; i++) {
    await Validator.validate(data, rules);
  }
  sw.stop();
  
  final avg = sw.elapsedMicroseconds / iterations;
  stdout.writeln('Validated $iterations objects in ${sw.elapsedMilliseconds}ms');
  stdout.writeln('Average validation time: ${avg.toStringAsFixed(2)}µs');
  stdout.writeln('');
}

// ─── MOCKS ───────────────────────────────────────────────────────

/// Mock [HttpRequest] for testing.
class MockHttpRequest implements HttpRequest {
  /// Creates a new [MockHttpRequest].
  MockHttpRequest(this.method, String path) : uri = Uri.parse(path);

  @override
  final String method;

  @override
  final Uri uri;

  @override
  final HttpHeaders headers = MockHttpHeaders();

  @override
  final HttpResponse response = MockHttpResponse();

  @override
  int get contentLength => 0;
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Mock [HttpResponse] for testing.
class MockHttpResponse implements HttpResponse {
  /// Creates a new [MockHttpResponse].
  MockHttpResponse();

  @override
  int statusCode = 200;

  @override
  final HttpHeaders headers = MockHttpHeaders();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Mock [HttpHeaders] for testing.
class MockHttpHeaders implements HttpHeaders {
  /// Creates a new [MockHttpHeaders].
  MockHttpHeaders();

  final Map<String, List<String>> _data = <String, List<String>>{};

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) =>
      _data[name] = <String>[value.toString()];

  @override
  String? value(String name) => _data[name]?.first;

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) =>
      _data[name] = <String>[value.toString()];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
