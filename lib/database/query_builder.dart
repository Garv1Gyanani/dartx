import 'adapter.dart';

/// A fluent SQL query builder for constructing and executing database queries.
class QueryBuilder {
  final String _table;
  final DatabaseAdapter _adapter;
  
  final List<String> _wheres = [];
  final Map<String, dynamic> _params = {};
  int _paramIndex = 0;
  
  List<String> _columns = ['*'];
  String? _orderBy;
  int? _limit;
  int? _offset;

  /// Creates a new [QueryBuilder] for the given [table] name.
  QueryBuilder(this._table, this._adapter);

  /// Specifies the [columns] to be selected. Defaults to `['*']`.
  QueryBuilder select(List<String> columns) {
    _columns = columns;
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

  void _addWhere(String column, String operator, dynamic value, String conjunction) {
    final paramName = 'v${++_paramIndex}';
    final prefix = _wheres.isEmpty ? '' : '$conjunction ';
    _wheres.add('$prefix$column $operator @$paramName');
    _params[paramName] = value;
  }

  /// Adds an `ORDER BY` clause for [column] and [direction].
  QueryBuilder orderBy(String column, [String direction = 'ASC']) {
    _orderBy = '$column ${direction.toUpperCase()}';
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

  String _buildSql({List<String>? overrideColumns}) {
    final cols = overrideColumns ?? _columns;
    var sql = 'SELECT ${cols.join(', ')} FROM $_table';

    if (_wheres.isNotEmpty) {
      sql += ' WHERE ${_wheres.join(' ')}';
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
    final result = await _adapter.query(_buildSql(), _params);
    return result.rows;
  }

  /// Executes a `SELECT` query and returns only the first matching row.
  Future<Map<String, dynamic>?> first() async {
    final results = await _adapter.query('${_buildSql()} LIMIT 1', _params);
    return results.rows.isNotEmpty ? results.rows.first : null;
  }

  /// Executes a `COUNT` query and returns the total number of matching rows.
  Future<int> count() async {
    final results = await _adapter.query(_buildSql(overrideColumns: ['COUNT(*) as count']), _params);
    final result = results.rows.isNotEmpty ? results.rows.first : null;
    return result != null ? int.parse(result['count'].toString()) : 0;
  }

  /// Executes an `INSERT` statement with the provided [data].
  Future<QueryResult> insert(Map<String, dynamic> data) async {
    final columns = data.keys.join(', ');
    final values = data.keys.map((k) {
      final paramName = 'i${++_paramIndex}';
      _params[paramName] = data[k];
      return '@$paramName';
    }).join(', ');

    final sql = 'INSERT INTO $_table ($columns) VALUES ($values)';
    return await _adapter.query(sql, _params);
  }

  /// Executes an `UPDATE` statement with the provided [data].
  Future<QueryResult> update(Map<String, dynamic> data) async {
    final sets = data.keys.map((k) {
      final paramName = 'u${++_paramIndex}';
      _params[paramName] = data[k];
      return '$k = @$paramName';
    }).join(', ');

    var sql = 'UPDATE $_table SET $sets';
    if (_wheres.isNotEmpty) {
      sql += ' WHERE ${_wheres.join(' ')}';
    }
    return await _adapter.query(sql, _params);
  }

  /// Executes a `DELETE` statement.
  Future<QueryResult> delete() async {
    var sql = 'DELETE FROM $_table';
    if (_wheres.isNotEmpty) {
      sql += ' WHERE ${_wheres.join(' ')}';
    }
    return await _adapter.query(sql, _params);
  }
}
