import '../http/request.dart';
import '../http/response.dart';
import '../di/container.dart';
import 'validator.dart';
import 'exceptions.dart';

class AbortException implements Exception {
  final Response response;
  AbortException(this.response);
}

class Context {
  final Request request;
  final Container container;
  final Stopwatch _stopwatch = Stopwatch()..start();
  Response? _response;

  Context(this.request, {required this.container});

  T resolve<T>() => container.resolve<T>();

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

  Map<String, dynamic> get params => request.params;
  Map<String, dynamic> get query => request.query;
  Map<String, dynamic> get body => request.body;
}
