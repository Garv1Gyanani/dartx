import 'dart:io';
import 'package:path/path.dart' as p;

/// Represents a file uploaded via a multipart/form-data request.
/// 
/// In Kronix, uploaded files are streamed to disk by default to prevent
/// memory exhaustion on large uploads.
/// 
/// **Security Note:** The [filename] property is the raw, untrusted value
/// from the client. Always use [safeFilename] when constructing file paths
/// to prevent path traversal attacks.
class UploadedFile {
  /// The original filename as provided by the client.
  /// 
  /// ⚠️ This is **untrusted** user input. Never use it directly in file paths.
  /// Use [safeFilename] instead.
  final String filename;

  /// The MIME type of the file.
  final String contentType;

  /// The internal path to the temporary file on disk.
  final String tempPath;

  /// The internal path to the temporary directory.
  final String? tempDir;

  /// The size of the file in bytes.
  final int size;

  bool _deleted = false;

  /// Creates a new [UploadedFile] instance.
  UploadedFile({
    required this.filename,
    required this.contentType,
    required this.tempPath,
    required this.size,
    this.tempDir,
  });

  /// Returns a sanitized version of [filename] safe for use in file paths.
  /// 
  /// Strips path components, replaces unsafe characters, and preserves 
  /// only the base name with its extension.
  /// 
  /// Example: `../../etc/passwd` → `etcpasswd`
  /// Example: `my photo (1).jpg` → `my_photo_1_.jpg`
  String get safeFilename {
    // Extract only the base name (strip directory traversal)
    final base = p.basename(filename);
    // Get extension separately to preserve it
    final ext = p.extension(base);
    final nameWithoutExt = p.basenameWithoutExtension(base);
    // Replace any non-alphanumeric/dot/hyphen/underscore chars
    final sanitized = nameWithoutExt.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    // Prevent empty filenames
    final safeName = sanitized.isEmpty ? 'upload' : sanitized;
    return '$safeName$ext';
  }

  /// Returns `true` if the temporary file has already been deleted or moved.
  bool get isDeleted => _deleted;

  /// Opens a stream to read the file content.
  /// 
  /// Throws [StateError] if the file has already been deleted.
  Stream<List<int>> openRead() {
    if (_deleted) throw StateError('Cannot read: file has already been deleted or moved.');
    return File(tempPath).openRead();
  }

  /// Reads the entire file content as bytes.
  /// 
  /// If [maxSize] is provided and the file exceeds it, a [StateError] is thrown
  /// instead of loading the file into memory.
  /// 
  /// 💣 Warning: Calling this without a [maxSize] on very large files 
  /// can cause memory issues.
  Future<List<int>> readAsBytes({int? maxSize}) async {
    if (_deleted) throw StateError('Cannot read: file has already been deleted or moved.');
    if (maxSize != null && size > maxSize) {
      throw StateError(
        'File "$filename" is $size bytes, which exceeds the maxSize limit of $maxSize bytes. '
        'Use openRead() for streaming access instead.'
      );
    }
    return File(tempPath).readAsBytes();
  }

  /// Saves the file to the specified [path] and deletes the temporary file.
  /// 
  /// Attempts a fast `rename()` (zero-copy move) first. If the destination
  /// is on a different filesystem, falls back to `copy()` + `delete()`.
  /// 
  /// Throws [StateError] if the file has already been deleted.
  Future<File> saveAs(String path) async {
    if (_deleted) throw StateError('Cannot save: file has already been deleted or moved.');

    final dest = File(path);
    if (!await dest.parent.exists()) {
      await dest.parent.create(recursive: true);
    }

    try {
      // Attempt fast move (same filesystem)
      final moved = await File(tempPath).rename(path);
      _deleted = true;

      // Clean up the now-empty temp directory
      if (tempDir != null) {
        try {
          final dir = Directory(tempDir!);
          if (await dir.exists()) {
            await dir.delete(recursive: true);
          }
        } catch (_) {}
      }

      return moved;
    } catch (_) {
      // Fallback to copy if cross-device (EXDEV error)
      final copied = await File(tempPath).copy(path);
      await delete();
      return copied;
    }
  }

  /// Deletes the temporary file and directory. 
  /// 
  /// This is handled automatically by [Context.dispose()] if not already called.
  /// Safe to call multiple times — subsequent calls are no-ops.
  Future<void> delete() async {
    if (_deleted) return;
    _deleted = true;
    
    try {
      if (tempDir != null) {
        final dir = Directory(tempDir!);
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      } else {
        final file = File(tempPath);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (_) {
      // Best effort cleanup
    }
  }
}
