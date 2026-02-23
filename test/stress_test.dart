import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:kronix/kronix.dart';

void main() {
  group('Kronix Stress Test Suite', () {
    late App app;
    late int port;

    setUp(() async {
      Config.set('MAX_CONCURRENT_REQUESTS', '100'); // Reset to default
      app = App();
      // Setup a random port
      final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      port = socket.port;
      await socket.close();
    });

    tearDown(() async {
      await app.stop();
    });

    test('High Concurrency & Backpressure Rejection', () async {
      // Configure low concurrency for test
      Config.set('MAX_CONCURRENT_REQUESTS', '10');
      
      app.get('/slow', (ctx) async {
        await Future.delayed(Duration(milliseconds: 500));
        return ctx.text('slept');
      });

      unawaited(app.listen(port: port, host: 'localhost'));
      await Future.delayed(Duration(milliseconds: 200));

      // Fire 15 concurrent requests. 10 should be accepted, 5 rejected (503)
      final results = await Future.wait(
        List.generate(15, (_) => http.get(Uri.parse('http://localhost:$port/slow')))
      );

      final accepted = results.where((r) => r.statusCode == 200).length;
      final rejected = results.where((r) => r.statusCode == 503).length;

      print('Accepted: $accepted, Rejected: $rejected');
      expect(accepted, lessThanOrEqualTo(10));
      expect(rejected, greaterThanOrEqualTo(5));
    });

    test('Resource Cleanup (Temp Files) Under Load', () async {
      int deletedCount = 0;
      app.post('/upload', (ctx) async {
        // Request comes with temp files. We just read and return.
        // Context.dispose() should delete them.
        return ctx.text('ok');
      });

      unawaited(app.listen(port: port, host: 'localhost'));
      await Future.delayed(Duration(milliseconds: 200));

      // Simulate heavy upload load
      final boundary = '----WebKitFormBoundary7MA4YWxkTrZu0gW';
      final body = '--$boundary\r\n'
          'Content-Disposition: form-data; name="file"; filename="test.txt"\r\n'
          'Content-Type: text/plain\r\n\r\n'
          'some largeish content\r\n'
          '--$boundary--\r\n';

      await Future.wait(List.generate(50, (_) => http.post(
        Uri.parse('http://localhost:$port/upload'),
        headers: {'Content-Type': 'multipart/form-data; boundary=$boundary'},
        body: body,
      )));

      // Check temp directory - should be empty or only contain unrelated files
      final tempDir = Directory(Config.get('TEMP_DIR', 'temp/uploads')!);
      if (await tempDir.exists()) {
        final files = await tempDir.list().length;
        print('Remaining temp files: $files');
        expect(files, 0, reason: 'Temp files were not cleaned up');
      }
    });

    test('Database Transaction Integrity Under Load', () async {
      final mockDb = ConcurrentMockDB();
      di.registerInstance<DatabaseAdapter>(mockDb);

      app.use(transactionMiddleware());
      app.post('/tx', (ctx) async {
        final tx = ctx.resolve<DatabaseExecutor>();
        await tx.query('UPDATE counter SET value = value + 1');
        return ctx.text('ok');
      });

      unawaited(app.listen(port: port, host: 'localhost'));
      await Future.delayed(Duration(milliseconds: 200));

      // Fire 50 concurrent requests that start transactions
      await Future.wait(List.generate(50, (_) => http.post(Uri.parse('http://localhost:$port/tx'))));

      print('History length: ${mockDb.history.length}');
      // Each request had 1 query.
      expect(mockDb.history.length, 50);
    });

    test('Validation Engine Stress (Deep Nesting)', () async {
      app.post('/validate', (ctx) async {
        final data = await ctx.validateData({
          'user.profile.settings.notifications.email': 'required|boolean',
          'items.*.price': 'required|numeric|min:10',
        });
        return ctx.json(data);
      });

      unawaited(app.listen(port: port, host: 'localhost'));
      await Future.delayed(Duration(milliseconds: 200));

      final hugePayload = {
        'user': {
          'profile': {
            'settings': {
              'notifications': {'email': 'true'}
            }
          }
        },
        'items': List.generate(100, (i) => {'price': 10 + i})
      };

      final response = await http.post(
        Uri.parse('http://localhost:$port/validate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(hugePayload),
      );

      expect(response.statusCode, 200);
      final decoded = jsonDecode(response.body);
      expect(decoded['user']['profile']['settings']['notifications']['email'], true);
    });

    test('Graceful Shutdown Drains Active Requests', () async {
      bool requestFinished = false;
      app.get('/long', (ctx) async {
        await Future.delayed(Duration(seconds: 1));
        requestFinished = true;
        return ctx.text('done');
      });

      unawaited(app.listen(port: port, host: 'localhost'));
      await Future.delayed(Duration(milliseconds: 200));

      final reqFuture = http.get(Uri.parse('http://localhost:$port/long'));

      await Future.delayed(Duration(milliseconds: 100));
      print('Stopping app...');
      final stopFuture = app.stop();

      final result = await reqFuture;
      expect(result.statusCode, 200);
      expect(requestFinished, true);
      
      await stopFuture;
    });

    test('Extreme Load Performance (1,000,000 Requests)', () async {
      // Allow the server to handle extreme concurrency
      Config.set('MAX_CONCURRENT_REQUESTS', '50000');
      Logger.level = LogLevel.error; // Only log critical errors

      app.get('/fast', (ctx) async {
        return ctx.text('f'); // Minimal response body for speed
      });

      unawaited(app.listen(port: port, host: 'localhost'));
      await Future.delayed(Duration(milliseconds: 200));

      const totalRequests = 1000000;
      const batchSize = 1000;
      int successful = 0;
      int failed = 0;

      print('🚀 STARTING MEGA STRESS TEST: 1,000,000 requests...');
      print('ℹ️  Batch size: $batchSize | Targeted throughput: ~500 req/s');
      
      final sw = Stopwatch()..start();
      
      for (var i = 0; i < totalRequests; i += batchSize) {
        final batch = await Future.wait(
          List.generate(batchSize, (_) => http.get(Uri.parse('http://localhost:$port/fast')))
        );
        
        for (final res in batch) {
          if (res.statusCode == 200) {
            successful++;
          } else {
            failed++;
          }
        }

        if (i % 50000 == 0 && i > 0) {
          final elapsed = sw.elapsedMilliseconds / 1000;
          final currentRps = (i / elapsed).toStringAsFixed(2);
          print('📊 Progress: $i / $totalRequests ($currentRps req/s)...');
        }
      }
      
      sw.stop();

      final rps = (totalRequests / (sw.elapsedMilliseconds / 1000)).toStringAsFixed(2);
      
      print('\n🏁 MEGA STRESS TEST COMPLETE:');
      print('   Total: $totalRequests');
      print('   Successful: $successful');
      print('   Failed: $failed');
      print('   Total Time: ${(sw.elapsedMilliseconds / 1000).toStringAsFixed(2)}s');
      print('   Throughput: $rps req/s');

      expect(successful, totalRequests);
    });
  });
}

class ConcurrentMockDB extends DatabaseAdapter {
  final List<String> history = [];
  
  @override
  Future<QueryResult> query(String sql, [Map<String, dynamic>? params]) async {
    history.add(sql);
    return ConcurrentMockQueryResult([]);
  }

  @override
  Future<T> transaction<T>(Future<T> Function(DatabaseExecutor tx) callback) async {
    // Simulate some work
    await Future.delayed(Duration(milliseconds: 10));
    return await callback(this);
  }

  @override
  QueryBuilder table(String name, [DatabaseExecutor? executor]) {
    return QueryBuilder(name, executor ?? this);
  }

  @override Future<void> connect() async {}
  @override Future<void> close() async {}
  @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class ConcurrentMockQueryResult implements QueryResult {
  @override final List<Map<String, dynamic>> rows;
  @override final int? affectedRows = 0;
  ConcurrentMockQueryResult(this.rows);
}
