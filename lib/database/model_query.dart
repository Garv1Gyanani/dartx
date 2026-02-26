import 'adapter.dart';
import 'model.dart';
import 'query_builder.dart';

/// A type-safe query builder that returns model instances instead of raw maps.
///
/// Wraps the underlying [QueryBuilder] and automatically maps results to [T].
///
/// ```dart
/// final users = await ModelQuery<User>(db, User.fromRow)
///   .where('active', '=', true)
///   .orderBy('name')
///   .get();
/// ```
class ModelQuery<T extends Model> {
  final DatabaseExecutor _executor;
  final ModelFactory<T> _factory;
  final String _tableName;
  late final QueryBuilder _builder;

  /// Creates a typed query for models of type [T].
  ///
  /// [executor] is the database connection or transaction.
  /// [factory] constructs a [T] from a database row map.
  /// [tableName] overrides the table name (optional if model defines it).
  ModelQuery(this._executor, this._factory, {String? tableName})
      : _tableName = tableName ?? _inferTableName<T>() {
    _builder = QueryBuilder(_tableName, _executor);
  }

  /// Infers table name from a dummy instance — falls back to lowercase type name + 's'.
  static String _inferTableName<T>() {
    // Convention: ClassName -> classnames (pluralized lowercase)
    final name = T.toString().toLowerCase();
    return '${name}s';
  }

  // ─── Fluent Filter Methods ────────────────────────────────────────

  /// Adds a `WHERE` clause.
  ModelQuery<T> where(String column, String operator, dynamic value) {
    _builder.where(column, operator, value);
    return this;
  }

  /// Adds an `OR WHERE` clause.
  ModelQuery<T> orWhere(String column, String operator, dynamic value) {
    _builder.orWhere(column, operator, value);
    return this;
  }

  /// Adds a `WHERE column IS NULL` clause.
  ModelQuery<T> whereNull(String column) {
    _builder.whereNull(column);
    return this;
  }

  /// Adds a `WHERE column IS NOT NULL` clause.
  ModelQuery<T> whereNotNull(String column) {
    _builder.whereNotNull(column);
    return this;
  }

  /// Adds a `WHERE column IN (...)` clause.
  ModelQuery<T> whereIn(String column, List<dynamic> values) {
    _builder.whereIn(column, values);
    return this;
  }

  /// Specifies which columns to select.
  ModelQuery<T> select(List<String> columns) {
    _builder.select(columns);
    return this;
  }

  /// Adds an `ORDER BY` clause.
  ModelQuery<T> orderBy(String column, [String direction = 'ASC']) {
    _builder.orderBy(column, direction);
    return this;
  }

  /// Adds a `GROUP BY` clause.
  ModelQuery<T> groupBy(String column) {
    _builder.groupBy(column);
    return this;
  }

  /// Adds a `HAVING` clause.
  ModelQuery<T> having(String column, String operator, dynamic value) {
    _builder.having(column, operator, value);
    return this;
  }

  /// Adds a `LIMIT` clause.
  ModelQuery<T> limit(int value) {
    _builder.limit(value);
    return this;
  }

  /// Adds an `OFFSET` clause.
  ModelQuery<T> offset(int value) {
    _builder.offset(value);
    return this;
  }

  /// Adds an INNER JOIN.
  ModelQuery<T> join(String table, String col1, String op, String col2) {
    _builder.join(table, col1, op, col2);
    return this;
  }

  /// Adds a LEFT JOIN.
  ModelQuery<T> leftJoin(String table, String col1, String op, String col2) {
    _builder.leftJoin(table, col1, op, col2);
    return this;
  }

  // ─── Terminal Operations (Return Typed Results) ───────────────────

  /// Executes the query and returns all matching models.
  Future<List<T>> get() async {
    final rows = await _builder.get();
    return rows.map((row) {
      final model = _factory(row);
      model.setRawData(_executor, row);
      return model;
    }).toList();
  }

  /// Returns the first matching model, or `null` if none found.
  Future<T?> first() async {
    final row = await _builder.first();
    if (row == null) return null;
    final model = _factory(row);
    model.setRawData(_executor, row);
    return model;
  }

