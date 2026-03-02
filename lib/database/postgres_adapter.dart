import 'package:postgres/postgres.dart';
import 'adapter.dart';
import 'query_builder.dart';
import '../di/container.dart';

/// Implementation of [QueryResult] for PostgreSQL.
class PostgresQueryResult implements QueryResult {
  /// Creates a new [PostgresQueryResult].
  PostgresQueryResult(this.rows, [this.affectedRows]);

  @override
  final List<Map<String, dynamic>> rows;
  @override
  final int? affectedRows;
}

/// A [DatabaseAdapter] implementation for PostgreSQL using the `package:postgres` Pool.
class PostgresAdapter implements DatabaseAdapter, Disposable {
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

  final Pool _pool;

  @override
  QueryBuilder table(String name, [DatabaseExecutor? executor]) => 
    QueryBuilder(name, executor ?? this);

  @override
  Future<void> connect() async {
    // Pool usually connects lazily.
  }

  @override
  Future<QueryResult> query(String sql, [Map<String, dynamic>? params]) async {
    final result = await _pool.execute(Sql.named(sql), parameters: params ?? {});
    return transformResult(result);
  }

  @override
  Future<T> transaction<T>(Future<T> Function(DatabaseExecutor tx) callback) async {
    return await _pool.run((session) async {
      final executor = PostgresExecutor(session);
      return await callback(executor);
    });
  }

  /// Transforms a raw database [result] into a persistent [QueryResult].
  static QueryResult transformResult(Result result) {
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
/// 
/// Transactions are managed by the pool's `run()` scope:
/// - **Commit**: Automatic when the callback completes successfully.
/// - **Rollback**: Automatic when the callback throws an exception.
class PostgresExecutor implements DatabaseExecutor {
  /// Creates a new [PostgresExecutor] wrapping the given [session].
  PostgresExecutor(this._session);

  final Session _session;

  @override
  Future<QueryResult> query(String sql, [Map<String, dynamic>? params]) async {
    final result = await _session.execute(Sql.named(sql), parameters: params ?? {});
    return PostgresAdapter.transformResult(result);
  }

  @override
  Future<T> transaction<T>(Future<T> Function(DatabaseExecutor tx) callback) async {
    // Within a session, we're already in a transaction scope.
    return await callback(this);
  }
}
