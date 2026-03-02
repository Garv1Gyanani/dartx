import 'dart:io';
import 'package:kronix/kronix.dart';

void main() async {
  stdout.writeln('========================================');
  stdout.writeln('   KRONIX TIER 2 VERIFICATION (Cache & Session)');
  stdout.writeln('========================================\n');

  await testCache();
  await testSessions();

  stdout.writeln('\nTier 2 Verification Complete.');
  exit(0);
}

/// Tests basic Cache operations.
Future<void> testCache() async {
  stdout.writeln('--- Testing Cache (InMemory) ---');
  
  await Cache.put('name', 'Kronix');
  final name = await Cache.get<String>('name');
  
  if (name == 'Kronix') {
    stdout.writeln('✅ Cache put/get works.');
  } else {
    stdout.writeln('❌ Cache failed. Got: $name');
  }

  stdout.writeln('Testing Cache.remember...');
  final remembered = await Cache.remember('count', const Duration(seconds: 1), () => 42);
  final retrieved = await Cache.get<int>('count');
  
  if (remembered == 42 && retrieved == 42) {
    stdout.writeln('✅ Cache.remember works.');
  } else {
    stdout.writeln('❌ Cache.remember failed.');
  }

  await Cache.increment('visits');
  await Cache.increment('visits');
  final visits = await Cache.get<int>('visits');
  if (visits == 2) {
    stdout.writeln('✅ Cache increment works.');
  } else {
    stdout.writeln('❌ Cache increment failed: $visits');
  }
}

/// Tests Session management and persistence.
Future<void> testSessions() async {
  stdout.writeln('\n--- Testing Sessions ---');
  
  final store = MemorySessionStore();
  final middleware = SessionMiddleware(store: store);
  
  // 1. Initial Request (No cookie)
  stdout.writeln('Testing session initialization...');
  final rawReq1 = MockHttpRequest('GET', '/');
  final ctx1 = Context(Request(rawRequest: rawReq1), container: Container());
  
  final res1 = await middleware.handle()(ctx1, () async {
    ctx1.session.put('user_id', 123);
    return Response.ok('ok');
  });

  final setCookie = res1.headers['set-cookie'] ?? '';
  if (setCookie.contains('kronix_session=')) {
    stdout.writeln('✅ Session cookie set in response.');
  } else {
    stdout.writeln('❌ Set-Cookie missing.');
  }

  // 2. Subsequent Request (With cookie)
  stdout.writeln('Testing session persistence...');
  final parts = setCookie.split('kronix_session=');
  final sessionId = parts[1].split(';')[0];
  
  final rawReq2 = MockHttpRequest('GET', '/');
  rawReq2.headers.add('Cookie', 'kronix_session=$sessionId');
  
  final ctx2 = Context(Request(rawRequest: rawReq2), container: Container());
  
  await middleware.handle()(ctx2, () async {
    final uid = ctx2.session.get<int>('user_id');
    if (uid == 123) {
      stdout.writeln('✅ Session data persisted correctly.');
    } else {
      stdout.writeln('❌ Session data lost. Got: $uid');
    }
    return Response.ok('ok');
  });
}

// ─── MOCKS ───────────────────────────────────────────────────────

/// Mock [HttpRequest] for Tier 2 verification.
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

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Mock [HttpHeaders] for Tier 2 verification.
class MockHttpHeaders implements HttpHeaders {
  /// Creates a new [MockHttpHeaders].
  MockHttpHeaders();

  final Map<String, List<String>> _data = <String, List<String>>{};

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    _data[name] ??= <String>[];
    _data[name]!.add(value.toString());
  }

  @override
  String? value(String name) => _data[name]?.first;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Mock [HttpResponse] for Tier 2 verification.
class MockHttpResponse implements HttpResponse {
  /// Creates a new [MockHttpResponse].
  MockHttpResponse();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
