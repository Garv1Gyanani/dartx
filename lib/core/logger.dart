import 'dart:convert';
import 'dart:io';
import 'context.dart';

/// Defines the severity levels for log messages.
enum LogLevel { debug, info, warn, error }

/// Interface for log destinations (e.g., console, file, external service).
abstract class LogDriver {
  /// Writes a [record] to the destination.
  void write(LogRecord record);
}

/// A [LogDriver] that writes messages to the standard output.
class ConsoleDriver implements LogDriver {
  @override
  void write(LogRecord record) {
    if (Logger.useJson) {
      print(jsonEncode(record.toJson()));
      return;
    }

    final timestamp = record.timestamp.toIso8601String();
    final color = _getColor(record.level);
    final reset = '\x1B[0m';
    final requestId = record.context?['requestId'] ?? 'system';
    
    print('$color[$timestamp] [$requestId] ${record.level.name.toUpperCase()}: ${record.message}${record.data != null ? ' ${record.data}' : ''}$reset');
  }

  String _getColor(LogLevel lvl) {
    if (stdout.hasTerminal && stdout.supportsAnsiEscapes) {
      switch (lvl) {
        case LogLevel.debug: return '\x1B[34m'; // Blue
        case LogLevel.info: return '\x1B[32m'; // Green
        case LogLevel.warn: return '\x1B[33m'; // Yellow
        case LogLevel.error: return '\x1B[31m'; // Red
      }
    }
    return '';
  }
}

/// Represents a single log entry.
class LogRecord {
  /// The severity of the log.
  final LogLevel level;

  /// The log message.
  final String message;

  /// The time the log was created.
  final DateTime timestamp;

  /// Additional metadata associated with the log.
  final Map<String, dynamic>? data;

  /// Contextual data (e.g., Request-ID).
  final Map<String, dynamic>? context;

  /// Creates a new [LogRecord].
  LogRecord({
    required this.level,
    required this.message,
    required this.timestamp,
    this.data,
    this.context,
  });

  /// Converts the record to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'level': level.name.toUpperCase(),
        'message': message,
        if (data != null) 'data': data,
        if (context != null) 'context': context,
      };
}

/// The core logging utility for the Kronix framework.
/// 
/// It supports multiple output [drivers], JSON logging, and contextual 
/// logging with Request-IDs.
class Logger {
  /// The current minimum log level to display.
  static LogLevel level = LogLevel.info;

  /// Whether to output logs in JSON format.
  static bool useJson = false;

  /// The list of active log drivers.
  static List<LogDriver> drivers = [ConsoleDriver()];

  final Map<String, dynamic>? _context;

  /// Creates a new [Logger] with optional [context].
  Logger([this._context]);

  /// Creates a [Logger] instance configured with metadata from the [ctx].
  static Logger withContext(Context ctx) {
    return Logger({'requestId': ctx.requestId});
  }

  /// Logs an [info] message.
  void info(String message, [Map<String, dynamic>? data]) => _log(LogLevel.info, message, data);

  /// Logs a [debug] message.
  void debug(String message, [Map<String, dynamic>? data]) => _log(LogLevel.debug, message, data);

  /// Logs a [warn] message.
  void warn(String message, [Map<String, dynamic>? data]) => _log(LogLevel.warn, message, data);

  /// Logs an [error] message with optional [error] and [stackTrace].
  void error(String message, {Object? error, StackTrace? stackTrace, Map<String, dynamic>? data}) {
    final combinedData = data ?? {};
    if (error != null) combinedData['error'] = error.toString();
    if (stackTrace != null) combinedData['stack'] = stackTrace.toString();
    _log(LogLevel.error, message, combinedData);
  }

  /// Static helper for logging info.
  static void staticInfo(String message, [Map<String, dynamic>? data]) => 
      Logger()._log(LogLevel.info, message, data);

  /// Static helper for logging an error.
  static void staticError(String message, {Object? error, StackTrace? stackTrace, Map<String, dynamic>? data}) => 
      Logger().error(message, error: error, stackTrace: stackTrace, data: data);

  /// Static helper for logging a warning.
  static void staticWarn(String message, [Map<String, dynamic>? data]) => 
      Logger()._log(LogLevel.warn, message, data);

  /// Static helper for logging debug info.
  static void staticDebug(String message, [Map<String, dynamic>? data]) => 
      Logger()._log(LogLevel.debug, message, data);

  void _log(LogLevel lvl, String message, [Map<String, dynamic>? data]) {
    if (lvl.index < level.index) return;

    final record = LogRecord(
      level: lvl,
      message: message,
      timestamp: DateTime.now(),
      data: data,
      context: _context,
    );

    for (var driver in drivers) {
      driver.write(record);
    }
  }
}
