import 'package:kronix/kronix.dart';

// --- DI Services ---
class AuthService {
  bool verify(String token) => token == 'secret-token';
}

class RequestCounter {
  int _count = 0;
  void increment() => _count++;
  int get count => _count;
}

// --- Middlewares ---
Future<Response> authMiddleware(Context ctx, Next next) async {
  final token = ctx.request.headers.value('Authorization');
  if (token == null || !token.startsWith('Bearer ')) {
    ctx.abort(ctx.json({'error': 'Unauthorized'}, status: 401));
    return ctx.response;
  }
  
  final authService = di.resolve<AuthService>();
  if (!authService.verify(token.substring(7))) {
    ctx.abort(ctx.json({'error': 'Invalid token'}, status: 403));
    return ctx.response;
  }
  
  return await next();
}

void main() async {
  // 1. Setup DI
  di.singleton(AuthService());
  di.scoped((container) => RequestCounter());

  final app = App();

  // 2. Global Logging Configuration
  Logger.level = LogLevel.debug;
  Config.set('APP_NAME', 'kronix Enterprise Demo');

  // 3. Routing with Groups & Prefixes
  app.group('/api/v1', callback: (router) {
    
    router.add('GET', '/health-check', (ctx) async {
      return ctx.json({
        'status': 'up',
        'app': Config.get('APP_NAME'),
      });
    });

    // Sub-group with middleware
    router.group('/admin', middleware: [authMiddleware], callback: (adminRouter) {
      
      adminRouter.add('GET', '/dashboard/:id', (ctx) async {
        // Resolve scoped service - now truly isolated per request container
        final counter = ctx.resolve<RequestCounter>();
        counter.increment();
        
        final adminId = ctx.params['id'];
        
        return ctx.json({
          'message': 'Welcome to Admin Dashboard',
          'admin_id': adminId,
          'requests_in_this_specific_scope': counter.count,
        });
      }, name: 'admin.dashboard');

    });
  });

  // 4. Named routes example with parameters
  app.get('/routes', (ctx) async {
    final dashboardUrl = di.resolve<Router>().url('admin.dashboard', params: {'id': 'admin-special'});
    return ctx.json({
      'admin_dashboard_path_with_id': dashboardUrl,
      'tip': 'Try visiting that path with header "Authorization: Bearer secret-token"'
    });
  });

  await app.listen(port: 3000);
}
