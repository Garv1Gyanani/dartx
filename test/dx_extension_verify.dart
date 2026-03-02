import 'dart:io';
import 'package:kronix/kronix.dart';

void main() async {
  stdout.writeln('========================================');
  stdout.writeln('   KRONIX DX & EXTENSION VERIFICATION');
  stdout.writeln('========================================\n');

  testEnvAlias();
  testCastingHelpers();
  await testMiddlewareHelper();
  testFileServeArchitecture();

  stdout.writeln('\nVerification Complete.');
  exit(0);
}

/// Tests that Env.get() is an alias for Config.get().
void testEnvAlias() {
  stdout.writeln('--- Testing Env Alias ---');
  Config.set('VERIFY_ENV', 'true');
  if (Env.get('VERIFY_ENV') == 'true') {
    stdout.writeln('✅ Env alias for Config works.');
  } else {
    stdout.writeln('❌ BUG: Env.get() failed to retrieve Config value.');
  }
}

/// Tests parameter casting helpers in Context.
void testCastingHelpers() {
  stdout.writeln('\n--- Testing Casting Helpers ---');
  final rawReq = MockHttpRequest('GET', '/test?id=42&active=true&price=19.99');
  final req = Request(
    rawRequest: rawReq,
    params: <String, String>{'userId': '101'},
    query: <String, String>{'id': '42', 'active': 'true', 'price': '19.99'},
  );
  
  final ctx = Context(req, container: Container());

  if (ctx.paramInt('userId') == 101 && 
      ctx.queryInt('id') == 42 && 
      ctx.queryBool('active') == true &&
      ctx.queryDouble('price') == 19.99) {
    stdout.writeln('✅ All casting helpers (paramInt, queryInt, queryBool, queryDouble) verified.');
  } else {
    stdout.writeln('❌ BUG: Casting helpers failed. Params: ${ctx.params}, Query: ${ctx.queryParams}');
    stdout.writeln('Detailed failures:');
    stdout.writeln('userId: ${ctx.paramInt('userId')} (expected 101)');
    stdout.writeln('id: ${ctx.queryInt('id')} (expected 42)');
    stdout.writeln('active: ${ctx.queryBool('active')} (expected true)');
    stdout.writeln('price: ${ctx.queryDouble('price')} (expected 19.99)');
  }
}

/// Tests MiddlewareHelper's only/except logic.
Future<void> testMiddlewareHelper() async {
  stdout.writeln('\n--- Testing Middleware Helper (only/except) ---');
  
  final middleware = (Context ctx, Next next) async => Response.ok('intercepted');
  
  // Test only()
  final onlyAdmin = MiddlewareHelper.only('/admin', middleware);
  
  final matchCtx = Context(Request(rawRequest: MockHttpRequest('GET', '/admin')), container: Container());
  final missCtx = Context(Request(rawRequest: MockHttpRequest('GET', '/user')), container: Container());
  
  final res1 = await onlyAdmin(matchCtx, () async => Response.ok('ok'));
  final res2 = await onlyAdmin(missCtx, () async => Response.ok('ok'));

  if (res1.body == 'intercepted' && res2.body == 'ok') {
    stdout.writeln('✅ MiddlewareHelper.only() verified.');
  } else {
    stdout.writeln('❌ BUG: MiddlewareHelper.only() failed.');
  }

  // Test except()
  final exceptApi = MiddlewareHelper.except('/api/', middleware);
  final apiCtx = Context(Request(rawRequest: MockHttpRequest('GET', '/api/users')), container: Container());
  final webCtx = Context(Request(rawRequest: MockHttpRequest('GET', '/about')), container: Container());

  final res3 = await exceptApi(apiCtx, () async => Response.ok('ok'));
  final res4 = await exceptApi(webCtx, () async => Response.ok('ok'));

  if (res3.body == 'ok' && res4.body == 'intercepted') {
    stdout.writeln('✅ MiddlewareHelper.except() verified.');
  } else {
    stdout.writeln('❌ BUG: MiddlewareHelper.except() failed.');
  }
}

/// Tests the file serving logic in Context.
void testFileServeArchitecture() {
  stdout.writeln('\n--- Testing File Serving Architecture ---');
  final ctx = Context(Request(rawRequest: MockHttpRequest('GET', '/')), container: Container());
  
  // Create a dummy file for the test
  final dummyFile = File('dummy_test_file.txt');
  dummyFile.writeAsStringSync('hello world');
  
  try {
    final res = ctx.file('dummy_test_file.txt');
    if (res.statusCode == 200 && res.headers['content-type']!.startsWith('text/plain')) {
      stdout.writeln('✅ Context.file() generated correct response structure.');
    } else {
      stdout.writeln('❌ BUG: Context.file() failed. Status: ${res.statusCode}, CT: ${res.headers['content-type']}');
    }

    final downloadRes = ctx.download('dummy_test_file.txt', 'my_report.txt');
    if (downloadRes.headers['content-disposition'] == 'attachment; filename="my_report.txt"') {
      stdout.writeln('✅ Context.download() generated correct headers.');
    } else {
      stdout.writeln('❌ BUG: Context.download() failed headers check.');
    }
  } finally {
    if (dummyFile.existsSync()) dummyFile.deleteSync();
  }
}

// ─── MOCKS ───────────────────────────────────────────────────────

/// Mock [HttpRequest] for extension verification.
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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Mock [HttpHeaders] for extension verification.
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

/// Mock [HttpResponse] for extension verification.
class MockHttpResponse implements HttpResponse {
  /// Creates a new [MockHttpResponse].
  MockHttpResponse();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
