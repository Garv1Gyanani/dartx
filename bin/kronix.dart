import 'dart:io';
import 'dart:async';
import 'package:args/args.dart';
import 'package:watcher/watcher.dart';
import 'templates.dart';

void main(List<String> args) {
  final parser = ArgParser()
    ..addCommand('create')
    ..addCommand('make:controller')
    ..addCommand('make:service')
    ..addCommand('make:middleware')
    ..addCommand('make:request')
    ..addCommand('make:migration')
    ..addCommand('make:model', ArgParser()..addFlag('migration', abbr: 'm', negatable: false))
    ..addCommand('migrate')
    ..addCommand('migrate:rollback')
    ..addCommand('route:list')
    ..addCommand('watch', ArgParser()..addOption('target', abbr: 't', defaultsTo: 'bin/server.dart'));

  late ArgResults results;
  try {
    results = parser.parse(args);
  } catch (e) {
    print('Error: $e');
    _printUsage();
    return;
  }

  if (results.command == null) {
    _printUsage();
    return;
  }

  final cmd = results.command!;
  switch (cmd.name) {
    case 'create':
      _createApp(cmd.rest);
      break;
    case 'make:controller':
      _generateComponent(cmd.rest, 'controller', 'app/controllers', Templates.controller);
      break;
    case 'make:service':
      _generateComponent(cmd.rest, 'service', 'app/services', Templates.service);
      break;
    case 'make:middleware':
      _generateComponent(cmd.rest, 'middleware', 'app/middleware', Templates.middleware);
      break;
    case 'make:request':
      _generateComponent(cmd.rest, 'request', 'app/requests', Templates.request);
      break;
    case 'make:migration':
      _generateMigration(cmd.rest);
      break;
    case 'make:model':
      _generateModel(cmd);
      break;
    case 'migrate':
      _runMigrations(rollback: false);
      break;
    case 'migrate:rollback':
      _runMigrations(rollback: true);
      break;
    case 'route:list':
      _listRoutes();
      break;
    case 'watch':
      _watch(cmd['target']);
      break;
    default:
      print('Unknown command: ${cmd.name}');
  }
}

void _printUsage() {
  print('Usage: kronix <command> [arguments]');
  print('\nCommands:');
  print('  create <name>       Scaffold a new Kronix application');
  print('  make:controller <N> Create a new controller');
  print('  make:service <N>    Create a new service');
  print('  make:middleware <N> Create a new middleware');
  print('  make:request <N>    Create a new request validation class');
  print('  make:migration <N>  Create a new database migration');
  print('  make:model <N> [-m] Create a new model (optional: create migration)');
  print('  migrate             Run pending migrations');
  print('  migrate:rollback    Rollback last migration batch');
  print('  route:list          List all registered routes');
  print('  watch [-t target]   Run with hot reload (default target: bin/server.dart)');
}

void _createApp(List<String> args) {
  if (args.isEmpty) {
    print('Error: Please specify app name (e.g., kronix create my_app)');
    return;
  }
  final name = args[0];
  final root = Directory(name);
  
  if (root.existsSync()) {
    print('Error: Directory $name already exists.');
    return;
  }

  print('🚀 Scaffolding new Kronix app: $name...');

  // Create Folders
  _createDir('$name/bin');
  _createDir('$name/lib/app');
  _createDir('$name/app/controllers');
  _createDir('$name/app/services');
  _createDir('$name/app/middleware');
  _createDir('$name/app/requests');
  _createDir('$name/app/models');
  _createDir('$name/routes');
  _createDir('$name/config');
  _createDir('$name/database/migrations');

  // Create Files
  _writeFile('$name/pubspec.yaml', Templates.pubspec(name));
  _writeFile('$name/.env', Templates.env());
  _writeFile('$name/bin/server.dart', Templates.main());
  _writeFile('$name/lib/app.dart', Templates.appBoot());
  _writeFile('$name/routes/api.dart', Templates.apiRoutes());
  _writeFile('$name/app/controllers/user_controller.dart', Templates.controller('User'));

  print('\n✅ App $name created successfully!');
  print('\nNext steps:');
  print('  cd $name');
  print('  dart pub get');
  print('  kronix watch');
}

