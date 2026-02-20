import 'dart:math';
import '../http/request.dart';
import '../http/response.dart';
import '../di/container.dart';
import 'validator.dart';
import 'exceptions.dart';

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

  Map<String, dynamic> validate(FormRequest request) {
    return validateData(request.rules(), request.messages());
  }

  Map<String, dynamic> validateData(Map<String, String> rules, [Map<String, String>? messages]) {
    final errors = Validator.validate(body, rules, messages);
    
    if (errors.isNotEmpty) {
      throw ValidationException(errors);
    }
    
    return body;
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

  Future<void> dispose() async {
    await container.dispose();
  }
}
