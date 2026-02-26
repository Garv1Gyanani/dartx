import 'dart:async';

/// Abstract interface for session storage.
abstract class SessionStore {
  /// Retrieves session data by ID.
  Future<Map<String, dynamic>?> get(String id);

  /// Saves session data.
  Future<void> put(String id, Map<String, dynamic> data, {Duration? ttl});

  /// Deletes a session.
  Future<void> forget(String id);
}

/// In-memory implementation of SessionStore.
class MemorySessionStore implements SessionStore {
  final Map<String, _SessionEntry> _sessions = {};

  @override
  Future<Map<String, dynamic>?> get(String id) async {
    final entry = _sessions[id];
    if (entry == null) return null;
    if (DateTime.now().isAfter(entry.expiresAt)) {
      _sessions.remove(id);
      return null;
    }
    return entry.data;
  }

  @override
  Future<void> put(String id, Map<String, dynamic> data, {Duration? ttl}) async {
    final expiration = ttl ?? Duration(hours: 2);
    _sessions[id] = _SessionEntry(
      Map<String, dynamic>.from(data),
      DateTime.now().add(expiration),
    );
  }

  @override
  Future<void> forget(String id) async {
    _sessions.remove(id);
  }
}

class _SessionEntry {
  final Map<String, dynamic> data;
  final DateTime expiresAt;
  _SessionEntry(this.data, this.expiresAt);
}
