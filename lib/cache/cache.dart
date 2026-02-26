import 'dart:async';
import 'driver.dart';
import 'memory_driver.dart';

/// The global Cache manager.
/// 
/// ```dart
/// await Cache.put('key', 'value', ttl: Duration(minutes: 5));
/// final val = await Cache.get('key');
/// ```
class Cache {
  static CacheDriver _driver = MemoryCacheDriver();

  /// Sets the global cache driver.
  static void use(CacheDriver driver) {
    _driver = driver;
  }

  /// Retrieves an item from the cache.
  static Future<T?> get<T>(String key) async {
    final value = await _driver.get(key);
    if (value == null) return null;
    return value as T;
  }

  /// Stores an item in the cache.
  static Future<void> put(String key, dynamic value, {Duration? ttl}) async {
    await _driver.put(key, value, ttl: ttl);
  }

  /// Retrieves an item, or stores the result of the callback if it doesn't exist.
  static Future<T> remember<T>(String key, Duration ttl, FutureOr<T> Function() callback) async {
    final value = await get<T>(key);
    if (value != null) return value;

    final result = await callback();
    await put(key, result, ttl: ttl);
    return result;
  }

  /// Increments the value of an item.
  static Future<int> increment(String key, [int value = 1]) async {
    return await _driver.increment(key, value);
  }

  /// Decrements the value of an item.
  static Future<int> decrement(String key, [int value = 1]) async {
    return await _driver.decrement(key, value);
  }

  /// Removes an item.
  static Future<void> forget(String key) async {
    await _driver.forget(key);
  }

  /// Clears the entire cache.
  static Future<void> flush() async {
    await _driver.flush();
  }

  /// Checks if an item exists.
  static Future<bool> has(String key) async {
    return await _driver.has(key);
  }
}
