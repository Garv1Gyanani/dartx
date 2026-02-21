import 'dart:convert';

class Response {
  final int statusCode;
  final dynamic body;
  final Map<String, String> headers;

  Response({
    this.statusCode = 200,
    this.body,
    Map<String, String>? headers,
  }) : headers = headers ?? {'Content-Type': 'text/plain'};

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

  Response.redirect(String url, {int status = 302})
      : statusCode = status,
        body = null,
        headers = {'Location': url};

  /// Creates a copy of this response with additional/replaced headers.
  Response withHeaders(Map<String, String> additionalHeaders) {
    return Response(
      statusCode: statusCode,
      body: body,
      headers: {...headers, ...additionalHeaders},
    );
  }
}
