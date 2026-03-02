import 'dart:io';
import 'package:kronix/kronix.dart';

void main() async {
  stdout.writeln('========================================');
  stdout.writeln('   KRONIX CRITICAL BUG VERIFICATION');
  stdout.writeln('========================================\n');

  await testConfigBug();
  await testResponseHeadersBug();
  await testCorsBug();
  await testJwtAuthBug();
  await testMigrationBatchBug();
  
  stdout.writeln('\nVerification Complete.');
  exit(0);
}

/// Tests that Config.set() and Config.get() are consistent.
Future<void> testConfigBug() async {
  stdout.writeln('--- Testing Config Bug (set/get disconnect) ---');
  Config.set('VERIFY_KEY', 'verified_value');
  final value = Config.get('VERIFY_KEY');
  if (value == 'verified_value') {
    stdout.writeln('✅ Config set/get works correctly.');
  } else {
    stdout.writeln('❌ BUG CONFIRMED: Config.get() returned "$value" after Config.set() was used.');
  }
}

/// Tests that Response headers are mutable.
Future<void> testResponseHeadersBug() async {
  stdout.writeln('\n--- Testing Response Headers Bug (const map) ---');
  final res = Response(); // Default constructor should use mutable headers
  try {
    res.headers['X-Test'] = 'Value';
    stdout.writeln('✅ Response headers are mutable.');
  } catch (e) {
    stdout.writeln('❌ BUG CONFIRMED: Response headers are immutable (const). Error: $e');
  }
}

/// Tests that the CORS plugin handles default responses.
Future<void> testCorsBug() async {
  stdout.writeln('\n--- Testing CORS Plugin Bug ---');
  final cors = Cors();
  final ctx = Context(Request(rawRequest: MockHttpRequest('GET', '/')), container: Container());
  
  try {
    // This simulates the middleware chain where next() returns a default Response
    await cors.handle()(ctx, () async => Response()); 
    stdout.writeln('✅ CORS handled default response successfully.');
  } catch (e) {
    stdout.writeln('❌ BUG CONFIRMED: CORS crashed on default response. Error: $e');
  }
}

/// Tests that JWT auth doesn't crash on empty bodies (GET requests).
Future<void> testJwtAuthBug() async {
  stdout.writeln('\n--- Testing JWT Auth Bug (Body mutation) ---');
  final auth = Auth('secret');
  
  // 1. Test GET request (usually has empty body map)
  final rawReq = MockHttpRequest('GET', '/');
  final ctx = Context(Request(rawRequest: rawReq), container: Container());
  
  try {
    // Manually set auth header for test
    rawReq.headers.add('Authorization', 'Bearer ${auth.generateToken(<String, int>{'uid': 1})}');
    
    await auth.verify()(ctx, () async => Response.ok('ok'));
    stdout.writeln('✅ JWT verified successfully even with empty body.');
  } catch (e) {
    stdout.writeln('❌ BUG CONFIRMED: JWT verification crashed on empty body mutation. Error: $e');
  }
}

/// Tests the migration runner's batch increment logic.
Future<void> testMigrationBatchBug() async {
  stdout.writeln('\n--- Testing Migration Batch Bug ---');
  final db = VerificationMockDB();
  final runner = MigrationRunner(db, <MigrationEntry>[
    MigrationEntry('m1', VerificationMockMigration()),
    MigrationEntry('m2', VerificationMockMigration()),
  ]);

  await runner.run();
  
  stdout.writeln('ℹ️ Migration Runner behavior: It records each migration with a new batch ID if called sequentially.');
  stdout.writeln('ℹ️ (Verification relies on code analysis: _recordMigration is called inside loop, each calling _db.query(SELECT MAX(batch)))');
}

// ─── MOCKS ───────────────────────────────────────────────────────

/// Mock [HttpRequest] for bug verification.
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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Mock [HttpHeaders] for bug verification.
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

/// Mock database for verification.
class VerificationMockDB extends DatabaseAdapter {
  /// History of SQL queries executed.
  final List<String> history = <String>[];
  
  @override
  Future<QueryResult> query(String sql, [Map<String, dynamic>? params]) async {
    history.add(sql);
    if (sql.contains('SELECT MAX(batch)')) {
      return VerificationMockQueryResult(<Map<String, int>>[<String, int>{'max_batch': 0}]);
    }
    if (sql.contains('SELECT name FROM migrations')) {
      return VerificationMockQueryResult(<Map<String, dynamic>>[]);
    }
    if (sql.contains('pg_try_advisory_lock')) {
      return VerificationMockQueryResult(<Map<String, bool>>[<String, bool>{'acquired': true}]);
    }
    return VerificationMockQueryResult(<Map<String, dynamic>>[]);
  }

  @override
  Future<T> transaction<T>(Future<T> Function(DatabaseExecutor tx) callback) async {
    return callback(this);
  }

  @override
  QueryBuilder table(String name, [DatabaseExecutor? executor]) {
    return QueryBuilder(name, executor ?? this);
  }

  @override
  Future<void> connect() async {}

  @override
  Future<void> close() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Result of a verification mock query.
class VerificationMockQueryResult implements QueryResult {
  /// Creates a new [VerificationMockQueryResult].
  VerificationMockQueryResult(this.rows);

  @override
  final List<Map<String, dynamic>> rows;

  @override
  final int? affectedRows = 0;
}

/// Mock migration for verification.
class VerificationMockMigration extends Migration {
  /// Creates a new [VerificationMockMigration].
  VerificationMockMigration();

  @override
  Future<void> up(DatabaseExecutor db) async {}

  @override
  Future<void> down(DatabaseExecutor db) async {}
}
