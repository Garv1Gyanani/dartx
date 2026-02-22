import 'dart:io';
import 'file.dart';

/// Represents an incoming HTTP request within the Kronix framework.
/// 
/// This class wraps the native [HttpRequest] and provides parsed access to
/// path parameters, query strings, decoded request bodies, and uploaded files.
class Request {
  /// The underlying native Dart HTTP request.
  final HttpRequest rawRequest;

  /// Path parameters extracted by the router (e.g., /users/:id).
  final Map<String, dynamic> params;

  /// Query string parameters (e.g., ?page=1).
  final Map<String, dynamic> query;

  /// The decoded request body, typically from JSON or Form-UrlEncoded data.
  final Map<String, dynamic> body;

  /// Uploaded files from multipart/form-data requests.
  final Map<String, UploadedFile> files;

  /// Extra storage for middleware to attach data without polluting body.
  final Map<String, dynamic> attributes;

  Request({
    required this.rawRequest,
    Map<String, dynamic>? params,
    Map<String, dynamic>? query,
    Map<String, dynamic>? body,
    Map<String, UploadedFile>? files,
  })  : params = params ?? {},
        query = query ?? {},
        body = body ?? {},
        files = files ?? {},
        attributes = {};

  String get method => rawRequest.method;
  Uri get uri => rawRequest.uri;
  HttpHeaders get headers => rawRequest.headers;

  /// Convenience getter for the client's IP address.
  String get ip =>
      rawRequest.connectionInfo?.remoteAddress.address ?? 'unknown';
}
