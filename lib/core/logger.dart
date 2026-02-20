import 'dart:convert';
import 'dart:io';
import 'context.dart';

enum LogLevel { debug, info, warn, error }

abstract class LogDriver {
  void write(LogRecord record);
}

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

class LogRecord {
  final LogLevel level;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic>? data;
  final Map<String, dynamic>? context;

  LogRecord({
    required this.level,
    required this.message,
    required this.timestamp,
    this.data,
    this.context,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'level': level.name.toUpperCase(),
        'message': message,
        if (data != null) 'data': data,
        if (context != null) 'context': context,
      };
}

class Logger {
  static LogLevel level = LogLevel.info;
  static bool useJson = false;
  static List<LogDriver> drivers = [ConsoleDriver()];

  final Map<String, dynamic>? _context;

  Logger([this._context]);

  static Logger withContext(Context ctx) {
    return Logger({'requestId': ctx.requestId});
  }

  void info(String message, [Map<String, dynamic>? data]) => _log(LogLevel.info, message, data);
  void debug(String message, [Map<String, dynamic>? data]) => _log(LogLevel.debug, message, data);
  void warn(String message, [Map<String, dynamic>? data]) => _log(LogLevel.warn, message, data);
  void error(String message, {Object? error, StackTrace? stackTrace, Map<String, dynamic>? data}) {
    final combinedData = data ?? {};
    if (error != null) combinedData['error'] = error.toString();
    if (stackTrace != null) combinedData['stack'] = stackTrace.toString();
    _log(LogLevel.error, message, combinedData);
  }

  static void staticInfo(String message, [Map<String, dynamic>? data]) => 
      Logger()._log(LogLevel.info, message, data);
  static void staticError(String message, {Object? error, StackTrace? stackTrace, Map<String, dynamic>? data}) => 
      Logger().error(message, error: error, stackTrace: stackTrace, data: data);
  static void staticWarn(String message, [Map<String, dynamic>? data]) => 
      Logger()._log(LogLevel.warn, message, data);
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
