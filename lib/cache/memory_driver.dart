import 'dart:async';
import 'driver.dart';

class _CacheEntry {
  final dynamic value;
  final DateTime? expiresAt;

  _CacheEntry(this.value, this.expiresAt);

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
}

/// A simple, in-memory cache driver.
/// 
/// Note: Items are only cleared when accessed or on [flush].
class MemoryCacheDriver implements CacheDriver {
  final Map<String, _CacheEntry> _storage = {};

  @override
  Future<dynamic> get(String key) async {
    final entry = _storage[key];
    if (entry == null) return null;
    
    if (entry.isExpired) {
      _storage.remove(key);
      return null;
    }
    
    return entry.value;
  }

  @override
  Future<void> put(String key, dynamic value, {Duration? ttl}) async {
    final expiresAt = ttl != null ? DateTime.now().add(ttl) : null;
    _storage[key] = _CacheEntry(value, expiresAt);
  }

  @override
  Future<int> increment(String key, [int value = 1]) async {
    final current = await get(key) ?? 0;
    final newValue = (current is int ? current : 0) + value;
    await put(key, newValue);
    return newValue;
  }

  @override
  Future<int> decrement(String key, [int value = 1]) async {
    return increment(key, -value);
  }

  @override
  Future<void> forget(String key) async {
    _storage.remove(key);
  }

  @override
  Future<void> flush() async {
    _storage.clear();
  }

  @override
  Future<bool> has(String key) async {
    return (await get(key)) != null;
  }
}
