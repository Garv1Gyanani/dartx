import '../core/context.dart';
import '../core/middleware.dart';
import '../http/response.dart';

class Cors {
  final String origin;
  final String methods;
  final String headers;

   Cors({
    this.origin = '*',
    this.methods = 'GET, POST, PUT, DELETE, OPTIONS',
    this.headers = 'Origin, Content-Type, Accept, Authorization',
  });

  Middleware handle() {
    return (Context ctx, Next next) async {
      if (ctx.request.method == 'OPTIONS') {
        return Response(
          statusCode: 204,
          headers: {
            'Access-Control-Allow-Origin': origin,
            'Access-Control-Allow-Methods': methods,
            'Access-Control-Allow-Headers': headers,
          },
        );
      }

      final response = await next();
      response.headers.addAll({
        'Access-Control-Allow-Origin': origin,
        'Access-Control-Allow-Methods': methods,
        'Access-Control-Allow-Headers': headers,
      });
      
      return response;
    };
  }
}
