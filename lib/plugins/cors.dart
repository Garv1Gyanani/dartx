import '../core/context.dart';
import '../core/middleware.dart';
import '../http/response.dart';

/// Middleware for handling Cross-Origin Resource Sharing (CORS).
class Cors {
  /// Creates a new [Cors] instance with the specified configuration.
  Cors({
    this.origin = '*',
    this.methods = 'GET, POST, PUT, DELETE, PATCH, OPTIONS',
    this.headers = 'Origin, Content-Type, Accept, Authorization',
  });

  /// The allowed origin. Defaults to `*`.
  final String origin;
  
  /// The allowed HTTP methods.
  final String methods;

  /// The allowed HTTP headers.
  final String headers;

  /// Returns a [Middleware] that injects CORS headers into the response.
  Middleware handle() {
    return (Context ctx, Next next) async {
      final corsHeaders = {
        'Access-Control-Allow-Origin': origin,
        'Access-Control-Allow-Methods': methods,
        'Access-Control-Allow-Headers': headers,
      };

      if (ctx.request.method == 'OPTIONS') {
        return Response(
          statusCode: 204,
          headers: corsHeaders,
        );
      }

      final response = await next();
      // Create a new Response with merged headers instead of mutating
      return Response(
        statusCode: response.statusCode,
        body: response.body,
        headers: {...response.headers, ...corsHeaders},
      );
    };
  }
}