void _generateMigration(List<String> args) {
  if (args.isEmpty) {
    print('Error: Please specify migration name');
    return;
  }
  final name = args[0];
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final fileName = '${timestamp}_${name.toLowerCase()}.dart';
  final path = 'database/migrations/$fileName';

  // Format className: create_users_table -> CreateUsersTable
  final className = name.split('_').map((s) => s[0].toUpperCase() + s.substring(1)).join('');

  _writeFile(path, Templates.migration(className));
  print('✨ Created migration: $className at $path');
}

void _generateModel(ArgResults cmd) {
  if (cmd.rest.isEmpty) {
    print('Error: Please specify model name');
    return;
  }
  final name = cmd.rest[0];
  _generateComponent([name], 'model', 'app/models', Templates.model);

  if (cmd['migration'] == true) {
    final tableName = '${name.toLowerCase()}s';
    _generateMigration(['create_${tableName}_table']);
  }
}

void _listRoutes() {
  print('ℹ️  Listing routes requires booting the app. This feature is coming soon!');
  print('Tip: Check your routes/api.dart file.');
}

void _generateComponent(List<String> args, String type, String folder, String Function(String) template) {
  if (args.isEmpty) {
    print('Error: Please specify $type name');
    return;
  }
  final name = args[0];
  final fileName = '${name.toLowerCase()}_$type.dart';
  final path = '$folder/$fileName';

  _writeFile(path, template(name));
  print('✨ Created $type: $name at $path');
}

void _createDir(String path) {
  Directory(path).createSync(recursive: true);
}

void _writeFile(String path, String content) {
  final file = File(path);
  if (!file.parent.existsSync()) {
    file.parent.createSync(recursive: true);
  }
  file.writeAsStringSync(content);
}

void _runMigrations({bool rollback = false}) async {
  final dir = Directory('database/migrations');
  if (!dir.existsSync()) {
    print('Error: database/migrations directory not found.');
    return;
  }

  final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.dart')).toList();
  files.sort((a, b) => a.path.compareTo(b.path));

  final imports = <String>[];
  final entries = <String>[];

  for (var file in files) {
    final fileName = file.path.split(Platform.pathSeparator).last;
    final nameWithoutExt = fileName.replaceFirst('.dart', '');
    
    // We need the class name. For now, let's assume it's the part after the timestamp.
    // e.g. 123456789_create_users -> CreateUsers
    final parts = nameWithoutExt.split('_');
    final className = parts.skip(1).map((s) => s[0].toUpperCase() + s.substring(1)).join('');
    
    imports.add("import 'migrations/$fileName';");
    entries.add("MigrationEntry('$nameWithoutExt', $className())");
  }

  final runnerContent = '''
import 'package:kronix/kronix.dart';
${imports.join('\n')}

void main() async {
  Config.load();
  final db = PostgresAdapter(
    host: Config.get('DB_HOST', 'localhost')!,
    database: Config.get('DB_NAME', 'kronix')!,
    username: Config.get('DB_USER', 'postgres'),
    password: Config.get('DB_PASS', 'postgres'),
  );

  final runner = MigrationRunner(db, [
    ${entries.join(',\n    ')}
  ]);

  try {
    if ($rollback) {
      await runner.rollback();
    } else {
      await runner.run();
    }
  } finally {
    await db.close();
  }
}
''';

  final tempFile = File('database/run_migrations.dart');
  tempFile.writeAsStringSync(runnerContent);

  print('⏳ Running migrations...');
  final result = await Process.run('dart', ['run', tempFile.path]);
  
  if (result.exitCode != 0) {
    print('❌ Migration failed.');
  }

  tempFile.deleteSync();
}

void _watch(List<String> args) async {
  final target = args.isNotEmpty ? args[0] : 'bin/server.dart';
  if (!File(target).existsSync()) {
    print('Error: Target file $target not found.');
    return;
  }

  print('👀 Watching for changes... Target: $target');
  Process? process;

  Future<void> restart() async {
    if (process != null) {
      print('♻️ Restarting...');
      process!.kill();
    }
    process = await Process.start(
      'dart',
      ['run', target],
      mode: ProcessStartMode.inheritStdio,
    );
  }

  await restart();

  final watcher = DirectoryWatcher(Directory.current.path);
  Timer? debounce;

  watcher.events.listen((event) {
    if (event.path.endsWith('.dart') || event.path.endsWith('.env')) {
      if (event.path.contains('.dart_tool') || event.path.contains('.git')) return;
      
      debounce?.cancel();
      debounce = Timer(const Duration(milliseconds: 300), () {
        print('📝 Change detected: ${event.path}');
        restart();
      });
    }
  });
}
