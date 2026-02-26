import 'dart:convert';
import 'package:redis/redis.dart';
import 'driver.dart';

/// A Redis-backed cache driver.
class RedisCacheDriver implements CacheDriver {
  final String host;
  final int port;
  final String? password;
  
  Command? _command;
  late final RedisConnection _conn;

  RedisCacheDriver({
    this.host = 'localhost',
    this.port = 6379,
    this.password,
  });

  Future<Command> _getCommand() async {
    if (_command != null) return _command!;
    
    _conn = RedisConnection();
    _command = await _conn.connect(host, port);
    
    if (password != null) {
      await _command!.send_object(['AUTH', password]);
    }
    
    return _command!;
  }

  @override
  Future<dynamic> get(String key) async {
    final cmd = await _getCommand();
    final value = await cmd.get(key);
    if (value == null) return null;
    
    try {
      return jsonDecode(value as String);
    } catch (_) {
      return value;
    }
  }

  @override
  Future<void> put(String key, dynamic value, {Duration? ttl}) async {
    final cmd = await _getCommand();
    final encoded = jsonEncode(value);
    
    if (ttl != null) {
      await cmd.send_object(['SETEX', key, ttl.inSeconds, encoded]);
    } else {
      await cmd.set(key, encoded);
    }
  }

  @override
  Future<int> increment(String key, [int value = 1]) async {
    final cmd = await _getCommand();
    if (value == 1) {
      return await cmd.send_object(['INCR', key]);
    }
    return await cmd.send_object(['INCRBY', key, value]);
  }

  @override
  Future<int> decrement(String key, [int value = 1]) async {
    final cmd = await _getCommand();
    if (value == 1) {
      return await cmd.send_object(['DECR', key]);
    }
    return await cmd.send_object(['DECRBY', key, value]);
  }

  @override
  Future<void> forget(String key) async {
    final cmd = await _getCommand();
    await cmd.send_object(['DEL', key]);
  }

  @override
  Future<void> flush() async {
    final cmd = await _getCommand();
    await cmd.send_object(['FLUSHDB']);
  }

  @override
  Future<bool> has(String key) async {
    final cmd = await _getCommand();
    final result = await cmd.send_object(['EXISTS', key]);
    return result == 1;
  }

  Future<void> close() async {
    if (_command != null) {
      // redis package doesn't have a direct close, but the Conn object does.
    }
  }
}
