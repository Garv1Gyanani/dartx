/// Base class for all database models in Kronix.
/// 
/// Extend this class to define your entity structure and mapping.
abstract class Model {
  /// The primary key (auto-incrementing integer).
  int? id;
  
  /// The name of the database table associated with this model.
  String get table;

  /// Converts the model instance to a JSON-compatible map.
  Map<String, dynamic> toJson();

  /// Populates the model instance from a JSON-compatible map.
  void fromJson(Map<String, dynamic> json);
}
