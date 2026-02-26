/// Abstract interface for cache storage drivers.
abstract class CacheDriver {
  /// Retrieves an item from the cache.
  Future<dynamic> get(String key);

  /// Stores an item in the cache for a given duration.
  Future<void> put(String key, dynamic value, {Duration? ttl});

  /// Increments the value of an item in the cache.
  Future<int> increment(String key, [int value = 1]);

  /// Decrements the value of an item in the cache.
  Future<int> decrement(String key, [int value = 1]);

  /// Removes an item from the cache.
  Future<void> forget(String key);

  /// Removes all items from the cache.
  Future<void> flush();

  /// Determines if an item exists in the cache.
  Future<bool> has(String key);
}
