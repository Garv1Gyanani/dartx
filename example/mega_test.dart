import 'package:dartx/dartx.dart';

// ─── MOCK DATABASE ──────────────────────────────────────────────
class TestDB implements DatabaseAdapter {
  final List<String> sqlLog = [];

  @override
  QueryBuilder table(String name) => QueryBuilder(name, this);

  @override
  Future<QueryResult> query(String sql, [Map<String, dynamic>? params]) async {
    sqlLog.add(sql);
    if (sql.contains('SELECT')) {
      return _MockResult([
        {'id': 1, 'name': 'Garv', 'email': 'garv@dartx.dev'}
      ]);
    }
    return _MockResult([], 1);
  }

  @override
  Future<T> transaction<T>(Future<T> Function(DatabaseExecutor tx) callback) async {
    sqlLog.add('BEGIN');
    final executor = _TxExecutor(sqlLog);
    try {
      final result = await callback(executor);
      sqlLog.add('COMMIT');
      return result;
    } catch (e) {
      sqlLog.add('ROLLBACK');
      rethrow;
    }
  }

  @override
  Future<DatabaseExecutor> beginTransaction() => throw UnimplementedError();
  @override
  Future<void> connect() async {}
  @override
  Future<void> close() async {}
}

class _TxExecutor implements DatabaseExecutor {
  final List<String> log;
  _TxExecutor(this.log);

  @override
  Future<QueryResult> query(String sql, [Map<String, dynamic>? params]) async {
    log.add('[TX] $sql');
    return _MockResult([], 1);
  }
  @override
  Future<void> commit() async {}
  @override
  Future<void> rollback() async {}
}

class _MockResult implements QueryResult {
  @override
  final List<Map<String, dynamic>> rows;
  @override
  final int? affectedRows;
  _MockResult(this.rows, [this.affectedRows]);
}

// ─── SERVICES (DI Test) ─────────────────────────────────────────
class CounterService {
  int count = 0;
  void inc() => count++;
}

class SingletonService {
  final String id;
  SingletonService() : id = DateTime.now().microsecondsSinceEpoch.toString();
}

// ─── FORM REQUESTS (Validation Test) ────────────────────────────
class LoginRequest extends FormRequest {
  @override
  Map<String, String> rules() => {
    'email': 'required|email',
    'password': 'required|min:6',
  };

  @override
  Map<String, String> messages() => {
    'email.required': 'Email is mandatory!',
    'password.min': 'Password too short, need 6+ chars.',
  };
}

class ProductRequest extends FormRequest {
  @override
  Map<String, String> rules() => {
    'name': 'required|min:2|max:50',
    'price': 'required|numeric',
    'active': 'boolean',
  };
}

