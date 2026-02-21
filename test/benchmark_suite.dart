import 'dart:io';
import 'dart:convert';
import 'package:kronix/kronix.dart';

void main() async {
  print('============================================');
  print('   kronix FRAMEWORK - BENCHMARK & VERIFY');
  print('============================================\n');

  // 1. Verify Fixes
  await verifyFixes();

  // 2. Performance Benchmarks
  await runRoutingBenchmark();
  await runValidationBenchmark();
  
  print('\nAll tests complete.');
  exit(0);
}

Future<void> verifyFixes() async {
  print('=== VERIFYING BUG FIXES ===');
  
  // Config Override Fix
  Config.set('TEST_KEY', 'override');
  if (Config.get('TEST_KEY') == 'override') {
    print('✅ [FIXED] Config overrides now work correctly.');
  } else {
    print('❌ [STILL BROKEN] Config overrides failed.');
  }

  // Response Headers Mutability
  final res = Response();
  try {
    res.headers['X-Verify'] = 'Internal';
    print('✅ [FIXED] Response headers are now mutable (not const).');
  } catch (e) {
    print('❌ [STILL BROKEN] Response headers are still immutable.');
  }

  // Auth response format
  final auth = Auth('secret');
  final rawReq = MockHttpRequest('GET', '/');
  final ctx = Context(Request(rawRequest: rawReq), container: Container());
  // We just want to see if verify() returns a Response.json or plain Response
  final verifyMiddleware = auth.verify();
  final response = await verifyMiddleware(ctx, () async => Response.ok('next'));
  if (response.headers['Content-Type'] == 'application/json') {
    print('✅ [FIXED] Auth middleware now returns JSON responses.');
  } else {
    print('❌ [STILL BROKEN] Auth middleware still returns plain text.');
  }
  
  print('');
}

Future<void> runRoutingBenchmark() async {
  print('=== ROUTING PERFORMANCE ===');
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
  print('Matched $iterations routes in ${sw.elapsedMilliseconds}ms');
  print('Average match time: ${avg.toStringAsFixed(2)}µs');
  
  if (avg < 5.0) {
    print('🚀 Performance: EXCELLENT (< 5µs)');
  } else if (avg < 20.0) {
    print('⚡ Performance: GOOD (< 20µs)');
  } else {
    print('🐢 Performance: NEEDS OPTIMIZATION (> 20µs)');
  }
  print('');
}

Future<void> runValidationBenchmark() async {
  print('=== VALIDATION PERFORMANCE ===');
  final rules = {
    'email': 'required|email',
    'password': 'required|min:8',
    'name': 'required|min:2|max:50',
    'age': 'numeric',
  };
  
  final data = {
    'email': 'test@example.com',
    'password': 'password123',
    'name': 'kronix Tester',
    'age': '25',
  };
  
  final sw = Stopwatch()..start();
  const iterations = 10000;
  for (var i = 0; i < iterations; i++) {
    Validator.validate(data, rules);
  }
  sw.stop();
  
  final avg = sw.elapsedMicroseconds / iterations;
  print('Validated $iterations objects in ${sw.elapsedMilliseconds}ms');
  print('Average validation time: ${avg.toStringAsFixed(2)}µs');
  print('');
}

// ─── MOCKS ───────────────────────────────────────────────────────

class MockHttpRequest implements HttpRequest {
  @override final String method;
  @override final Uri uri;
  @override final HttpHeaders headers = MockHttpHeaders();
  @override final HttpResponse response = MockHttpResponse();
  @override int get contentLength => 0;
  
  MockHttpRequest(this.method, String path) : uri = Uri.parse(path);
  @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockHttpResponse implements HttpResponse {
  @override int statusCode = 200;
  @override final HttpHeaders headers = MockHttpHeaders();
  @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockHttpHeaders implements HttpHeaders {
  final Map<String, List<String>> _data = {};
  @override void add(String name, Object value, {bool preserveHeaderCase = false}) => _data[name] = [value.toString()];
  @override String? value(String name) => _data[name]?.first;
  @override void set(String name, Object value, {bool preserveHeaderCase = false}) => _data[name] = [value.toString()];
  @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
