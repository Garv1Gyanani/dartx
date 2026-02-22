import 'dart:async';
import 'package:kronix/kronix.dart';

/// --------------------------------------------------------------------------
/// 1. MODELS
/// --------------------------------------------------------------------------

class Task extends Model {
  String? title;
  bool completed = false;

  Task({this.title, this.completed = false});

  @override
  String get table => 'tasks';

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'completed': completed,
  };

  @override
  void fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    completed = json['completed'] ?? false;
  }
}

/// --------------------------------------------------------------------------
/// 2. VALIDATION (Form Requests)
/// --------------------------------------------------------------------------

class CreateTaskRequest extends FormRequest {
  @override
  Map<String, String> rules() => {
    'title': 'required|string|min:3',
    'completed': 'boolean',
  };
}

/// --------------------------------------------------------------------------
/// 3. CONTROLLERS
/// --------------------------------------------------------------------------

class TaskController {
  // In a real app, you'd resolve a repository from the DI container
  final List<Task> _mockDb = [
    Task(title: 'Learn Kronix')..id = 1,
    Task(title: 'Build an API')..id = 2,
  ];

  Future<Response> index(Context ctx) async {
    return ctx.json(_mockDb);
  }

  Future<Response> store(Context ctx) async {
    // This will automatically throw 422 if validation fails
    final data = ctx.validate(CreateTaskRequest());
    
    final task = Task(
      title: data['title'],
      completed: data['completed'] ?? false,
    )..id = _mockDb.length + 1;

    _mockDb.add(task);
    
    return ctx.json(task, status: 201);
  }

  Future<Response> show(Context ctx) async {
    final id = int.tryParse(ctx.params['id'] ?? '');
    final task = _mockDb.firstWhere((t) => t.id == id, orElse: () => throw NotFoundException());
    
    return ctx.json(task);
  }
}

/// --------------------------------------------------------------------------
/// 4. MAIN APPLICATION
/// --------------------------------------------------------------------------

void main() async {
  final app = App();
  final taskController = TaskController();

  // Global Middleware
  app.use(loggerMiddleware);

  // Grouped Routes
  app.group('/api/v1', callback: (router) {
    
    router.get('/tasks', taskController.index);
    router.post('/tasks', taskController.store);
    router.get('/tasks/:id', taskController.show);

  });

  // Simple Redirect Example
  app.get('/', (ctx) async => ctx.redirect('/api/v1/tasks'));

  print('🚀 Task API running on http://localhost:3000');
  await app.listen(port: 3000);
}

/// --------------------------------------------------------------------------
/// 5. MIDDLEWARE
/// --------------------------------------------------------------------------

Future<Response> loggerMiddleware(Context ctx, Next next) async {
  final start = DateTime.now();
  final response = await next();
  final duration = DateTime.now().difference(start);
  
  print('[${ctx.requestId}] ${ctx.request.method} ${ctx.request.path} -> ${response.statusCode} (${duration.inMilliseconds}ms)');
  
  return response;
}
