import 'query_builder.dart';

abstract class QueryResult {
  List<Map<String, dynamic>> get rows;
  int? get affectedRows;
}

abstract class DatabaseAdapter {
  QueryBuilder table(String name);
  Future<QueryResult> query(String sql, [Map<String, dynamic>? params]);
  Future<T> transaction<T>(Future<T> Function(DatabaseExecutor tx) callback);
  Future<DatabaseExecutor> beginTransaction();
  Future<void> connect();
  Future<void> close();
}

abstract class DatabaseExecutor {
  Future<QueryResult> query(String sql, [Map<String, dynamic>? params]);
  Future<void> commit();
  Future<void> rollback();
}
