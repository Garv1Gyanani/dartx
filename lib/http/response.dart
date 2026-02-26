import 'dart:convert';
import 'dart:collection';

/// Represents an outgoing HTTP response from the Kronix framework.
class Response {
  /// The HTTP status code of the response (e.g., 200, 404, 500).
  final int statusCode;

  /// The payload of the response, usually a String or null.
  final dynamic body;

  /// The HTTP headers to be sent with the response.
  final Map<String, String> headers;

  /// The cookies to be set with the response.
  final List<String> _cookies;

  /// Constructs a new [Response] with an optional body and headers.
  Response({
    this.statusCode = 200,
    this.body,
    Map<String, String>? headers,
    List<String>? cookies,
  })  : headers = _CaseInsensitiveMap(headers ?? {'content-type': 'text/plain'}),
        _cookies = cookies ?? [];

  List<String> get cookies => _cookies;

  /// Creates a JSON response with the provided [data] and status code.
  Response.json(dynamic data, {int status = 200})
      : statusCode = status,
        body = jsonEncode(data),
        headers = _CaseInsensitiveMap({'content-type': 'application/json'}),
        _cookies = [];

  /// Creates an HTML response with the provided [html] string and status code.
  Response.html(String html, {int status = 200})
      : statusCode = status,
        body = html,
        headers = _CaseInsensitiveMap({'content-type': 'text/html'}),
        _cookies = [];

  Response.ok(this.body)
      : statusCode = 200,
        headers = _CaseInsensitiveMap({'content-type': 'text/plain'}),
        _cookies = [];

  Response.redirect(String url, {int status = 302})
      : statusCode = status,
        body = null,
        headers = _CaseInsensitiveMap({'location': url}),
        _cookies = [];

  /// Creates a copy of this response with additional/replaced headers.
  Response withHeaders(Map<String, String> additionalHeaders) {
    return Response(
      statusCode: statusCode,
      body: body,
      headers: {...headers, ...additionalHeaders},
      cookies: _cookies,
    );
  }

  /// Adds a cookie to the response.
  Response withCookie(String cookie) {
    return Response(
      statusCode: statusCode,
      body: body,
      headers: headers,
      cookies: [..._cookies, cookie],
    );
  }
}

class _CaseInsensitiveMap with MapMixin<String, String> {
  final Map<String, String> _inner = {};

  _CaseInsensitiveMap([Map<String, String>? initial]) {
    if (initial != null) {
      initial.forEach((key, value) => _inner[key.toLowerCase()] = value);
    }
  }

  @override String? operator [](Object? key) => _inner[key.toString().toLowerCase()];
  @override void operator []=(String key, String value) => _inner[key.toLowerCase()] = value;
  @override void clear() => _inner.clear();
  @override Iterable<String> get keys => _inner.keys;
  @override String? remove(Object? key) => _inner.remove(key.toString().toLowerCase());
}
