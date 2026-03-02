import 'adapter.dart';

/// Regex for validating SQL identifiers (table names, column names).
final _identifierPattern = RegExp(r'^[a-zA-Z_][a-zA-Z0-9_.]*$');

/// Validates and quotes a SQL identifier to prevent injection.
String _quoteIdentifier(String identifier) {
  // Allow expressions like COUNT(*), table.column, and aliases
  if (identifier == '*' || identifier.contains('(')) return identifier;
  
  // Split on dots for qualified names like "users.id"
  return identifier.split('.').map((part) {
    if (!_identifierPattern.hasMatch(part)) {
      throw ArgumentError('Invalid SQL identifier: "$part"');
    }
    return '"$part"';
  }).join('.');
}

/// A fluent SQL query builder for constructing and executing database queries.
/// 
/// Each terminal operation (get, first, insert, etc.) creates a snapshot of the
/// current state before executing, so the builder can be safely reused.
class QueryBuilder {
  /// Creates a new [QueryBuilder] for the given [table] name.
  QueryBuilder(this._table, this._executor);

  final String _table;
  final DatabaseExecutor _executor;
  
  final List<String> _wheres = [];
  final Map<String, dynamic> _params = {};
  int _paramIndex = 0;
  
  List<String> _columns = ['*'];
  final List<String> _joins = [];
  String? _orderBy;
  String? _groupBy;
  String? _having;
  int? _limit;
  int? _offset;

  /// Specifies the [columns] to be selected. Defaults to `['*']`.
  QueryBuilder select(List<String> columns) {
    _columns = columns.map(_quoteIdentifier).toList();
    return this;
  }

  /// Adds a `WHERE` clause with an `AND` conjunction.
  QueryBuilder where(String column, String operator, dynamic value) {
    _addWhere(column, operator, value, 'AND');
    return this;
  }

  /// Adds a `WHERE` clause with an `OR` conjunction.
  QueryBuilder orWhere(String column, String operator, dynamic value) {
    _addWhere(column, operator, value, 'OR');
    return this;
  }

  /// Adds a `WHERE column IS NULL` clause.
  QueryBuilder whereNull(String column) {
    final prefix = _wheres.isEmpty ? '' : 'AND ';
    _wheres.add('$prefix${_quoteIdentifier(column)} IS NULL');
    return this;
  }

  /// Adds a `WHERE column IS NOT NULL` clause.
  QueryBuilder whereNotNull(String column) {
    final prefix = _wheres.isEmpty ? '' : 'AND ';
    _wheres.add('$prefix${_quoteIdentifier(column)} IS NOT NULL');
    return this;
  }

  /// Adds a `WHERE column IN (...)` clause.
  QueryBuilder whereIn(String column, List<dynamic> values) {
    final placeholders = <String>[];
    for (final v in values) {
      final paramName = 'v${++_paramIndex}';
      _params[paramName] = v;
      placeholders.add('@$paramName');
    }
    final prefix = _wheres.isEmpty ? '' : 'AND ';
    _wheres.add('$prefix${_quoteIdentifier(column)} IN (${placeholders.join(', ')})');
    return this;
  }

  void _addWhere(String column, String operator, dynamic value, String conjunction) {
    final paramName = 'v${++_paramIndex}';
    final prefix = _wheres.isEmpty ? '' : '$conjunction ';
    _wheres.add('$prefix${_quoteIdentifier(column)} $operator @$paramName');
    _params[paramName] = value;
  }

  /// Adds an INNER JOIN clause.
  QueryBuilder join(String table, String col1, String operator, String col2) {
    _joins.add('INNER JOIN ${_quoteIdentifier(table)} ON ${_quoteIdentifier(col1)} $operator ${_quoteIdentifier(col2)}');
    return this;
  }

  /// Adds a LEFT JOIN clause.
  QueryBuilder leftJoin(String table, String col1, String operator, String col2) {
    _joins.add('LEFT JOIN ${_quoteIdentifier(table)} ON ${_quoteIdentifier(col1)} $operator ${_quoteIdentifier(col2)}');
    return this;
  }

  /// Adds a RIGHT JOIN clause.
  QueryBuilder rightJoin(String table, String col1, String operator, String col2) {
    _joins.add('RIGHT JOIN ${_quoteIdentifier(table)} ON ${_quoteIdentifier(col1)} $operator ${_quoteIdentifier(col2)}');
    return this;
  }

