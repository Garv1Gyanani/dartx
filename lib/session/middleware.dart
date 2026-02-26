import 'dart:io';
import '../core/context.dart';
import '../core/middleware.dart';
import '../http/response.dart';
import 'session.dart';
import 'store.dart';

/// Middleware for managing server-side sessions.
class SessionMiddleware {
  final SessionStore store;
  final String cookieName;
  final Duration ttl;

  SessionMiddleware({
    required this.store,
    this.cookieName = 'kronix_session',
    this.ttl = const Duration(hours: 2),
  });

  Middleware handle() {
    return (Context ctx, Next next) async {
      // 1. Try to get session ID from cookie
      final cookies = ctx.request.rawRequest.cookies;
      final sessionCookie = cookies.firstWhere(
        (c) => c.name == cookieName,
        orElse: () => Cookie(cookieName, ''),
      );

      String sessionId = sessionCookie.value;
      Session session;

      // 2. Load existing or create new session
      if (sessionId.isNotEmpty) {
        final data = await store.get(sessionId);
        if (data != null) {
          session = Session(sessionId, data);
        } else {
          sessionId = Session.generateId();
          session = Session(sessionId);
        }
      } else {
        sessionId = Session.generateId();
        session = Session(sessionId);
      }

      // 3. Attach session to context
      ctx.set('session', session);

      // 4. Continue execution
      final response = await next();

      // 5. Persist session if dirty
      if (session.isDirty) {
        await store.put(sessionId, session.data, ttl: ttl);
      }

      // 6. Set/Refresh cookie
      final cookie = Cookie(cookieName, sessionId)
        ..httpOnly = true
        ..path = '/'
        ..maxAge = ttl.inSeconds;
      
      // Since Response is immutable, we use withHeaders but cookies are handled via the raw request?
      // Actually, we should probably add a cookie helper to Response or handle it in the server's _sendResponse.
      // For now, let's use withHeaders to pass the Set-Cookie string.
      return response.withHeaders({
        'set-cookie': cookie.toString(),
      });
    };
  }
}
