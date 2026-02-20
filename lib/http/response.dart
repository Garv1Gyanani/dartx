import 'dart:io';
import 'dart:convert';

class Response {
  final int statusCode;
  final dynamic body;
  final Map<String, String> headers;

  Response({
    this.statusCode = 200,
    this.body,
    this.headers = const {'Content-Type': 'text/plain'},
  });

  Response.json(dynamic data, {int status = 200})
      : statusCode = status,
        body = jsonEncode(data),
        headers = {'Content-Type': 'application/json'};

  Response.html(String html, {int status = 200})
      : statusCode = status,
        body = html,
        headers = {'Content-Type': 'text/html'};

  Response.ok(this.body)
      : statusCode = 200,
        headers = {'Content-Type': 'text/plain'};
}
