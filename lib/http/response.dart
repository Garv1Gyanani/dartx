import 'dart:convert';

/// Represents an outgoing HTTP response from the Kronix framework.
class Response {
  /// The HTTP status code of the response (e.g., 200, 404, 500).
  final int statusCode;

  /// The payload of the response, usually a String or null.
  final dynamic body;

  /// The HTTP headers to be sent with the response.
  final Map<String, String> headers;

  /// Constructs a new [Response] with an optional body and headers.
  Response({
    this.statusCode = 200,
    this.body,
    Map<String, String>? headers,
  }) : headers = headers ?? {'content-type': 'text/plain'};

  /// Creates a JSON response with the provided [data] and status code.
  Response.json(dynamic data, {int status = 200})
      : statusCode = status,
        body = jsonEncode(data),
        headers = {'content-type': 'application/json'};

  /// Creates an HTML response with the provided [html] string and status code.
  Response.html(String html, {int status = 200})
      : statusCode = status,
        body = html,
        headers = {'content-type': 'text/html'};

  Response.ok(this.body)
      : statusCode = 200,
        headers = {'content-type': 'text/plain'};

  Response.redirect(String url, {int status = 302})
      : statusCode = status,
        body = null,
        headers = {'location': url};

  /// Creates a copy of this response with additional/replaced headers.
  Response withHeaders(Map<String, String> additionalHeaders) {
    return Response(
      statusCode: statusCode,
      body: body,
      headers: {...headers, ...additionalHeaders},
    );
  }
}
