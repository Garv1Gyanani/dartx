import 'adapter.dart';

/// A fluent, type-safe schema builder for database migrations.
/// 
/// Instead of writing raw SQL in migrations, use the [Schema] class
/// to define tables declaratively:
/// 
/// ```dart
/// class CreateUsersTable extends Migration {
///   @override
///   Future<void> up(DatabaseExecutor db) async {
///     await Schema(db).create('users', (table) {
///       table.id();
///       table.string('name');
///       table.string('email').unique();
///       table.integer('age').nullable();
///       table.boolean('is_active').defaultsTo('true');
///       table.timestamps();
///     });
///   }
///   
///   @override
///   Future<void> down(DatabaseExecutor db) async {
///     await Schema(db).drop('users');
///   }
/// }
/// ```
class Schema {
  /// Creates a new [Schema] tied to the given database [executor].
  Schema(this._db);

  final DatabaseExecutor _db;

  /// Creates a new table with the given [name] using the [callback] to define columns.
  Future<void> create(String name, void Function(Blueprint table) callback) async {
    final blueprint = Blueprint(name);
    callback(blueprint);
    await _db.query(blueprint._toCreateSql());
  }

  /// Modifies an existing table by adding new columns.
  Future<void> alter(String name, void Function(Blueprint table) callback) async {
    final blueprint = Blueprint(name);
    callback(blueprint);
    for (final col in blueprint._columns) {
      await _db.query('ALTER TABLE "${_sanitize(name)}" ADD COLUMN ${col._toSql()}');
    }
  }

  /// Drops a table if it exists.
  Future<void> drop(String name) async {
    await _db.query('DROP TABLE IF EXISTS "${_sanitize(name)}" CASCADE');
  }

  /// Drops a table only if it exists (safe version).
  Future<void> dropIfExists(String name) async => drop(name);

  /// Renames a table.
  Future<void> rename(String from, String to) async {
    await _db.query('ALTER TABLE "${_sanitize(from)}" RENAME TO "${_sanitize(to)}"');
  }

  /// Checks if a table exists.
  Future<bool> hasTable(String name) async {
    final result = await _db.query(
      'SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = @name)',
      {'name': name},
    );
    return result.rows.first['exists'] == true;
  }

  /// Checks if a column exists on a table.
  Future<bool> hasColumn(String table, String column) async {
    final result = await _db.query(
      'SELECT EXISTS (SELECT FROM information_schema.columns WHERE table_name = @table AND column_name = @column)',
      {'table': table, 'column': column},
    );
    return result.rows.first['exists'] == true;
  }

  static String _sanitize(String identifier) {
    if (!RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$').hasMatch(identifier)) {
      throw ArgumentError('Invalid table/column name: "$identifier"');
    }
    return identifier;
  }
}

/// Defines the structure of a database table through a fluent API.
class Blueprint {
  /// Creates a new [Blueprint] for the given [table] name.
  Blueprint(this._table);

  final String _table;
  final List<ColumnDefinition> _columns = [];
  final List<String> _constraints = [];

  // ─── Column Types ────────────────────────────────────────────────

  /// Adds an auto-incrementing integer primary key named `id`.
  ColumnDefinition id([String name = 'id']) {
    return _addColumn(name, 'SERIAL', isPrimaryKey: true);
  }

  /// Adds a big auto-incrementing integer primary key.
  ColumnDefinition bigId([String name = 'id']) {
    return _addColumn(name, 'BIGSERIAL', isPrimaryKey: true);
  }

  /// Adds a UUID primary key with auto-generation.
  ColumnDefinition uuid([String name = 'id']) {
    return _addColumn(name, 'UUID', isPrimaryKey: true)
        .defaultsTo('gen_random_uuid()');
  }

  /// Adds a `VARCHAR(length)` column.
  ColumnDefinition string(String name, {int length = 255}) {
    return _addColumn(name, 'VARCHAR($length)');
  }

  /// Adds a `TEXT` column (unlimited length).
  ColumnDefinition text(String name) {
    return _addColumn(name, 'TEXT');
  }

  /// Adds an `INTEGER` column.
  ColumnDefinition integer(String name) {
    return _addColumn(name, 'INTEGER');
  }

  /// Adds a `BIGINT` column.
  ColumnDefinition bigInteger(String name) {
    return _addColumn(name, 'BIGINT');
  }

  /// Adds a `SMALLINT` column.
  ColumnDefinition smallInteger(String name) {
    return _addColumn(name, 'SMALLINT');
  }

  /// Adds a `DECIMAL(precision, scale)` column.
  ColumnDefinition decimal(String name, {int precision = 10, int scale = 2}) {
    return _addColumn(name, 'DECIMAL($precision, $scale)');
  }

  /// Adds a `REAL` (single-precision float) column.
  ColumnDefinition float(String name) {
    return _addColumn(name, 'REAL');
  }

  /// Adds a `DOUBLE PRECISION` column.
  ColumnDefinition doublePrecision(String name) {
    return _addColumn(name, 'DOUBLE PRECISION');
  }

  /// Adds a `BOOLEAN` column.
  ColumnDefinition boolean(String name) {
    return _addColumn(name, 'BOOLEAN');
  }

