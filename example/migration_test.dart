import 'package:kronix/kronix.dart';

/// Mock database adapter for migration testing.
class MockDatabaseAdapter implements DatabaseAdapter {
  /// Creates a new [MockDatabaseAdapter].
  MockDatabaseAdapter();

  /// History of SQL queries executed.
  final List<String> history = <String>[];

  /// List of applied migrations.
  final List<Map<String, dynamic>> applied = <Map<String, dynamic>>[];

  @override
  QueryBuilder table(String name, [DatabaseExecutor? executor]) =>
      QueryBuilder(name, executor ?? this);

  @override
  Future<QueryResult> query(String sql, [Map<String, dynamic>? params]) async {
    history.add(sql);
    
    if (sql.contains('SELECT name FROM migrations')) {
      return MockQueryResult(applied);
    }
    
    if (sql.contains('SELECT MAX(batch)')) {
      return MockQueryResult(<Map<String, int>>[<String, int>{'max_batch': 1}]);
    }

    if (sql.contains('INSERT INTO migrations')) {
      applied.add(<String, dynamic>{'name': params!['name']});
    }

    return MockQueryResult(<Map<String, dynamic>>[]);
  }

  @override
  Future<T> transaction<T>(Future<T> Function(DatabaseExecutor tx) callback) async =>
      callback(this);
  @override
  Future<void> connect() async {}
  @override
  Future<void> close() async {}
}

/// Result of a mock query.
class MockQueryResult implements QueryResult {
  /// Creates a new [MockQueryResult].
  MockQueryResult(this.rows);

  @override
  final List<Map<String, dynamic>> rows;

  @override
  final int? affectedRows = 0;
}

/// A test migration for demonstration.
class TestMigration extends Migration {
  /// Creates a new [TestMigration].
  TestMigration();

  @override
  Future<void> up(DatabaseExecutor db) async {
    await db.query('CREATE TABLE test (id INT)');
  }

  @override
  Future<void> down(DatabaseExecutor db) async {
    await db.query('DROP TABLE test');
  }
}

void main() async {
  final db = MockDatabaseAdapter();
  final runner = MigrationRunner(db, <MigrationEntry>[
    MigrationEntry('2023_01_01_create_test', TestMigration()),
  ]);

  stdout.writeln('--- Running Migrations ---');
  await runner.run();
  
  if (db.history.any((sql) => sql.contains('CREATE TABLE test'))) {
    stdout.writeln('✅ migration.up was called.');
  }
  
  if (db.applied.any((m) => m['name'] == '2023_01_01_create_test')) {
    stdout.writeln('✅ migration was recorded in DB.');
  }

  stdout.writeln('\n--- Running Rollback ---');
  await runner.rollback();

  if (db.history.any((sql) => sql.contains('DROP TABLE test'))) {
    stdout.writeln('✅ migration.down was called.');
  }
}
