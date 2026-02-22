import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:test/test.dart';
import 'package:kronix/kronix.dart';

void main() {
  final host = 'localhost';

  group('WebSocket Architecture Tests', () {
    
    test('Protocol Upgrade Detection', () async {
      final app = App();
      final port = 3101;
      app.ws('/ws-test', (conn) {
        conn.send('welcome');
      });

      unawaited(app.listen(port: port, host: host));
      await Future.delayed(Duration(milliseconds: 200));

      final client = HttpClient();
      final request = await client.getUrl(Uri.parse('http://$host:$port/ws-test'));
      final response = await request.close();
      expect(response.statusCode, equals(404));

      final ws = await WebSocket.connect('ws://$host:$port/ws-test');
      final firstMsg = await ws.first;
      expect(firstMsg, equals('welcome'));
      await ws.close();
      client.close();
    });

    test('Middleware Protection (Success Case)', () async {
      final app = App();
      final port = 3102;
      Future<Response> mockMiddleware(Context ctx, Next next) async {
        ctx.request.attributes['test'] = 'passed';
        return await next();
      }

      app.ws('/secure', (conn) {
        conn.send(conn.context.request.attributes['test']);
      }, middleware: [mockMiddleware]);

      unawaited(app.listen(port: port, host: host));
      await Future.delayed(Duration(milliseconds: 200));

      final ws = await WebSocket.connect('ws://$host:$port/secure');
      final msg = await ws.first;
      expect(msg, equals('passed'));
      await ws.close();
    });

    test('Middleware Protection (Auth Failure Case)', () async {
      final app = App();
      final port = 3103;
      Future<Response> rejectMiddleware(Context ctx, Next next) async {
        return Response.json({'error': 'unauthorized'}, status: 401);
      }

      app.ws('/protected', (conn) {
        conn.send('should not see this');
      }, middleware: [rejectMiddleware]);

      unawaited(app.listen(port: port, host: host));
      await Future.delayed(Duration(milliseconds: 200));

      try {
        await WebSocket.connect('ws://$host:$port/protected');
      } catch (e) {
        expect(e, anyOf(isA<WebSocketException>(), isA<HttpException>()));
      }
    });

    test('Room Isolation and Broadcasting', () async {
      final app = App();
      final port = 3104;
      app.ws('/hub', (conn) {
        conn.listen((data) {
          final msg = jsonDecode(data);
          if (msg['action'] == 'join') conn.join(msg['room']);
          if (msg['action'] == 'to_room') {
            app.wsHub.toRoom(msg['room'], msg['text']);
          }
        });
      });

      unawaited(app.listen(port: port, host: host));
      await Future.delayed(Duration(milliseconds: 200));

      final wsA = await WebSocket.connect('ws://$host:$port/hub');
      wsA.add(jsonEncode({'action': 'join', 'room': 'room1'}));

      final wsB = await WebSocket.connect('ws://$host:$port/hub');
      wsB.add(jsonEncode({'action': 'join', 'room': 'room2'}));

      final wsC = await WebSocket.connect('ws://$host:$port/hub');
      wsC.add(jsonEncode({'action': 'join', 'room': 'room1'}));

      await Future.delayed(Duration(milliseconds: 100));
      wsA.add(jsonEncode({'action': 'to_room', 'room': 'room1', 'text': 'hello room1'}));

      final msgC = await wsC.first.timeout(Duration(seconds: 1));
      expect(msgC, equals('hello room1'));

      bool receivedB = false;
      try {
        await wsB.first.timeout(Duration(milliseconds: 500));
        receivedB = true;
      } catch (_) {}
      expect(receivedB, isFalse);

      await wsA.close();
      await wsB.close();
      await wsC.close();
    });

    test('Automatic JSON Encoding', () async {
        final app = App();
        final port = 3105;
        app.ws('/json', (conn) {
            conn.send({'status': 'ok', 'code': 200});
        });

        unawaited(app.listen(port: port, host: host));
        await Future.delayed(Duration(milliseconds: 200));

        final ws = await WebSocket.connect('ws://$host:$port/json');
        final msg = await ws.first;
        expect(jsonDecode(msg), equals({'status': 'ok', 'code': 200}));
        await ws.close();
    });

  });
}
