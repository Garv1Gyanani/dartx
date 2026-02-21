import 'dart:io';

class Request {
  final HttpRequest rawRequest;
  final Map<String, dynamic> params;
  final Map<String, dynamic> query;
  final Map<String, dynamic> body;

  /// Extra storage for middleware to attach data without polluting body.
  final Map<String, dynamic> attributes;

  Request({
    required this.rawRequest,
    Map<String, dynamic>? params,
    Map<String, dynamic>? query,
    Map<String, dynamic>? body,
  })  : params = params ?? {},
        query = query ?? {},
        body = body ?? {},
        attributes = {};

  String get method => rawRequest.method;
  Uri get uri => rawRequest.uri;
  HttpHeaders get headers => rawRequest.headers;

  /// Convenience getter for the client's IP address.
  String get ip =>
      rawRequest.connectionInfo?.remoteAddress.address ?? 'unknown';
}
