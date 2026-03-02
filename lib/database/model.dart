import 'adapter.dart';
import 'query_builder.dart';

/// Base class for database-backed models in Kronix.
/// 
/// Models provide a type-safe bridge between Dart objects and database rows.
/// Every model must define its [tableName] and implement [toMap] for persistence.
/// 
/// ```dart
/// class User extends Model {
///   @override String get tableName => 'users';
///   
///   String name;
///   String email;
///   
///   User({super.id, required this.name, required this.email, super.createdAt, super.updatedAt});
///   
///   factory User.fromRow(Map<String, dynamic> row) => User(
///     id: row['id'],
///     name: row['name'],
///     email: row['email'],
///     createdAt: row['created_at'],
///     updatedAt: row['updated_at'],
///   );
///   
///   @override
///   Map<String, dynamic> toMap() => {'name': name, 'email': email};
/// }
/// ```
abstract class Model {
  /// Creates a new [Model] instance.
  Model({this.id, this.createdAt, this.updatedAt});

  /// The primary key value. Null for unsaved models.
  int? id;

  /// Timestamp of when this record was created.
  DateTime? createdAt;

  /// Timestamp of when this record was last updated.
  DateTime? updatedAt;

  /// The database table name for this model.
  String get tableName;

  /// The primary key column name. Override if not `id`.
  String get primaryKeyColumn => 'id';

  /// Whether to automatically manage `created_at`/`updated_at` columns.
  bool get timestamps => true;

  /// The internal executor used for lazy-loading relationships.
  DatabaseExecutor? _executor;

  /// Holds the raw database attributes for this model.
  Map<String, dynamic>? _rawAttributes;

  /// Sets the database executor and raw attributes for this model instance.
  void setRawData(DatabaseExecutor executor, Map<String, dynamic> raw) {
    _executor = executor;
    _rawAttributes = raw;
  }

  /// Returns the database executor, throwing an error if not set.
  DatabaseExecutor get db {
    final executor = _executor;
    if (executor == null) {
      throw StateError('This model instance is not attached to a database executor. '
          'Relationships can only be loaded on models fetched via ModelQuery.');
    }
    return executor;
  }

  /// Retrieves a raw attribute value by [key].
  dynamic getAttribute(String key) => _rawAttributes?[key];

  // ─── Relationships ──────────────────────────────────────────────

  /// Defines a "Belongs To" relationship.
  Future<T?> belongsTo<T extends Model>(ModelFactory<T> factory, {String? foreignKey, String? ownerKey}) async {
    final relatedModelName = T.toString().toLowerCase();
    final fk = foreignKey ?? '${relatedModelName}_id';
    final targetKey = ownerKey ?? 'id';
    
    final idValue = getAttribute(fk);
    if (idValue == null) return null;

    // Use a fresh QueryBuilder via the attached executor
    final row = await QueryBuilder(_inferTableName<T>(), db)
        .where(targetKey, '=', idValue)
        .first();

    if (row == null) return null;
    final model = factory(row);
    model.setRawData(db, row);
    return model;
  }

  /// Defines a "Has Many" relationship.
  Future<List<T>> hasMany<T extends Model>(ModelFactory<T> factory, {String? foreignKey, String? localKey}) async {
    final fk = foreignKey ?? '${runtimeType.toString().toLowerCase()}_id';
    final targetKey = localKey ?? 'id';
    
    final idValue = getAttribute(targetKey) ?? id;
    if (idValue == null) return [];

    final rows = await QueryBuilder(_inferTableName<T>(), db)
        .where(fk, '=', idValue)
        .get();

    return rows.map((row) {
      final m = factory(row);
      m.setRawData(db, row);
      return m;
    }).toList();
  }

  /// Defines a "Has One" relationship.
  Future<T?> hasOne<T extends Model>(ModelFactory<T> factory, {String? foreignKey, String? localKey}) async {
    final fk = foreignKey ?? '${runtimeType.toString().toLowerCase()}_id';
    final targetKey = localKey ?? 'id';
    
    final idValue = getAttribute(targetKey) ?? id;
    if (idValue == null) return null;

    final row = await QueryBuilder(_inferTableName<T>(), db)
        .where(fk, '=', idValue)
        .first();

    if (row == null) return null;
    final model = factory(row);
    model.setRawData(db, row);
    return model;
  }

  static String _inferTableName<T>() {
    final name = T.toString().toLowerCase();
    return '${name}s';
  }

  /// Converts this model's fields to a database-compatible map.
  /// 
  /// Should NOT include `id`, `created_at`, or `updated_at` — those are
  /// managed automatically.
  Map<String, dynamic> toMap();

  /// Converts this model to a full JSON-compatible map, including metadata.
  Map<String, dynamic> toJson() {
    return {
      primaryKeyColumn: id,
      ...toMap(),
      if (timestamps && createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (timestamps && updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  /// Whether this model has been persisted to the database.
  bool get exists => id != null;

  @override
  String toString() => '$runtimeType(id: $id)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Model &&
          runtimeType == other.runtimeType &&
          id != null &&
          id == other.id;

  @override
  int get hashCode => id?.hashCode ?? super.hashCode;
}

/// A function that constructs a [Model] of type [T] from a database row.
typedef ModelFactory<T extends Model> = T Function(Map<String, dynamic> row);
