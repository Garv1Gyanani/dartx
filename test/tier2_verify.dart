import 'dart:io';
import 'package:kronix/kronix.dart';

void main() async {
  print('========================================');
  print('   Kronix TIER 2 VERIFICATION (Cache & Session)');
  print('========================================\n');

  await testCache();
  await testSessions();

  print('\nTier 2 Verification Complete.');
  exit(0);
}

Future<void> testCache() async {
  print('--- Testing Cache (InMemory) ---');
  
  await Cache.put('name', 'Kronix');
  final name = await Cache.get<String>('name');
  
  if (name == 'Kronix') {
    print('✅ Cache put/get works.');
  } else {
    print('❌ Cache failed. Got: $name');
  }

  print('Testing Cache.remember...');
  final remembered = await Cache.remember('count', Duration(seconds: 1), () => 42);
  final retrieved = await Cache.get<int>('count');
  
  if (remembered == 42 && retrieved == 42) {
    print('✅ Cache.remember works.');
  } else {
    print('❌ Cache.remember failed.');
  }

  await Cache.increment('visits');
  await Cache.increment('visits');
  final visits = await Cache.get<int>('visits');
  if (visits == 2) {
    print('✅ Cache increment works.');
  } else {
    print('❌ Cache increment failed: $visits');
  }
}

Future<void> testSessions() async {
  print('\n--- Testing Sessions ---');
  
  final store = MemorySessionStore();
  final middleware = SessionMiddleware(store: store);
  
  // 1. Initial Request (No cookie)
  print('Testing session initialization...');
  final rawReq1 = MockHttpRequest('GET', '/');
  final ctx1 = Context(Request(rawRequest: rawReq1), container: Container());
  
  final res1 = await middleware.handle()(ctx1, () async {
    ctx1.session.put('user_id', 123);
    return Response.ok('ok');
  });

  final setCookie = res1.headers['set-cookie'] ?? '';
  if (setCookie.contains('kronix_session=')) {
    print('✅ Session cookie set in response.');
  } else {
    print('❌ Set-Cookie missing.');
  }

  // 2. Subsequent Request (With cookie)
  print('Testing session persistence...');
  final parts = setCookie.split('kronix_session=');
  final sessionId = parts[1].split(';')[0];
  
  final rawReq2 = MockHttpRequest('GET', '/');
  rawReq2.headers.add('Cookie', 'kronix_session=$sessionId');
  
  final ctx2 = Context(Request(rawRequest: rawReq2), container: Container());
  
  await middleware.handle()(ctx2, () async {
    final uid = ctx2.session.get<int>('user_id');
    if (uid == 123) {
      print('✅ Session data persisted correctly.');
    } else {
      print('❌ Session data lost. Got: $uid');
    }
    return Response.ok('ok');
  });
}

// ─── MOCKS ───────────────────────────────────────────────────────

class MockHttpRequest implements HttpRequest {
  @override final String method;
  @override final Uri uri;
  @override final HttpHeaders headers = MockHttpHeaders();
  
  MockHttpRequest(this.method, String path) : uri = Uri.parse(path);

  @override final HttpResponse response = MockHttpResponse();
  @override
  List<Cookie> get cookies {
    final cookieHeader = headers.value('Cookie') ?? '';
    if (cookieHeader.isEmpty) return <Cookie>[];
    final parts = cookieHeader.split('; ');
    return parts.map((p) {
      final pair = p.split('=');
      if (pair.length < 2) return Cookie(p, '');
      return Cookie(pair[0], pair[1]);
    }).toList();
  }

  @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockHttpHeaders implements HttpHeaders {
  final Map<String, List<String>> _data = {};
  @override void add(String name, Object value, {bool preserveHeaderCase = false}) {
    _data[name] ??= [];
    _data[name]!.add(value.toString());
  }
  @override String? value(String name) => _data[name]?.first;
  @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockHttpResponse implements HttpResponse {
  @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
