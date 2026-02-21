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
    ..addCommand('make:model')
    ..addCommand('migrate')
    ..addCommand('migrate:rollback')
    ..addCommand('watch');

  final results = parser.parse(args);

  if (results.command == null) {
    _printUsage();
    return;
  }

  switch (results.command!.name) {
    case 'create':
      _createApp(results.command!.rest);
      break;
    case 'make:controller':
      _generateComponent(results.command!.rest, 'controller', 'app/controllers', Templates.controller);
      break;
    case 'make:service':
      _generateComponent(results.command!.rest, 'service', 'app/services', Templates.service);
      break;
    case 'make:middleware':
      _generateComponent(results.command!.rest, 'middleware', 'app/middleware', Templates.middleware);
      break;
    case 'make:request':
      _generateComponent(results.command!.rest, 'request', 'app/requests', Templates.request);
      break;
    case 'make:migration':
      _generateMigration(results.command!.rest);
      break;
    case 'make:model':
      _generateComponent(results.command!.rest, 'model', 'app/models', Templates.model);
      break;
    case 'migrate':
      _runMigrations(rollback: false);
      break;
    case 'migrate:rollback':
      _runMigrations(rollback: true);
      break;
    case 'watch':
      _watch(results.command!.rest);
      break;
    default:
      print('Unknown command: ${results.command!.name}');
  }
}

void _printUsage() {
  print('Usage: dartx <command> [arguments]');
  print('\nCommands:');
  print('  create <name>       Scaffold a new DartX application');
  print('  make:controller <N> Create a new controller');
  print('  make:service <N>    Create a new service');
  print('  make:middleware <N> Create a new middleware');
  print('  make:request <N>    Create a new request validation class');
  print('  make:migration <N>  Create a new database migration');
  print('  make:model <N>       Create a new model');
  print('  migrate             Run pending migrations');
  print('  migrate:rollback    Rollback last migration batch');
  print('  watch [file]        Run with hot reload');
}

void _createApp(List<String> args) {
  if (args.isEmpty) {
    print('Error: Please specify app name (e.g., dartx create my_app)');
    return;
  }
  final name = args[0];
  final root = Directory(name);
  
  if (root.existsSync()) {
    print('Error: Directory $name already exists.');
    return;
  }

  print('🚀 Scaffolding new DartX app: $name...');

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
  print('  dartx watch bin/server.dart');
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

  _writeFile(path, Templates.migration(name));
  print('✨ Created migration: $name at $path');
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
  File(path).writeAsStringSync(content);
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
import 'package:dartx/dartx.dart';
${imports.join('\n')}

void main() async {
  Config.load();
  final db = PostgresAdapter(
    host: Config.get('DB_HOST', 'localhost')!,
    database: Config.get('DB_NAME', 'dartx')!,
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
