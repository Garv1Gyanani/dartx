import 'dart:io';
import 'package:dotenv/dotenv.dart';

/// A global configuration manager that loads and provides access to environment variables.
/// 
/// It automatically loads values from a `.env` file if it exists and allows for
/// runtime overrides.
class Config {
  static final DotEnv _env = DotEnv(includePlatformEnvironment: true);
  static bool _isLoaded = false;
  static final Map<String, String> _overrides = {};

  /// Loads the `.env` file from the current working directory.
  /// 
  /// This is called automatically by the framework during [App] initialization.
  static void load() {
    if (_isLoaded) return;
    if (File('.env').existsSync()) {
      _env.load();
    }
    _isLoaded = true;
  }

  /// Retrieves a configuration value by [key].
  /// 
  /// Returns [defaultValue] if the key is not found in either runtime overrides
  /// or the environment.
  static String? get(String key, [String? defaultValue]) {
    load();
    // Runtime overrides take precedence over .env values
    if (_overrides.containsKey(key)) return _overrides[key];
    return _env[key] ?? defaultValue;
  }

  /// Retrieves a configuration value as an integer.
  static int? getInt(String key, [int? defaultValue]) {
    final val = get(key);
    return val != null ? int.tryParse(val) : defaultValue;
  }

  /// Retrieves a configuration value as a boolean.
  static bool getBool(String key, [bool defaultValue = false]) {
    final val = get(key)?.toLowerCase();
    if (val == 'true' || val == '1') return true;
    if (val == 'false' || val == '0') return false;
    return defaultValue;
  }

  /// Sets a runtime override for a configuration [key].
  static void set(String key, dynamic value) {
    _overrides[key] = value.toString();
  }
}
