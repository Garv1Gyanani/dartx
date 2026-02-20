import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import '../core/context.dart';
import '../core/middleware.dart';
import '../http/response.dart';

class Auth {
  final String secret;
  final Duration tokenTtl;

  Auth(this.secret, {this.tokenTtl = const Duration(hours: 1)});

  String generateToken(Map<String, dynamic> payload) {
    final jwt = JWT(payload);
    return jwt.sign(SecretKey(secret), expiresIn: tokenTtl);
  }

  Middleware verify() {
    return (Context ctx, Next next) async {
      final authHeader = ctx.request.headers.value('Authorization');
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return Response.json({'message': 'Unauthorized'}, status: 401);
      }

      final token = authHeader.substring(7);
      try {
        final jwt = JWT.verify(token, SecretKey(secret));
        // Store auth data in request.attributes, NOT in body
        ctx.request.attributes['auth'] = jwt.payload;
        return await next();
      } on JWTExpiredException {
        return Response.json({'message': 'Token has expired'}, status: 401);
      } catch (e) {
        return Response.json({'message': 'Invalid Token'}, status: 401);
      }
    };
  }
}
