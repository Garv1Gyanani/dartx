import 'server.dart';
import 'router.dart';
import '../http/response.dart';

/// A utility to generate a document representation of all registered routes.
class RouteExplorer {
  final App app;

  RouteExplorer(this.app);

  /// Generates a List of Maps containing route details.
  List<Map<String, dynamic>> explore() {
    return app.router.allRoutes.map((route) {
      return {
        'method': route.method,
        'path': route.path,
        'name': route.name,
        'summary': route.summary,
        'description': route.description,
        'isWebSocket': route.isWebSocket,
        'metadata': route.metadata,
      };
    }).toList();
  }

  /// Returns a [Handler] that renders the route information as JSON.
  Handler jsonHandler() {
    return (ctx) async {
      return ctx.json({
        'framework': 'Kronix',
        'routes': explore(),
      });
    };
  }

  /// Returns a [Handler] that renders a simple HTML explorer.
  Handler htmlHandler() {
    return (ctx) async {
      final routes = explore();
      final rows = routes.map((r) => '''
        <tr>
          <td style="font-weight: bold; color: ${r['method'] == 'GET' ? '#2ecc71' : '#3498db'}">${r['method']}</td>
          <td><code>${r['path']}</code></td>
          <td>${r['name'] ?? '<span style="color: #95a5a6">none</span>'}</td>
          <td>${r['summary'] ?? '-'}</td>
        </tr>
      ''').join();

      final html = '''
        <!DOCTYPE html>
        <html>
        <head>
          <title>Kronix API Explorer</title>
          <style>
            body { font-family: -apple-system, system-ui, sans-serif; padding: 40px; background: #f9f9f9; }
            table { width: 100%; border-collapse: collapse; background: white; border-radius: 8px; overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
            th, td { padding: 12px 15px; text-align: left; border-bottom: 1px solid #eee; }
            th { background: #34495e; color: white; text-transform: uppercase; font-size: 13px; }
            code { background: #f0f0f0; padding: 2px 4px; border-radius: 4px; }
            h1 { color: #2c3e50; }
          </style>
        </head>
        <body>
          <h1>🚀 Kronix API Explorer</h1>
          <table>
            <thead>
              <tr>
                <th>Method</th>
                <th>Path</th>
                <th>Name</th>
                <th>Summary</th>
              </tr>
            </thead>
            <tbody>
              $rows
            </tbody>
          </table>
        </body>
        </html>
      ''';

      return ctx.html(html);
    };
  }
}
