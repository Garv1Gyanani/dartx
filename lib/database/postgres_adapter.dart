import 'package:postgres/postgres.dart';
import 'adapter.dart';
import 'query_builder.dart';
import '../di/container.dart';

/// Implementation of [QueryResult] for PostgreSQL.
class PostgresQueryResult implements QueryResult {
  @override
  final List<Map<String, dynamic>> rows;
  @override
  final int? affectedRows;

  /// Creates a new [PostgresQueryResult].
  PostgresQueryResult(this.rows, [this.affectedRows]);
}

/// A [DatabaseAdapter] implementation for PostgreSQL using the `package:postgres` Pool.
class PostgresAdapter implements DatabaseAdapter, Disposable {
  final Pool _pool;

  /// Creates a [PostgresAdapter] with the specified connection settings.
  PostgresAdapter({
    required String host,
    required String database,
    String? username,
    String? password,
    int port = 5432,
    int maxConnections = 10,
  }) : _pool = Pool.withEndpoints(
          [
            Endpoint(
              host: host,
              database: database,
              username: username,
              password: password,
              port: port,
            )
          ],
          settings: PoolSettings(maxConnectionCount: maxConnections),
        );

  @override
  QueryBuilder table(String name) => QueryBuilder(name, this);

  @override
  Future<void> connect() async {
    // Pool usually connects lazily.
  }

  @override
  Future<QueryResult> query(String sql, [Map<String, dynamic>? params]) async {
    final result = await _pool.execute(Sql.named(sql), parameters: params ?? {});
    return _transformResult(result);
  }

  @override
  Future<T> transaction<T>(Future<T> Function(DatabaseExecutor tx) callback) async {
    return await _pool.run((session) async {
      final executor = PostgresExecutor(session);
      return await callback(executor);
    });
  }

  @override
  Future<DatabaseExecutor> beginTransaction() async {
    throw UnsupportedError(
      'Manual beginTransaction() is not supported by Postgres v3 Pool. '
      'Please use db.transaction((tx) => ...) for safe scoped transactions.'
    );
  }

  static QueryResult _transformResult(Result result) {
    final rows = result.map((row) => row.toColumnMap()).toList();
    return PostgresQueryResult(rows, result.affectedRows);
  }

  @override
  Future<void> close() async {
    await _pool.close();
  }

  @override
  Future<void> dispose() async => await close();
}

/// Implementation of [DatabaseExecutor] for PostgreSQL sessions/transactions.
class PostgresExecutor implements DatabaseExecutor {
  final Session _session;

  /// Creates a new [PostgresExecutor] wrapping the given [session].
  PostgresExecutor(this._session);

  @override
  Future<QueryResult> query(String sql, [Map<String, dynamic>? params]) async {
    final result = await _session.execute(Sql.named(sql), parameters: params ?? {});
    return PostgresAdapter._transformResult(result);
  }

  @override
  Future<void> commit() async {
    // In postgres v3 .run(), commit is automatic if the callback completes.
  }

  @override
  Future<void> rollback() async {
    // In postgres v3 .run(), rollback is automatic if the callback throws.
    throw Exception('Rollback initiated');
  }
}
