import 'dart:io';

class Request {
  final HttpRequest rawRequest;
  final Map<String, dynamic> params;
  final Map<String, dynamic> query;
  final Map<String, dynamic> body;

  Request({
    required this.rawRequest,
    this.params = const {},
    this.query = const {},
    this.body = const {},
  });

  String get method => rawRequest.method;
  Uri get uri => rawRequest.uri;
  HttpHeaders get headers => rawRequest.headers;
}
