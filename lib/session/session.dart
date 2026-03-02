import 'dart:math';
import 'package:crypto/crypto.dart';

/// Represents a user session.
class Session {
  /// Creates a new [Session] with an [id] and optional initial [data].
  Session(this.id, [Map<String, dynamic>? data]) : _data = data ?? <String, dynamic>{};

  /// The unique session identifier.
  final String id;
  
  final Map<String, dynamic> _data;
  bool _isDirty = false;

  /// Whether the session data has been modified.
  bool get isDirty => _isDirty;

  /// Returns the internal data map.
  Map<String, dynamic> get data => _data;

  /// Generates a new unique session ID.
  static String generateId() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return sha256.convert(values).toString();
  }

  /// Gets a value from the session.
  T? get<T>(String key) => _data[key] as T?;

  /// Sets a value in the session.
  void put(String key, dynamic value) {
    _data[key] = value;
    _isDirty = true;
  }

  /// Removes a value from the session.
  void forget(String key) {
    _data.remove(key);
    _isDirty = true;
  }

  /// Clears the entire session.
  void flush() {
    _data.clear();
    _isDirty = true;
  }
}
