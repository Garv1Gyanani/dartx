import 'dart:io';
import 'package:kronix/kronix.dart';

void main() async {
  print('========================================');
  print('   Kronix DX & EXTENSION VERIFICATION');
  print('========================================\n');

  testEnvAlias();
  testCastingHelpers();
  await testMiddlewareHelper();
  testFileServeArchitecture();

  print('\nVerification Complete.');
  exit(0);
}

void testEnvAlias() {
  print('--- Testing Env Alias ---');
  Config.set('VERIFY_ENV', 'true');
  if (Env.get('VERIFY_ENV') == 'true') {
    print('✅ Env alias for Config works.');
  } else {
    print('❌ BUG: Env.get() failed to retrieve Config value.');
  }
}

void testCastingHelpers() {
  print('\n--- Testing Casting Helpers ---');
  final rawReq = MockHttpRequest('GET', '/test?id=42&active=true&price=19.99');
  final req = Request(
    rawRequest: rawReq,
    params: {'userId': '101'},
    query: {'id': '42', 'active': 'true', 'price': '19.99'}
  );
  
  final ctx = Context(req, container: Container());

  if (ctx.paramInt('userId') == 101 && 
      ctx.queryInt('id') == 42 && 
      ctx.queryBool('active') == true &&
      ctx.queryDouble('price') == 19.99) {
    print('✅ All casting helpers (paramInt, queryInt, queryBool, queryDouble) verified.');
  } else {
    print('❌ BUG: Casting helpers failed. Params: ${ctx.params}, Query: ${ctx.queryParams}');
    print('Detailed failures:');
    print('userId: ${ctx.paramInt('userId')} (expected 101)');
    print('id: ${ctx.queryInt('id')} (expected 42)');
    print('active: ${ctx.queryBool('active')} (expected true)');
    print('price: ${ctx.queryDouble('price')} (expected 19.99)');
  }
}

Future<void> testMiddlewareHelper() async {
  print('\n--- Testing Middleware Helper (only/except) ---');
  
  final middleware = (Context ctx, Next next) async => Response.ok('intercepted');
  
  // Test only()
  final onlyAdmin = MiddlewareHelper.only('/admin', middleware);
  
  final matchCtx = Context(Request(rawRequest: MockHttpRequest('GET', '/admin')), container: Container());
  final missCtx = Context(Request(rawRequest: MockHttpRequest('GET', '/user')), container: Container());
  
  final res1 = await onlyAdmin(matchCtx, () async => Response.ok('ok'));
  final res2 = await onlyAdmin(missCtx, () async => Response.ok('ok'));

  if (res1.body == 'intercepted' && res2.body == 'ok') {
    print('✅ MiddlewareHelper.only() verified.');
  } else {
    print('❌ BUG: MiddlewareHelper.only() failed.');
  }

  // Test except()
  final exceptApi = MiddlewareHelper.except('/api/', middleware);
  final apiCtx = Context(Request(rawRequest: MockHttpRequest('GET', '/api/users')), container: Container());
  final webCtx = Context(Request(rawRequest: MockHttpRequest('GET', '/about')), container: Container());

  final res3 = await exceptApi(apiCtx, () async => Response.ok('ok'));
  final res4 = await exceptApi(webCtx, () async => Response.ok('ok'));

  if (res3.body == 'ok' && res4.body == 'intercepted') {
    print('✅ MiddlewareHelper.except() verified.');
  } else {
    print('❌ BUG: MiddlewareHelper.except() failed.');
  }
}

void testFileServeArchitecture() {
  print('\n--- Testing File Serving Architecture ---');
  final ctx = Context(Request(rawRequest: MockHttpRequest('GET', '/')), container: Container());
  
  // Create a dummy file for the test
  final dummyFile = File('dummy_test_file.txt');
  dummyFile.writeAsStringSync('hello world');
  
  try {
    final res = ctx.file('dummy_test_file.txt');
    if (res.statusCode == 200 && res.headers['content-type']!.startsWith('text/plain')) {
      print('✅ Context.file() generated correct response structure.');
    } else {
      print('❌ BUG: Context.file() failed. Status: ${res.statusCode}, CT: ${res.headers['content-type']}');
    }

    final downloadRes = ctx.download('dummy_test_file.txt', 'my_report.txt');
    if (downloadRes.headers['content-disposition'] == 'attachment; filename="my_report.txt"') {
      print('✅ Context.download() generated correct headers.');
    } else {
      print('❌ BUG: Context.download() failed headers check.');
    }
  } finally {
    if (dummyFile.existsSync()) dummyFile.deleteSync();
  }
}

// ─── MOCKS ───────────────────────────────────────────────────────

class MockHttpRequest implements HttpRequest {
  @override final String method;
  @override final Uri uri;
  @override final HttpHeaders headers = MockHttpHeaders();
  @override final HttpResponse response = MockHttpResponse();
  
  MockHttpRequest(this.method, String path) : uri = Uri.parse(path);

  @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockHttpHeaders implements HttpHeaders {
  final Map<String, List<String>> _data = {};
  @override void add(String name, Object value, {bool preserveHeaderCase = false}) => _data[name] = [value.toString()];
  @override String? value(String name) => _data[name]?.first;
  @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockHttpResponse implements HttpResponse {
  @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
