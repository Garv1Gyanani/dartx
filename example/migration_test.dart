import 'package:dartx/dartx.dart';

// Reuse mock from orm_demo or define here
class MockDatabaseAdapter implements DatabaseAdapter {
  final List<String> history = [];
  final List<Map<String, dynamic>> applied = [];

  @override
  QueryBuilder table(String name) => QueryBuilder(name, this);

  @override
  Future<QueryResult> query(String sql, [Map<String, dynamic>? params]) async {
    history.add(sql);
    
    if (sql.contains('SELECT name FROM migrations')) {
      return MockQueryResult(applied);
    }
    
    if (sql.contains('SELECT MAX(batch)')) {
      return MockQueryResult([{'max_batch': 1}]);
    }

    if (sql.contains('INSERT INTO migrations')) {
      applied.add({'name': params!['name']});
    }

    return MockQueryResult([]);
  }

  @override
  Future<T> transaction<T>(Future<T> Function(DatabaseExecutor tx) callback) async => throw UnimplementedError();
  @override
  Future<DatabaseExecutor> beginTransaction() => throw UnimplementedError();
  @override
  Future<void> connect() async {}
  @override
  Future<void> close() async {}
}

class MockQueryResult implements QueryResult {
  @override
  final List<Map<String, dynamic>> rows;
  @override
  final int? affectedRows = 0;
  MockQueryResult(this.rows);
}

class TestMigration extends Migration {
  @override
  Future<void> up(DatabaseAdapter db) async {
    await db.query('CREATE TABLE test (id INT)');
  }

  @override
  Future<void> down(DatabaseAdapter db) async {
    await db.query('DROP TABLE test');
  }
}

void main() async {
  final db = MockDatabaseAdapter();
  final runner = MigrationRunner(db, [
    MigrationEntry('2023_01_01_create_test', TestMigration()),
  ]);

  print('--- Running Migrations ---');
  await runner.run();
  
  if (db.history.any((sql) => sql.contains('CREATE TABLE test'))) {
    print('✅ migration.up was called.');
  }
  
  if (db.applied.any((m) => m['name'] == '2023_01_01_create_test')) {
    print('✅ migration was recorded in DB.');
  }

  print('\n--- Running Rollback ---');
  await runner.rollback();

  if (db.history.any((sql) => sql.contains('DROP TABLE test'))) {
    print('✅ migration.down was called.');
  }
}
