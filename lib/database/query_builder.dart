import 'adapter.dart';

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

  QueryBuilder(this._table, this._adapter);

  QueryBuilder select(List<String> columns) {
    _columns = columns;
    return this;
  }

  QueryBuilder where(String column, String operator, dynamic value) {
    final paramName = 'v${++_paramIndex}';
    _wheres.add('$column $operator @$paramName');
    _params[paramName] = value;
    return this;
  }

  QueryBuilder orderBy(String column, [String direction = 'ASC']) {
    _orderBy = '$column ${direction.toUpperCase()}';
    return this;
  }

  QueryBuilder limit(int value) {
    _limit = value;
    return this;
  }

  QueryBuilder offset(int value) {
    _offset = value;
    return this;
  }

  String _buildSql() {
    var sql = 'SELECT ${_columns.join(', ')} FROM $_table';

    if (_wheres.isNotEmpty) {
      sql += ' WHERE ${_wheres.join(' AND ')}';
    }

    if (_orderBy != null) {
      sql += ' ORDER BY $_orderBy';
    }

    if (_limit != null) {
      sql += ' LIMIT $_limit';
    }

    if (_offset != null) {
      sql += ' OFFSET $_offset';
    }

    return sql;
  }

  Future<List<Map<String, dynamic>>> get() async {
    final result = await _adapter.query(_buildSql(), _params);
    return result.rows;
  }

  Future<Map<String, dynamic>?> first() async {
    limit(1);
    final results = await get();
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> count() async {
    final originalColumns = _columns;
    _columns = ['COUNT(*) as count'];
    final result = await first();
    _columns = originalColumns;
    return result != null ? int.parse(result['count'].toString()) : 0;
  }

  // Insert, Update, Delete
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

  Future<QueryResult> update(Map<String, dynamic> data) async {
    final sets = data.keys.map((k) {
      final paramName = 'u${++_paramIndex}';
      _params[paramName] = data[k];
      return '$k = @$paramName';
    }).join(', ');

    var sql = 'UPDATE $_table SET $sets';
    if (_wheres.isNotEmpty) {
      sql += ' WHERE ${_wheres.join(' AND ')}';
    }
    return await _adapter.query(sql, _params);
  }

  Future<QueryResult> delete() async {
    var sql = 'DELETE FROM $_table';
    if (_wheres.isNotEmpty) {
      sql += ' WHERE ${_wheres.join(' AND ')}';
    }
    return await _adapter.query(sql, _params);
  }
}
