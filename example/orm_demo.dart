import 'package:dartx/dartx.dart';

// Mocking the behavior for demo since we don't have a real Postgres running
class MockDatabaseAdapter implements DatabaseAdapter {
  @override
  QueryBuilder table(String name) => QueryBuilder(name, this);

  @override
  Future<QueryResult> query(String sql, [Map<String, dynamic>? params]) async {
    print('🔍 Executing SQL: $sql with params: $params');
    return MockQueryResult([
      {'id': 1, 'email': 'garv@example.com', 'name': 'Garv'}
    ]);
  }

  @override
  Future<T> transaction<T>(Future<T> Function(DatabaseExecutor tx) callback) async {
    print('🏁 Starting Transaction');
    final result = await callback(MockDatabaseExecutor());
    print('✅ Committing Transaction');
    return result;
  }

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
  final int? affectedRows = 1;
  MockQueryResult(this.rows);
}

class MockDatabaseExecutor implements DatabaseExecutor {
  @override
  Future<QueryResult> query(String sql, [Map<String, dynamic>? params]) async {
    print('🔍 [TX] Executing SQL: $sql with params: $params');
    return MockQueryResult([]);
  }
  @override
  Future<void> commit() async {}
  @override
  Future<void> rollback() async {}
}

void main() async {
  final app = App();
  
  // 1. Register Adapter
  final db = MockDatabaseAdapter();
  di.singleton<DatabaseAdapter>(db);

  // 2. Query Builder Demo
  app.get('/users/:id', (ctx) async {
    final user = await db.table('users')
        .where('id', '=', ctx.params['id'])
        .first();
    
    if (user == null) throw NotFoundException('User not found');
    return ctx.json(user);
  });

  // 3. Transaction Middleware Demo
  app.post('/register', (ctx) async {
    // This route uses a transaction
    return await db.transaction((tx) async {
      await tx.query('INSERT INTO users (email) VALUES (@email)', {'email': 'new@user.com'});
      await tx.query('INSERT INTO profiles (user_id) VALUES (@id)', {'id': 1});
      
      return ctx.json({'status': 'registered'});
    });
  }, middleware: []); // Could use transactionMiddleware() here if globally registered

  Logger.level = LogLevel.debug;
  await app.listen(port: 3004); // Changed port to avoid conflict
}
