import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'context.dart';

/// A wrapper around native [WebSocket] providing helper methods, room support, and metadata.
/// 
/// The [WebSocketConnection] is used within the Kronix framework to manage
/// individual real-time connections, allowing for automatic JSON encoding,
/// room management, and access to the original request [Context].
class WebSocketConnection {
  /// Creates a new connection wrapper for the given [socket] and [context].
  WebSocketConnection(this.socket, this.context);

  /// The underlying native Dart [WebSocket] instance.
  final WebSocket socket;
  
  /// The [Context] associated with the initial HTTP upgrade request.
  final Context context;
  
  final Set<String> _rooms = {};

  /// A unique identifier for this connection, identical to the initial [Context.requestId].
  String get id => context.requestId;

  /// Joins a specific [room].
  /// 
  /// Rooms allow for targeted broadcasting using [WebSocketHub.toRoom].
  void join(String room) => _rooms.add(room);

  /// Leaves a specific [room].
  void leave(String room) => _rooms.remove(room);

  /// Returns `true` if this connection is currently in the specified [room].
  bool isInRoom(String room) => _rooms.contains(room);

  /// Sends a [message] to the client.
  /// 
  /// If the [message] is a [Map] or [List], it is automatically encoded to a JSON string.
  /// Otherwise, it is sent as-is.
  void send(dynamic message) {
    if (message is Map || message is List) {
      socket.add(jsonEncode(message));
    } else {
      socket.add(message);
    }
  }

  /// Sets up a listener for data events from this connection.
  /// 
  /// This wraps the underlying [WebSocket.listen] and returns a [StreamSubscription].
  StreamSubscription listen(void Function(dynamic data)? onData, {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return socket.listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  /// Closes the connection with an optional [code] and [reason].
  Future<void> close([int? code, String? reason]) => socket.close(code, reason);
}

/// The global registry and manager for all active [WebSocketConnection]s.
/// 
/// Use the [WebSocketHub] to broadcast messages to all users, specific rooms,
/// or individual clients.
class WebSocketHub {
  /// Internal constructor for [WebSocketHub].
  WebSocketHub();

  final Map<String, WebSocketConnection> _connections = {};

  /// Returns an iterable of all currently active [WebSocketConnection]s.
  Iterable<WebSocketConnection> get connections => _connections.values;

  /// Registers a new [connection] into the hub.
  void register(WebSocketConnection connection) {
    _connections[connection.id] = connection;
    connection.socket.done.then((_) => _connections.remove(connection.id));
  }

  /// Broadcasts a [message] to all active connections.
  /// 
  /// Maps and Lists are automatically JSON encoded.
  void broadcast(dynamic message) {
    for (final conn in _connections.values) {
      conn.send(message);
    }
  }

  /// Broadcasts a [message] to all connections currently in the specified [room].
  void toRoom(String room, dynamic message) {
    for (final conn in _connections.values) {
      if (conn.isInRoom(room)) {
        conn.send(message);
      }
    }
  }

  /// Sends a [message] directly to a specific client by their [clientId].
  void emit(String clientId, dynamic message) {
    _connections[clientId]?.send(message);
  }

  /// Retrieves a [WebSocketConnection] by its unique [id].
  WebSocketConnection? get(String id) => _connections[id];
}