  /// Adds a `DATE` column.
  ColumnDefinition date(String name) {
    return _addColumn(name, 'DATE');
  }

  /// Adds a `TIMESTAMP` column.
  ColumnDefinition timestamp(String name) {
    return _addColumn(name, 'TIMESTAMP');
  }

  /// Adds a `TIMESTAMPTZ` (timestamp with timezone) column.
  ColumnDefinition timestampTz(String name) {
    return _addColumn(name, 'TIMESTAMPTZ');
  }

  /// Adds a `TIME` column.
  ColumnDefinition time(String name) {
    return _addColumn(name, 'TIME');
  }

  /// Adds a `JSONB` column.
  ColumnDefinition jsonb(String name) {
    return _addColumn(name, 'JSONB');
  }

  /// Adds a `JSON` column.
  ColumnDefinition json(String name) {
    return _addColumn(name, 'JSON');
  }

  /// Adds a `BYTEA` (binary data) column.
  ColumnDefinition binary(String name) {
    return _addColumn(name, 'BYTEA');
  }

  /// Adds an enum-like column using a CHECK constraint.
  ColumnDefinition enum_(String name, List<String> values) {
    final check = values.map((v) => "'$v'").join(', ');
    final col = _addColumn(name, 'VARCHAR(255)');
    _constraints.add('CHECK ("${Schema._sanitize(name)}" IN ($check))');
    return col;
  }

  // ─── Shorthand Columns ───────────────────────────────────────────

  /// Adds `created_at` and `updated_at` timestamp columns.
  void timestamps() {
    timestamp('created_at').defaultsTo('CURRENT_TIMESTAMP');
    timestamp('updated_at').defaultsTo('CURRENT_TIMESTAMP');
  }

  /// Adds a soft-delete `deleted_at` column.
  ColumnDefinition softDeletes() {
    return timestamp('deleted_at').nullable();
  }

  /// Adds a foreign key column referencing another table.
  /// 
  /// ```dart
  /// table.foreign('user_id', references: 'id', on: 'users');
  /// ```
  ColumnDefinition foreign(String column, {
    required String references,
    required String on,
    String onDelete = 'CASCADE',
    String onUpdate = 'CASCADE',
  }) {
    final col = integer(column);
    _constraints.add(
      'FOREIGN KEY ("${Schema._sanitize(column)}") '
      'REFERENCES "${Schema._sanitize(on)}" ("${Schema._sanitize(references)}") '
      'ON DELETE $onDelete ON UPDATE $onUpdate'
    );
    return col;
  }

  // ─── Table Constraints ───────────────────────────────────────────

  /// Adds a composite unique constraint.
  void unique(List<String> columns) {
    final cols = columns.map((c) => '"${Schema._sanitize(c)}"').join(', ');
    _constraints.add('UNIQUE ($cols)');
  }

  /// Adds a named index (executed as a separate statement after CREATE TABLE).
  /// Note: This generates a separate SQL statement, stored for later execution.
  String index(String name, List<String> columns) {
    final cols = columns.map((c) => '"${Schema._sanitize(c)}"').join(', ');
    return 'CREATE INDEX "${Schema._sanitize(name)}" ON "${Schema._sanitize(_table)}" ($cols)';
  }

  // ─── Internal ────────────────────────────────────────────────────

  ColumnDefinition _addColumn(String name, String type, {bool isPrimaryKey = false}) {
    final col = ColumnDefinition._(name, type, isPrimaryKey: isPrimaryKey);
    _columns.add(col);
    return col;
  }

  String _toCreateSql() {
    final parts = <String>[
      ..._columns.map((c) => c._toSql()),
      ..._constraints,
    ];
    return 'CREATE TABLE "${Schema._sanitize(_table)}" (${parts.join(', ')})';
  }
}

/// Defines a single column in a [Blueprint].
/// 
/// Supports chaining modifiers like [nullable], [unique], [defaultsTo], and [references].
class ColumnDefinition {
  ColumnDefinition._(this._name, this._type, {bool isPrimaryKey = false})
      : _isPrimaryKey = isPrimaryKey;

  final String _name;
  final String _type;
  final bool _isPrimaryKey;
  bool _nullable = false;
  bool _unique = false;
  String? _default;
  String? _check;

  /// Marks this column as nullable.
  ColumnDefinition nullable() {
    _nullable = true;
    return this;
  }

  /// Sets a default value expression (raw SQL).
  ColumnDefinition defaultsTo(String expression) {
    _default = expression;
    return this;
  }

  /// Adds a UNIQUE constraint to this column.
  ColumnDefinition unique() {
    _unique = true;
    return this;
  }

  /// Adds a CHECK constraint expression.
  ColumnDefinition check(String expression) {
    _check = expression;
    return this;
  }

  String _toSql() {
    final sb = StringBuffer('"${Schema._sanitize(_name)}" $_type');

    if (_isPrimaryKey) {
      sb.write(' PRIMARY KEY');
    }

    if (!_nullable && !_isPrimaryKey) {
      sb.write(' NOT NULL');
    }

    if (_default != null) {
      sb.write(' DEFAULT $_default');
    }

    if (_unique) {
      sb.write(' UNIQUE');
    }

    if (_check != null) {
      sb.write(' CHECK ($_check)');
    }

    return sb.toString();
  }
}
