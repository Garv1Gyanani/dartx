import 'dart:collection';
import 'dart:convert';

/// Represents an outgoing HTTP response from the Kronix framework.
class Response {
  /// Constructs a new [Response] with an optional body and headers.
  Response({
    this.statusCode = 200,
    this.body,
    Map<String, String>? headers,
    List<String>? cookies,
  })  : headers = _CaseInsensitiveMap(headers ?? {'content-type': 'text/plain'}),
        _cookies = cookies ?? [];

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

  /// Creates a simple 200 OK response with the given [body].
  Response.ok(this.body)
      : statusCode = 200,
        headers = _CaseInsensitiveMap({'content-type': 'text/plain'}),
        _cookies = [];

  /// Creates a redirect response to the given [url] with an optional status.
  Response.redirect(String url, {int status = 302})
      : statusCode = status,
        body = null,
        headers = _CaseInsensitiveMap({'location': url}),
        _cookies = [];

  /// The HTTP status code of the response (e.g., 200, 404, 500).
  final int statusCode;

  /// The payload of the response, usually a String or null.
  final dynamic body;

  /// The HTTP headers to be sent with the response.
  final Map<String, String> headers;

  /// The cookies to be set with the response.
  final List<String> _cookies;

  /// Returns the cookies to be set with the response.
  List<String> get cookies => _cookies;

  /// Creates a copy of this response with additional/replaced headers.
  Response withHeaders(Map<String, String> additionalHeaders) {
    return Response(
      statusCode: statusCode,
      body: body,
      headers: {...headers, ...additionalHeaders},
      cookies: _cookies,
    );
  }

  /// Adds a cookie to the response and returns a new [Response] instance.
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
  _CaseInsensitiveMap([Map<String, String>? initial]) {
    if (initial != null) {
      initial.forEach((key, value) => _inner[key.toLowerCase()] = value);
    }
  }

  final Map<String, String> _inner = {};

  @override
  String? operator [](Object? key) => _inner[key.toString().toLowerCase()];

  @override
  void operator []=(String key, String value) => _inner[key.toLowerCase()] = value;

  @override
  void clear() => _inner.clear();

  @override
  Iterable<String> get keys => _inner.keys;

  @override
  String? remove(Object? key) => _inner.remove(key.toString().toLowerCase());
}
