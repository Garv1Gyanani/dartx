import 'query_builder.dart';

/// Represents the result of a database query execution.
abstract class QueryResult {
  /// The list of rows returned by the query, represented as Maps.
  List<Map<String, dynamic>> get rows;

  /// The number of rows affected by an INSERT, UPDATE, or DELETE query.
  int? get affectedRows;
}

/// Abstract interface for database drivers.
abstract class DatabaseAdapter {
  /// Returns a [QueryBuilder] for the specified [name] (table).
  QueryBuilder table(String name);

  /// Executes a raw [sql] query with optional [params].
  Future<QueryResult> query(String sql, [Map<String, dynamic>? params]);

  /// Executes multiple queries within a single transaction.
  Future<T> transaction<T>(Future<T> Function(DatabaseExecutor tx) callback);

  /// Manually starts a new transaction.
  Future<DatabaseExecutor> beginTransaction();

  /// Establishes a connection to the database.
  Future<void> connect();

  /// Closes the database connection.
  Future<void> close();
}

/// Interface for executing queries within a specific database scope (e.g., a transaction).
abstract class DatabaseExecutor {
  /// Executes a raw [sql] query within this executor's scope.
  Future<QueryResult> query(String sql, [Map<String, dynamic>? params]);

  /// Commits all pending changes in this scope.
  Future<void> commit();

  /// Reverts all pending changes in this scope.
  Future<void> rollback();
}