  /// Adds an `ORDER BY` clause for [column] and [direction].
  QueryBuilder orderBy(String column, [String direction = 'ASC']) {
    final dir = direction.toUpperCase();
    if (dir != 'ASC' && dir != 'DESC') {
      throw ArgumentError('Order direction must be ASC or DESC');
    }
    _orderBy = '${_quoteIdentifier(column)} $dir';
    return this;
  }

  /// Adds a `GROUP BY` clause.
  QueryBuilder groupBy(String column) {
    _groupBy = _quoteIdentifier(column);
    return this;
  }

  /// Adds a `HAVING` clause.
  QueryBuilder having(String column, String operator, dynamic value) {
    final paramName = 'h${++_paramIndex}';
    _having = '${_quoteIdentifier(column)} $operator @$paramName';
    _params[paramName] = value;
    return this;
  }

  /// Adds a `LIMIT` clause.
  QueryBuilder limit(int value) {
    _limit = value;
    return this;
  }

  /// Adds an `OFFSET` clause.
  QueryBuilder offset(int value) {
    _offset = value;
    return this;
  }

  /// Snapshots the current params to prevent state bleed across executions.
  Map<String, dynamic> _snapshotParams() => Map<String, dynamic>.from(_params);

  String _buildSelect({List<String>? overrideColumns}) {
    final cols = overrideColumns ?? _columns;
    var sql = 'SELECT ${cols.join(', ')} FROM ${_quoteIdentifier(_table)}';

    for (final j in _joins) {
      sql += ' $j';
    }

    if (_wheres.isNotEmpty) {
      sql += ' WHERE ${_wheres.join(' ')}';
    }

    if (_groupBy != null && overrideColumns == null) {
      sql += ' GROUP BY $_groupBy';
    }

    if (_having != null && overrideColumns == null) {
      sql += ' HAVING $_having';
    }

    if (_orderBy != null && overrideColumns == null) {
      sql += ' ORDER BY $_orderBy';
    }

    if (_limit != null && overrideColumns == null) {
      sql += ' LIMIT $_limit';
    }

    if (_offset != null && overrideColumns == null) {
      sql += ' OFFSET $_offset';
    }

    return sql;
  }

  /// Executes a `SELECT` query and returns the matching rows.
  Future<List<Map<String, dynamic>>> get() async {
    final result = await _executor.query(_buildSelect(), _snapshotParams());
    return result.rows;
  }

  /// Executes a `SELECT` query and returns only the first matching row.
  Future<Map<String, dynamic>?> first() async {
    final results = await _executor.query('${_buildSelect()} LIMIT 1', _snapshotParams());
    return results.rows.isNotEmpty ? results.rows.first : null;
  }

  /// Executes a `COUNT` query and returns the total number of matching rows.
  Future<int> count() async {
    final results = await _executor.query(_buildSelect(overrideColumns: ['COUNT(*) as count']), _snapshotParams());
    final result = results.rows.isNotEmpty ? results.rows.first : null;
    return result != null ? int.parse(result['count'].toString()) : 0;
  }

  /// Executes an `INSERT` statement with the provided [data].
  /// Returns the query result (includes affected rows).
  Future<QueryResult> insert(Map<String, dynamic> data) async {
    final params = _snapshotParams();
    final columns = data.keys.map(_quoteIdentifier).join(', ');
    final values = data.keys.map((k) {
      final paramName = 'i${++_paramIndex}';
      params[paramName] = data[k];
      return '@$paramName';
    }).join(', ');

    final sql = 'INSERT INTO ${_quoteIdentifier(_table)} ($columns) VALUES ($values)';
    return await _executor.query(sql, params);
  }

  /// Executes an `UPDATE` statement with the provided [data].
  Future<QueryResult> update(Map<String, dynamic> data) async {
    final params = _snapshotParams();
    final sets = data.keys.map((k) {
      final paramName = 'u${++_paramIndex}';
      params[paramName] = data[k];
      return '${_quoteIdentifier(k)} = @$paramName';
    }).join(', ');

    var sql = 'UPDATE ${_quoteIdentifier(_table)} SET $sets';
    if (_wheres.isNotEmpty) {
      sql += ' WHERE ${_wheres.join(' ')}';
    }
    return await _executor.query(sql, params);
  }

  /// Executes a `DELETE` statement.
  Future<QueryResult> delete() async {
    var sql = 'DELETE FROM ${_quoteIdentifier(_table)}';
    if (_wheres.isNotEmpty) {
      sql += ' WHERE ${_wheres.join(' ')}';
    }
    return await _executor.query(sql, _snapshotParams());
  }
}
