import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import '../core/context.dart';
import '../core/middleware.dart';
import '../http/response.dart';

/// Helper class for JSON Web Token (JWT) authentication and authorization.
class Auth {
  /// The secret key used for signing and verifying tokens.
  final String secret;

  /// The duration for which a generated token remains valid.
  final Duration tokenTtl;

  /// Creates a new [Auth] instance with the specified [secret] and [tokenTtl].
  Auth(this.secret, {this.tokenTtl = const Duration(hours: 1)});

  /// Generates a new signed JWT string containing the provided [payload].
  String generateToken(Map<String, dynamic> payload) {
    final jwt = JWT(payload);
    return jwt.sign(SecretKey(secret), expiresIn: tokenTtl);
  }

  /// Returns a [Middleware] that verifies the `Authorization: Bearer <token>` header.
  /// 
  /// On success, the JWT payload is stored in `ctx.request.attributes['auth']`.
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
