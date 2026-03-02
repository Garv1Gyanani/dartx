import 'server.dart';
import 'router.dart';

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
          <td class="method-col"><span class="method-badge ${r['method']}">${r['method']}</span></td>
          <td class="path-col"><code>${r['path']}</code></td>
          <td class="name-col">${r['name'] ?? '<span class="none-text">none</span>'}</td>
          <td class="summary-col">${r['summary'] ?? '-'}</td>
        </tr>
      ''').join();

      final html = '''
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Kronix | API Explorer</title>
          <style>
            :root {
              --bg: #030712;
              --card-bg: #111827;
              --border: #1f2937;
              --text: #f9fafb;
              --text-muted: #9ca3af;
              --primary: #22c55e;
              --secondary: #3b82f6;
              --accent-bg: rgba(34, 197, 94, 0.1);
            }
            * { box-sizing: border-box; }
            body { 
              font-family: 'Inter', -apple-system, sans-serif; 
              background: var(--bg); 
              color: var(--text); 
              margin: 0; 
              padding: 60px 20px;
              line-height: 1.6;
            }
            .container { max-width: 1000px; margin: 0 auto; }
            h1 { font-size: 32px; font-weight: 800; letter-spacing: -0.025em; margin-bottom: 40px; display: flex; align-items: center; gap: 12px; }
            h1::before { content: ''; width: 24px; height: 24px; background: var(--primary); border-radius: 4px; display: inline-block; }
            
            table { 
              width: 100%; border-collapse: collapse; background: var(--card-bg); 
              border-radius: 12px; overflow: hidden; border: 1px solid var(--border); 
              box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
            }
            th { 
              text-align: left; padding: 16px 20px; font-size: 13px; font-weight: 600; 
              color: var(--text-muted); text-transform: uppercase; border-bottom: 1px solid var(--border); 
            }
            td { padding: 16px 20px; border-bottom: 1px solid var(--border); font-size: 15px; }
            
            code { 
              font-family: 'JetBrains Mono', 'Fira Code', monospace; 
              background: #1f2937; padding: 4px 8px; border-radius: 6px; 
              font-size: 14px; color: var(--text); 
            }
            
            .method-badge { 
              font-weight: 700; font-size: 12px; padding: 4px 10px; 
              border-radius: 100px; display: inline-block; letter-spacing: 0.05em;
            }
            .GET { background: rgba(34, 197, 94, 0.2); color: #4ade80; }
            .POST { background: rgba(59, 130, 246, 0.2); color: #60a5fa; }
            .PUT { background: rgba(245, 158, 11, 0.2); color: #fbbf24; }
            .DELETE { background: rgba(239, 68, 68, 0.2); color: #f87171; }
            
            .none-text { font-style: italic; color: var(--text-muted); opacity: 0.5; }
            .summary-col { color: var(--text-muted); }
            
            @media (max-width: 768px) {
              .name-col, .summary-col { display: none; }
              body { padding: 30px 15px; }
            }
          </style>
        </head>
        <body>
          <div class="container">
            <h1>Kronix Framework Explorer</h1>
            <table>
              <thead>
                <tr>
                  <th>Method</th>
                  <th>Endpoint Path</th>
                  <th>Route Name</th>
                  <th>Summary</th>
                </tr>
              </thead>
              <tbody>
                $rows
              </tbody>
            </table>
          </div>
        </body>
        </html>
      ''';

      return ctx.html(html);
    };
  }
}
