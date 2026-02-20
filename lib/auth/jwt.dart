import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import '../core/context.dart';
import '../core/middleware.dart';
import '../http/response.dart';

class Auth {
  final String secret;

  Auth(this.secret);

  String generateToken(Map<String, dynamic> payload) {
    final jwt = JWT(payload);
    return jwt.sign(SecretKey(secret));
  }

  Middleware verify() {
    return (Context ctx, Next next) async {
      final authHeader = ctx.request.headers.value('Authorization');
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return Response(statusCode: 401, body: 'Unauthorized');
      }

      final token = authHeader.substring(7);
      try {
        final jwt = JWT.verify(token, SecretKey(secret));
        ctx.request.body['auth'] = jwt.payload;
        return await next();
      } catch (e) {
        return Response(statusCode: 401, body: 'Invalid Token');
      }
    };
  }
}
