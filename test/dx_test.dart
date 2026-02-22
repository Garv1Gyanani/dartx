import 'package:test/test.dart';
import 'package:kronix/kronix.dart';

void main() {
  group('Developer Experience (DX)', () {
    late App app;

    setUp(() {
      app = App();
      
      app.get('/api/users', (ctx) async {
        return ctx.json({
          'data': [
            {'id': 1, 'name': 'Alice'},
            {'id': 2, 'name': 'Bob'}
          ]
        });
      })
      .setSummary('List users')
      .setDescription('Returns a list of all system users.');

      app.post('/api/login', (ctx) async {
        return ctx.json({'token': 'secret-jwt'});
      })
      .setSummary('User login')
      .setMeta('auth', false);
    });

    test('Fluent Testing API should work correctly', () async {
      final client = app.test();

      // Test GET and JSON path assertion
      await client.get('/api/users')
        .then((res) => res
          .assertStatus(200)
          .assertJsonPath('data.0.id', 1)
          .assertJsonPath('data.1.name', 'Bob'));

      // Test POST
      await client.post('/api/login', body: {'user': 'admin'})
        .then((res) => res
          .assertStatus(200)
          .assertJson({'token': 'secret-jwt'}));

      await client.stop();
    });

    test('Route Explorer should extract documentation', () {
      final explorer = RouteExplorer(app);
      final routes = explorer.explore();

      final userRoute = routes.firstWhere((r) => r['path'] == '/api/users');
      expect(userRoute['summary'], 'List users');
      expect(userRoute['description'], 'Returns a list of all system users.');

      final loginRoute = routes.firstWhere((r) => r['path'] == '/api/login');
      expect(loginRoute['metadata']['auth'], false);
    });

    test('Explorer should render HTML and JSON', () async {
      final explorer = RouteExplorer(app);
      app.get('/docs', explorer.htmlHandler());
      app.get('/docs/json', explorer.jsonHandler());

      final client = app.test();

      await client.get('/docs')
        .then((res) => res
          .assertStatus(200)
          .assertBodyContains('Kronix API Explorer'));

      await client.get('/docs/json')
        .then((res) => res
          .assertStatus(200)
          .assertJsonPath('framework', 'Kronix'));

      await client.stop();
    });
  });
}
