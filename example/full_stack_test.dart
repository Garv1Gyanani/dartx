import 'package:dartx/dartx.dart';

// 1. SERVICES
class StatsService {
  int processed = 0;
  void log() => processed++;
}

// 2. REQUESTS
class CreateProductRequest extends FormRequest {
  @override
  Map<String, String> rules() => {
    'name': 'required|min:3',
    'price': 'required|numeric',
  };
}

// 3. MOCK DB
class MockDB extends DatabaseAdapter {
  @override
  QueryBuilder table(String name) => QueryBuilder(name, this);
  @override
  Future<QueryResult> query(String sql, [Map<String, dynamic>? params]) async {
    return PostgresQueryResult([{'id': 101, 'status': 'inserted'}]);
  }
  @override
  Future<T> transaction<T>(Future<T> Function(DatabaseExecutor tx) callback) async => await callback(MockExecutor());
  @override
  Future<DatabaseExecutor> beginTransaction() => throw UnimplementedError();
  @override
  Future<void> connect() async {}
  @override
  Future<void> close() async {}
}

class MockExecutor implements DatabaseExecutor {
  @override
  Future<QueryResult> query(String sql, [Map<String, dynamic>? params]) async => PostgresQueryResult([]);
  @override
  Future<void> commit() async {}
  @override
  Future<void> rollback() async {}
}

void main() async {
  final app = App();
  Config.set('APP_ENV', 'development');
  
  // DI Setup
  di.singleton<DatabaseAdapter>(MockDB());
  di.scoped((_) => StatsService());

  // GLOBAL MIDDLEWARE
  app.use((ctx, next) async {
    final stats = ctx.resolve<StatsService>();
    stats.log();
    return await next();
  });

  // ROUTES
  app.group('/api', callback: (router) {
    
    // Test 1: Validation & Scoped DI
    router.add('POST', '/products', (ctx) async {
      final data = ctx.validate(CreateProductRequest());
      final stats = ctx.resolve<StatsService>();
      
      return ctx.json({
        'received': data,
        'stats_processed_in_this_request': stats.processed,
      });
    });

    // Test 2: Standard Exceptions
    router.add('GET', '/secure', (ctx) async {
      throw ForbiddenException('API Key Missing');
    });

    // Test 3: ORM Query Builder
    router.add('GET', '/db-test', (ctx) async {
      final db = ctx.resolve<DatabaseAdapter>();
      final result = await db.table('items').where('id', '>', 10).get();
      return ctx.json(result);
    });

    // Test 4: Unhandled Crash
    router.add('GET', '/crash', (ctx) async {
      throw RangeError('Index out of bounds');
    });
  });

  Logger.level = LogLevel.debug;
  await app.listen(port: 3005);
}
