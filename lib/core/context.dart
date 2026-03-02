import 'dart:io';
import 'dart:math';

import 'package:mime/mime.dart';

import '../database/adapter.dart';
import '../database/model.dart';
import '../database/model_query.dart';
import '../di/container.dart';
import '../filesystem/storage.dart';
import '../http/request.dart';
import '../http/response.dart';
import '../queue/queue.dart';
import '../session/session.dart';
import 'exceptions.dart';
import 'validator.dart';
import 'websocket.dart';

/// Exception thrown to immediately terminate a request with a specific [response].
class AbortException implements Exception {
  /// Creates a new [AbortException] with the given [response].
  AbortException(this.response);

  /// The response to send.
  final Response response;
}

/// Encapsulates the state of a single HTTP request and its lifecycle.
///
/// The [Context] provides access to the [Request] data, a request-scoped
/// dependency injection [Container], and convenience methods for generating
/// responses. It also tracks the request's execution time.
class Context {
  /// Initializes a new [Context] for the given [request] and [container].
  Context(this.request, {required this.container}) : requestId = _generateRequestId();

  /// The incoming HTTP request data.
  final Request request;

  /// The dependency injection container scoped specifically to this request.
  final Container container;

  /// A unique 8-character identifier for this request, used for log correlation.
  final String requestId;

  final Stopwatch _stopwatch = Stopwatch()..start();
  final Map<String, dynamic> _data = <String, dynamic>{};
  Response? _response;

  /// Returns the total elapsed time since the request was created.
  Duration get elapsed => _stopwatch.elapsed;

  /// Sets a value in the request-scoped data storage.
  void set(String key, dynamic value) => _data[key] = value;

  /// Retrieves a value from the request-scoped data storage.
  T? get<T>(String key) => _data[key] as T?;

  static String _generateRequestId() {
    final rnd = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(8, (_) => chars[rnd.nextInt(chars.length)]).join();
  }

  /// Resolves an instance of type [T] from the request container.
  T resolve<T>({String? name}) => container.resolve<T>(name: name);

  /// Validates the request body against a [FormRequest].
  Future<Map<String, dynamic>> validate(FormRequest request) async {
    return validateData(request.rules(), request.messages());
  }

  /// Validates the request body against the given [rules].
  Future<Map<String, dynamic>> validateData(
    Map<String, String> rules, [
    Map<String, String>? messages,
  ]) async {
    final res = await Validator.validate(body, rules, messages);

    if (res.fails) {
      throw ValidationException(res.errors);
    }

    return res.data;
  }

  /// Immediately terminates the request with the given [res].
  void abort(Response res) {
    throw AbortException(res);
  }

  /// Returns the response object.
  Response get response => _response ?? Response(statusCode: 404);
  set response(Response res) => _response = res;

  /// Generates a JSON response.
  Response json(dynamic data, {int status = 200}) {
    return Response.json(data, status: status);
  }

  /// Generates an HTML response.
  Response html(String content, {int status = 200}) {
    return Response.html(content, status: status);
  }

  /// Generates a plain text response.
  Response text(String content, {int status = 200}) {
    return Response(body: content, statusCode: status);
  }

  /// Generates a redirect response.
  Response redirect(String location, {int status = 302}) {
    return Response.redirect(location, status: status);
  }

  /// Serves a file from the local filesystem.
  ///
  /// Automatically detects the content-type and uses efficient streaming.
  Response file(String path) {
    final f = File(path);
    if (!f.existsSync()) {
      return json(<String, String>{'message': 'File not found'}, status: 404);
    }

    final mimeType = lookupMimeType(path) ?? 'application/octet-stream';
    return Response(
      body: f.openRead(),
      statusCode: 200,
      headers: <String, String>{'content-type': mimeType},
    );
  }

  /// Forces a file download by setting the Content-Disposition header.
  Response download(String path, [String? filename]) {
    final res = file(path);
    if (res.statusCode != 200) return res;

    final name = filename ?? path.split(Platform.pathSeparator).last;
    return res.withHeaders(<String, String>{
      'content-disposition': 'attachment; filename="$name"',
    });
  }

  /// Returns the path parameters of the request.
  Map<String, dynamic> get params => request.params;

  /// Returns the query parameters of the request.
  Map<String, dynamic> get queryParams => request.query;

  /// Returns the body of the request.
  Map<String, dynamic> get body => request.body;

  /// Returns the user session, if SessionMiddleware is active.
  Session get session {
    final s = get<Session>('session');
    if (s == null) {
      throw StateError('Session is not initialized. Ensure SessionMiddleware is registered.');
    }
    return s;
  }

  /// Helper to get a path parameter as an integer.
  int? paramInt(String key, [int? defaultValue]) => request.paramInt(key, defaultValue);

  /// Helper to get a query parameter as an integer.
  int? queryInt(String key, [int? defaultValue]) => request.queryInt(key, defaultValue);

  /// Helper to get a query parameter as a double.
  double? queryDouble(String key, [double? defaultValue]) => request.queryDouble(key, defaultValue);

  /// Helper to get a query parameter as a boolean.
  bool queryBool(String key, [bool defaultValue = false]) => request.queryBool(key, defaultValue);

  /// Retrieves the global [WebSocketHub] from the [Container].
  WebSocketHub get wsHub => resolve<WebSocketHub>();

  /// Retrieves the default [Storage] driver from the [Container].
  Storage get storage => resolve<Storage>();

  /// Retrieves the active [DatabaseExecutor] from the [Container].
  ///
  /// If a transaction middleware is active, this returns the transaction scope.
  /// Otherwise, returns the global [DatabaseAdapter].
  DatabaseExecutor get db {
    try {
      return resolve<DatabaseExecutor>();
    } catch (_) {
      return resolve<DatabaseAdapter>();
    }
  }

  /// Creates a type-safe [ModelQuery] for the given model type [T].
  ///
  /// ```dart
  /// final users = await ctx.query<User>(User.fromRow).where('active', '=', true).get();
  /// final user = await ctx.query<User>(User.fromRow).find(1);
  /// ```
  ModelQuery<T> query<T extends Model>(ModelFactory<T> factory, {String? tableName}) {
    return ModelQuery<T>(db, factory, tableName: tableName);
  }

  /// Retrieves the [Queue] instance from the [Container].
  Queue get queue => resolve<Queue>();

  /// Disposes of the request-scoped [Container] and cleans up temporary files.
  Future<void> dispose() async {
    for (final f in request.files.values) {
      try {
        await f.delete();
      } catch (_) {
        // Best effort cleanup
      }
    }
    await container.dispose();
  }
}
