import 'dart:io';
import 'package:dotenv/dotenv.dart';

class Config {
  static final DotEnv _env = DotEnv(includePlatformEnvironment: true);
  static bool _isLoaded = false;
  static final Map<String, dynamic> _config = {};

  static void load() {
    if (_isLoaded) return;
    if (File('.env').existsSync()) {
      _env.load();
    }
    _isLoaded = true;
  }

  static String? get(String key, [String? defaultValue]) {
    load();
    // Support dot notation like 'app.name'
    return _env[key] ?? defaultValue;
  }

  static int? getInt(String key, [int? defaultValue]) {
    final val = get(key);
    return val != null ? int.tryParse(val) : defaultValue;
  }

  static bool getBool(String key, [bool defaultValue = false]) {
    final val = get(key)?.toLowerCase();
    if (val == 'true' || val == '1') return true;
    if (val == 'false' || val == '0') return false;
    return defaultValue;
  }

  static void set(String key, dynamic value) {
    _config[key] = value;
  }
}
