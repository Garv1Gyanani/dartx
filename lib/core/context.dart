import 'dart:math';
import '../http/request.dart';
import '../http/response.dart';
import '../di/container.dart';
import '../database/adapter.dart';
import '../database/model.dart';
import '../database/model_query.dart';
import 'validator.dart';
import 'exceptions.dart';
import 'websocket.dart';
import '../filesystem/storage.dart';
import '../queue/queue.dart';

class AbortException implements Exception {
  final Response response;
  AbortException(this.response);
}

/// Encapsulates the state of a single HTTP request and its lifecycle.
/// 
/// The [Context] provides access to the [Request] data, a request-scoped
/// dependency injection [Container], and convenience methods for generating
/// responses. It also tracks the request's execution time.
class Context {
  /// The incoming HTTP request data.
  final Request request;
  
  /// The dependency injection container scoped specifically to this request.
  final Container container;
  
  /// A unique 8-character identifier for this request, used for log correlation.
  final String requestId;
  final Stopwatch _stopwatch = Stopwatch()..start();
  Response? _response;

  Context(this.request, {required this.container}) 
    : requestId = _generateRequestId();

  static String _generateRequestId() {
    final rnd = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(8, (_) => chars[rnd.nextInt(chars.length)]).join();
  }

  T resolve<T>({String? name}) => container.resolve<T>(name: name);

  Future<Map<String, dynamic>> validate(FormRequest request) async {
    return await validateData(request.rules(), request.messages());
  }

  Future<Map<String, dynamic>> validateData(Map<String, String> rules, [Map<String, String>? messages]) async {
    final result = await Validator.validate(body, rules, messages);
    
    if (result.fails) {
      throw ValidationException(result.errors);
    }
    
    // Merge coerced data back into request body or return as "cleaned" data
    // Usually, we return the cleaned data so the controller doesn't use unvalidated input
    return result.data;
  }

  void abort(Response res) {
    throw AbortException(res);
  }

  Response get response => _response ?? Response(statusCode: 404);
  set response(Response res) => _response = res;

  Duration get elapsed => _stopwatch.elapsed;

  Response json(dynamic data, {int status = 200}) {
    return Response.json(data, status: status);
  }

  Response html(String html, {int status = 200}) {
    return Response.html(html, status: status);
  }

  Response text(String text, {int status = 200}) {
    return Response(body: text, statusCode: status);
  }

  Response redirect(String url, {int status = 302}) {
    return Response.redirect(url, status: status);
  }

  Map<String, dynamic> get params => request.params;
  Map<String, dynamic> get query => request.query;
  Map<String, dynamic> get body => request.body;

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
    for (var file in request.files.values) {
      try {
        await file.delete();
      } catch (_) {
        // Best effort cleanup
      }
    }
    await container.dispose();
  }
}
