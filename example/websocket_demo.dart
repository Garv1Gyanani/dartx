import 'dart:convert';
import 'package:kronix/kronix.dart';

void main() async {
  final app = App();

  // Root route for UI
  app.get('/', (ctx) async {
    return ctx.html('''
      <!DOCTYPE html>
      <html>
      <head>
        <title>Kronix WebSocket Hub</title>
        <style>
          body { font-family: sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; background: #f4f4f9; }
          #chat { border: 1px solid #ddd; height: 300px; overflow-y: scroll; padding: 15px; background: white; border-radius: 8px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); margin-bottom: 20px; }
          .msg { margin-bottom: 8px; padding: 5px 10px; border-radius: 4px; }
          .msg.server { background: #e3f2fd; color: #1565c0; border-left: 4px solid #1565c0; }
          .msg.room { background: #f3e5f5; color: #7b1fa2; border-left: 4px solid #7b1fa2; }
          .msg.user { background: #f1f8e9; color: #33691e; border-left: 4px solid #33691e; }
          .controls { display: flex; gap: 10px; }
          input { flex: 1; padding: 10px; border: 1px solid #ddd; border-radius: 4px; }
          button { padding: 10px 20px; background: #2e7d32; color: white; border: none; border-radius: 4px; cursor: pointer; }
          button:hover { background: #1b5e20; }
          .rooms { margin-bottom: 10px; font-weight: bold; }
        </style>
      </head>
      <body>
        <h1>🚀 Kronix WebSocket Hub</h1>
        <div class="rooms">
          Join Room: 
          <button onclick="joinRoom('general')">General</button>
          <button onclick="joinRoom('vip')">VIP</button>
        </div>
        <div id="chat"></div>
        <div class="controls">
          <input type="text" id="input" placeholder="Type a message to the room...">
          <button onclick="sendMessage()">Send to Room</button>
          <button onclick="broadcast()" style="background: #1565c0;">Global Broadcast</button>
        </div>

        <script>
          let socket;
          let currentRoom = 'general';
          const chat = document.getElementById('chat');
          
          function connect() {
            socket = new WebSocket('ws://' + window.location.host + '/ws');
            
            socket.onopen = () => {
              addMessage('Connected to Kronix!', 'server');
              joinRoom('general');
            };

            socket.onmessage = (event) => {
              const data = JSON.parse(event.data);
              addMessage(`[\${data.from}] \${data.text}`, data.type || 'user');
            };

            socket.onclose = () => addMessage('Disconnected.', 'server');
          }

          function addMessage(text, type) {
            const div = document.createElement('div');
            div.className = 'msg ' + type;
            div.textContent = text;
            chat.appendChild(div);
            chat.scrollTop = chat.scrollHeight;
          }

          function joinRoom(room) {
            currentRoom = room;
            socket.send(JSON.stringify({ action: 'join', room: room }));
            addMessage('Joined room: ' + room, 'room');
          }

          function sendMessage() {
            const text = document.getElementById('input').value;
            socket.send(JSON.stringify({ action: 'message', room: currentRoom, text: text }));
            document.getElementById('input').value = '';
          }

          function broadcast() {
             socket.send(JSON.stringify({ action: 'broadcast', text: document.getElementById('input').value }));
             document.getElementById('input').value = '';
          }

          connect();
        </script>
      </body>
      </html>
    ''');
  });

  // Matured WebSocket Handler
  app.ws('/ws', (conn) {
    print('New Hub connection: ${conn.id}');

    conn.listen((data) {
      final payload = Map<String, dynamic>.from(jsonDecode(data));
      final action = payload['action'];

      if (action == 'join') {
        final room = payload['room'];
        conn.join(room);
        print('Client ${conn.id} joined $room');
      } 
      
      else if (action == 'message') {
        final room = payload['room'];
        final text = payload['text'];
        // Broadcast to specific room using the global Hub
        app.wsHub.toRoom(room, {
          'from': 'Room $room',
          'text': text,
          'type': 'user'
        });
      }

      else if (action == 'broadcast') {
        final text = payload['text'];
        // Global broadcast
        app.wsHub.broadcast({
          'from': 'GLOBAL',
          'text': text,
          'type': 'server'
        });
      }
    }, onDone: () {
      print('Client ${conn.id} left.');
    });
  });

  print('Hub Demo starting on http://localhost:3000');
  await app.listen(port: 3000);
}
