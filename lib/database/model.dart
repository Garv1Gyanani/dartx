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

  Model({this.id, this.createdAt, this.updatedAt});

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
  String toString() => '${runtimeType}(id: $id)';

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
