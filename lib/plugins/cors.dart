import '../core/context.dart';
import '../core/middleware.dart';
import '../http/response.dart';

class Cors {
  final String origin;
  final String methods;
  final String headers;

   Cors({
    this.origin = '*',
    this.methods = 'GET, POST, PUT, DELETE, PATCH, OPTIONS',
    this.headers = 'Origin, Content-Type, Accept, Authorization',
  });

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