  /// Finds a model by its primary key [id].
  Future<T?> find(dynamic id) async {
    final row = await QueryBuilder(_tableName, _executor)
        .where('id', '=', id)
        .first();
    if (row == null) return null;
    final model = _factory(row);
    model.setRawData(_executor, row);
    return model;
  }

  /// Finds a model by primary key or throws if not found.
  Future<T> findOrFail(dynamic id) async {
    final model = await find(id);
    if (model == null) {
      throw StateError('$T with id $id not found');
    }
    return model;
  }

  /// Returns the count of matching rows.
  Future<int> count() async {
    return await _builder.count();
  }

  /// Checks if any rows match the current query.
  Future<bool> exists() async {
    return (await count()) > 0;
  }

  // ─── Mutation Operations ──────────────────────────────────────────

  /// Creates a new record from the model and returns the model with `id` populated.
  Future<T> create(T model) async {
    final data = <String, dynamic>{...model.toMap()};

    if (model.timestamps) {
      final now = DateTime.now().toUtc();
      data['created_at'] = now;
      data['updated_at'] = now;
    }

    // Use RETURNING to get the full inserted row back
    final insertBuilder = QueryBuilder(_tableName, _executor);
    await insertBuilder.insert(data);

    // Fetch the created record (for databases that support RETURNING, this could be optimized)
    // For now, get the last inserted record
    final row = await QueryBuilder(_tableName, _executor)
        .orderBy('id', 'DESC')
        .first();

    if (row != null) {
      final created = _factory(row);
      created.setRawData(_executor, row);
      return created;
    }
    return model;
  }

  /// Updates an existing model in the database.
  Future<T> save(T model) async {
    if (!model.exists) {
      return await create(model);
    }

    final data = <String, dynamic>{...model.toMap()};
    if (model.timestamps) {
      data['updated_at'] = DateTime.now().toUtc();
    }

    await QueryBuilder(_tableName, _executor)
        .where('id', '=', model.id)
        .update(data);

    // Return a fresh copy from DB
    return await findOrFail(model.id);
  }

  /// Deletes a model by its primary key.
  Future<void> destroy(dynamic id) async {
    await QueryBuilder(_tableName, _executor)
        .where('id', '=', id)
        .delete();
  }

  /// Deletes a model instance from the database.
  Future<void> destroyModel(T model) async {
    if (!model.exists) {
      throw StateError('Cannot delete a model that has not been persisted');
    }
    await destroy(model.id);
    model.id = null;
  }

  /// Performs a bulk update on all rows matching the current query.
  Future<int> updateAll(Map<String, dynamic> data) async {
    if (_builder.toString().isEmpty) {
      throw StateError('Bulk update requires at least one WHERE clause');
    }
    final result = await _builder.update(data);
    return result.affectedRows ?? 0;
  }

  /// Deletes all rows matching the current query.
  Future<int> deleteAll() async {
    final result = await _builder.delete();
    return result.affectedRows ?? 0;
  }

  // ─── Pagination ───────────────────────────────────────────────────

  /// Returns a paginated result.
  Future<PaginatedResult<T>> paginate({int page = 1, int perPage = 15}) async {
    final total = await ModelQuery<T>(_executor, _factory, tableName: _tableName)
        .count();
    
    final items = await ModelQuery<T>(_executor, _factory, tableName: _tableName)
        .limit(perPage)
        .offset((page - 1) * perPage)
        .orderBy('id')
        .get();

    return PaginatedResult<T>(
      items: items,
      total: total,
      page: page,
      perPage: perPage,
      lastPage: (total / perPage).ceil(),
    );
  }
}

/// Holds a paginated set of results with metadata.
class PaginatedResult<T> {
  final List<T> items;
  final int total;
  final int page;
  final int perPage;
  final int lastPage;

  PaginatedResult({
    required this.items,
    required this.total,
    required this.page,
    required this.perPage,
    required this.lastPage,
  });

  bool get hasNextPage => page < lastPage;
  bool get hasPrevPage => page > 1;

  Map<String, dynamic> toJson() => {
    'data': items,
    'meta': {
      'total': total,
      'page': page,
      'per_page': perPage,
      'last_page': lastPage,
      'has_next': hasNextPage,
      'has_prev': hasPrevPage,
    },
  };
}
