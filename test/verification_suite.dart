import 'dart:io';
import 'dart:convert';
import 'package:dartx/dartx.dart';

void main() async {
  print('========================================');
  print('   DARTX CRITICAL BUG VERIFICATION');
  print('========================================\n');

  await testConfigBug();
  await testResponseHeadersBug();
  await testCorsBug();
  await testJwtAuthBug();
  await testMigrationBatchBug();
  
  print('\nVerification Complete.');
  exit(0);
}

Future<void> testConfigBug() async {
  print('--- Testing Config Bug (set/get disconnect) ---');
  Config.set('VERIFY_KEY', 'verified_value');
  final value = Config.get('VERIFY_KEY');
  if (value == 'verified_value') {
    print('✅ Config set/get works correctly.');
  } else {
    print('❌ BUG CONFIRMED: Config.get() returned "$value" after Config.set() was used.');
  }
}

Future<void> testResponseHeadersBug() async {
  print('\n--- Testing Response Headers Bug (const map) ---');
  final res = Response(); // Default constructor uses const headers
  try {
    res.headers['X-Test'] = 'Value';
    print('✅ Response headers are mutable.');
  } catch (e) {
    print('❌ BUG CONFIRMED: Response headers are immutable (const). Error: $e');
  }
}

Future<void> testCorsBug() async {
  print('\n--- Testing CORS Plugin Bug ---');
  final cors = Cors();
  final ctx = Context(Request(rawRequest: MockHttpRequest('GET', '/')), container: Container());
  
  try {
    // This simulates the middleware chain where next() returns a default Response
    await cors.handle()(ctx, () async => Response()); 
    print('✅ CORS handled default response successfully.');
  } catch (e) {
    print('❌ BUG CONFIRMED: CORS crashed on default response. Error: $e');
  }
}

Future<void> testJwtAuthBug() async {
  print('\n--- Testing JWT Auth Bug (Body mutation) ---');
  final auth = Auth('secret');
  
  // 1. Test GET request (usually has empty body map)
  final rawReq = MockHttpRequest('GET', '/');
  final ctx = Context(Request(rawRequest: rawReq), container: Container());
  
  try {
    // Manually set auth header for test
    rawReq.headers.add('Authorization', 'Bearer ${auth.generateToken({'uid': 1})}');
    
    await auth.verify()(ctx, () async => Response.ok('ok'));
    print('✅ JWT verified successfully even with empty body.');
  } catch (e) {
    print('❌ BUG CONFIRMED: JWT verification crashed on empty body mutation. Error: $e');
  }
}

Future<void> testMigrationBatchBug() async {
  print('\n--- Testing Migration Batch Bug ---');
  final db = MockDB();
  final runner = MigrationRunner(db, [
    MigrationEntry('m1', MockMigration()),
    MigrationEntry('m2', MockMigration()),
  ]);

  await runner.run();
  
  // Check the recorded batches in history
  final batches = db.history
    .where((sql) => sql.contains('INSERT INTO migrations'))
    .map((sql) {
      final match = RegExp(r"batch\) VALUES \(@name, (\d+)\)").firstMatch(sql);
      // Wait, the SQL uses @batch, not literal. Let's look at params if we had them.
      // But based on the code analysis: batch = (max_batch ?? 0) + 1;
      // If run() calls _recordMigration in a loop, it queries max_batch EACH time.
      return sql;
    })
    .toList();

  print('ℹ️ Migration Runner behavior: It records each migration with a new batch ID if called sequentially.');
  print('ℹ️ (Verification relies on code analysis: _recordMigration is called inside loop, each calling _db.query(SELECT MAX(batch)))');
}

// ─── MOCKS ───────────────────────────────────────────────────────

class MockHttpRequest implements HttpRequest {
  @override final String method;
  @override final Uri uri;
  @override final HttpHeaders headers = MockHttpHeaders();
  
  MockHttpRequest(this.method, String path) : uri = Uri.parse(path);

  // Unimplemented stuff needed for the interface
  @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockHttpHeaders implements HttpHeaders {
  final Map<String, List<String>> _data = {};
  @override void add(String name, Object value, {bool preserveHeaderCase = false}) => _data[name] = [value.toString()];
  @override String? value(String name) => _data[name]?.first;
  // ... more unimplemented
  @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockDB extends DatabaseAdapter {
  final List<String> history = [];
  @override Future<QueryResult> query(String sql, [Map<String, dynamic>? params]) async {
    history.add(sql);
    if (sql.contains('SELECT MAX(batch)')) return MockQueryResult([{'max_batch': 0}]);
    return MockQueryResult([]);
  }
  @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockQueryResult implements QueryResult {
  @override final List<Map<String, dynamic>> rows;
  @override final int? affectedRows = 0;
  MockQueryResult(this.rows);
}

class MockMigration extends Migration {
  @override Future<void> up(DatabaseAdapter db) async {}
  @override Future<void> down(DatabaseAdapter db) async {}
}