// ─── MAIN ───────────────────────────────────────────────────────
void main() async {
  final app = App();
  Config.set('APP_ENV', 'development');

  final db = TestDB();
  di.singleton<DatabaseAdapter>(db);
  di.singleton(SingletonService());
  di.scoped((_) => CounterService());

  // ─── GLOBAL MIDDLEWARE ──────────────────────────────────────
  app.use((ctx, next) async {
    // Adds a custom header to every response
    final response = await next();
    return Response(
      statusCode: response.statusCode,
      body: response.body,
      headers: {...response.headers, 'X-Powered-By': 'DartX'},
    );
  });

  // ═══════════════════════════════════════════════════════════
  // TEST GROUP 1: ROUTING
  // ═══════════════════════════════════════════════════════════
  app.get('/ping', (ctx) async => ctx.json({'pong': true}));

  app.get('/text', (ctx) async => ctx.text('Hello DartX'));

  app.get('/html', (ctx) async => ctx.html('<h1>DartX</h1>'));

  app.get('/users/:id', (ctx) async {
    return ctx.json({'userId': ctx.params['id']});
  });

  app.get('/search', (ctx) async {
    return ctx.json({'q': ctx.query['q'], 'page': ctx.query['page']});
  });

  // Nested groups
  app.group('/api', callback: (api) {
    api.group('/v1', callback: (v1) {
      v1.add('GET', '/status', (ctx) async {
        return ctx.json({'api': 'v1', 'status': 'ok'});
      });
    });

    api.group('/v2', callback: (v2) {
      v2.add('GET', '/status', (ctx) async {
        return ctx.json({'api': 'v2', 'status': 'ok'});
      });
    });
  });

  // ═══════════════════════════════════════════════════════════
  // TEST GROUP 2: VALIDATION
  // ═══════════════════════════════════════════════════════════
  app.post('/validate/login', (ctx) async {
    final data = ctx.validate(LoginRequest());
    return ctx.json({'valid': true, 'email': data['email']});
  });

  app.post('/validate/product', (ctx) async {
    final data = ctx.validate(ProductRequest());
    return ctx.json({'valid': true, 'product': data['name']});
  });

  app.post('/validate/inline', (ctx) async {
    final data = ctx.validateData({
      'age': 'required|numeric',
      'name': 'required|min:2',
    });
    return ctx.json({'valid': true, 'data': data});
  });

  // ═══════════════════════════════════════════════════════════
  // TEST GROUP 3: EXCEPTIONS
  // ═══════════════════════════════════════════════════════════
  app.get('/err/401', (ctx) async {
    throw UnauthorizedException('Token expired');
  });

  app.get('/err/403', (ctx) async {
    throw ForbiddenException('Admin only');
  });

  app.get('/err/404', (ctx) async {
    throw NotFoundException('User #99 not found');
  });

  app.get('/err/409', (ctx) async {
    throw ConflictException('Email already taken');
  });

  app.get('/err/500', (ctx) async {
    throw StateError('Null pointer');
  });

  app.get('/err/abort', (ctx) async {
    ctx.abort(ctx.json({'custom': 'abort response'}, status: 418));
    return ctx.text('never reached');
  });

  // ═══════════════════════════════════════════════════════════
  // TEST GROUP 4: DI & SCOPING
  // ═══════════════════════════════════════════════════════════
  app.get('/di/singleton', (ctx) async {
    final s1 = ctx.resolve<SingletonService>();
    final s2 = ctx.resolve<SingletonService>();
    return ctx.json({'same': identical(s1, s2), 'id': s1.id});
  });

  app.get('/di/scoped', (ctx) async {
    final c = ctx.resolve<CounterService>();
    c.inc();
    c.inc();
    c.inc();
    return ctx.json({'count': c.count});
  });

  // ═══════════════════════════════════════════════════════════
  // TEST GROUP 5: DATABASE / QUERY BUILDER
  // ═══════════════════════════════════════════════════════════
  app.get('/db/select', (ctx) async {
    final users = await db.table('users')
        .select(['id', 'name'])
        .where('active', '=', true)
        .orderBy('name')
        .limit(10)
        .get();
    return ctx.json({'users': users, 'sql_log': db.sqlLog.last});
  });

  app.post('/db/insert', (ctx) async {
    await db.table('posts').insert({'title': 'Hello', 'body': 'World'});
    return ctx.json({'inserted': true, 'sql': db.sqlLog.last});
  });

  app.post('/db/transaction', (ctx) async {
    await db.transaction((tx) async {
      await tx.query('INSERT INTO accounts VALUES (1, 1000)');
      await tx.query('UPDATE accounts SET balance = balance - 100 WHERE id = 1');
    });
    return ctx.json({'committed': true, 'log': db.sqlLog});
  });

  // ═══════════════════════════════════════════════════════════
  // TEST GROUP 6: MIDDLEWARE CHAIN
  // ═══════════════════════════════════════════════════════════
  app.get('/guarded', (ctx) async {
    return ctx.json({'access': 'granted'});
  }, middleware: [
    (ctx, next) async {
      final token = ctx.query['token'];
      if (token != 'secret') throw UnauthorizedException('Bad token');
      return await next();
    }
  ]);

  // ═══════════════════════════════════════════════════════════
  // TEST GROUP 7: CONFIG
  // ═══════════════════════════════════════════════════════════
  app.get('/config', (ctx) async {
    Config.set('CUSTOM_KEY', 'hello_dartx');
    return ctx.json({
      'env': Config.get('APP_ENV'),
      'custom': Config.get('CUSTOM_KEY'),
      'missing_with_default': Config.get('NOPE', 'fallback_value'),
    });
  });

  Logger.level = LogLevel.debug;
  await app.listen(port: 3006);
}
