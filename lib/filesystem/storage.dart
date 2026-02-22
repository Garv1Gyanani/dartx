import 'dart:io';
import 'package:path/path.dart' as p;
import '../di/container.dart';

/// Abstract interface for file storage systems.
abstract class Storage {
  /// Stores the [bytes] at the specified [path].
  /// 
  /// Returns the path where the file was stored.
  Future<String> put(String path, List<int> bytes);

  /// Retrieves the content of the file at [path] as bytes.
  Future<List<int>> get(String path);

  /// Checks if a file exists at [path].
  Future<bool> exists(String path);

  /// Deletes the file at [path].
  Future<void> delete(String path);

  /// Returns a public URL for the file at [path].
  String url(String path);
}

/// A [Storage] implementation that uses the local filesystem.
class LocalStorage implements Storage {
  /// The root directory where files are stored.
  final String root;

  /// The base URL for serving files stored in this root.
  final String baseUrl;

  /// Creates a new [LocalStorage] instance.
  LocalStorage({required this.root, this.baseUrl = '/storage'});

  @override
  Future<String> put(String path, List<int> bytes) async {
    final fullPath = p.join(root, path);
    final file = File(fullPath);
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }
    await file.writeAsBytes(bytes);
    return path;
  }

  @override
  Future<List<int>> get(String path) async {
    final file = File(p.join(root, path));
    return await file.readAsBytes();
  }

  @override
  Future<bool> exists(String path) async {
    return await File(p.join(root, path)).exists();
  }

  @override
  Future<void> delete(String path) async {
    final file = File(p.join(root, path));
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  String url(String path) {
    return p.join(baseUrl, path).replaceAll(r'\', '/');
  }
}

/// Global helper for accessing the default storage disk.
Storage get storage => di.resolve<Storage>();
