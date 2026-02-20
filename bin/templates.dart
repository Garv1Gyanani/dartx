class Templates {
  static String pubspec(String name) => '''
name: $name
description: A new DartX application.
version: 1.0.0
environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  dartx:
    path: ../ # This assumes the app is created in a subfolder of the framework for now
  dotenv: ^4.2.0

dev_dependencies:
  lints: ^3.0.0
  test: ^1.24.0
''';

  static String main() => '''
import 'package:dartx/dartx.dart';
import '../lib/app.dart';

void main() async {
  final app = App();
  
  // Initialize routes and global middleware
  setupApp(app);

  await app.listen();
}
''';

  static String appBoot() => '''
import 'package:dartx/dartx.dart';
import '../routes/api.dart';

void setupApp(App app) {
  // Global Middleware
  app.use(LoggerMiddleware);

  // Routes
  setupApiRoutes(app);
}

Future<Response> LoggerMiddleware(Context ctx, Next next) async {
  final response = await next();
  return response;
}
''';

  static String apiRoutes() => '''
import 'package:dartx/dartx.dart';
import '../app/controllers/user_controller.dart';

void setupApiRoutes(App app) {
  app.group('/api', callback: (router) {
    router.get('/status', (ctx) async => ctx.json({'status': 'ok'}));
    
    final userController = UserController();
    router.get('/users', userController.index);
  });
}
''';

  static String controller(String name) => '''
import 'package:dartx/dartx.dart';

class ${name}Controller {
  Future<Response> index(Context ctx) async {
    return ctx.json({'message': 'Welcome to ${name}Controller'});
  }
}
''';

  static String service(String name) => '''
class ${name}Service {
  String hello() => 'Hello from ${name}Service';
}
''';

  static String middleware(String name) => '''
import 'package:dartx/dartx.dart';

Future<Response> ${name}Middleware(Context ctx, Next next) async {
  // Logic before
  final response = await next();
  // Logic after
  return response;
}
''';

  static String request(String name) => '''
import 'package:dartx/dartx.dart';

class ${name}Request extends FormRequest {
  @override
  Map<String, String> rules() => {
    'email': 'required|email',
    'password': 'required|min:8',
  };

  @override
  Map<String, String> messages() => {
    'email.required': 'We need your email address!',
  };
}
''';

  static String migration(String name) => '''
import 'package:dartx/dartx.dart';

class $name extends Migration {
  @override
  Future<void> up(DatabaseAdapter db) async {
    await db.query('CREATE TABLE ...');
  }

  Future<void> down(DatabaseAdapter db) async {
    await db.query('DROP TABLE ...');
  }
}
''';

  static String env() => '''
PORT=3000
HOST=0.0.0.0
APP_NAME=DartXApp
''';
}
