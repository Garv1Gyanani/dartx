import 'dart:io';

/// Represents a file uploaded via a multipart/form-data request.
/// 
/// In Kronix, uploaded files are streamed to disk by default to prevent
/// memory exhaustion on large uploads.
class UploadedFile {
  /// The original filename as provided by the client.
  final String filename;

  /// The MIME type of the file.
  final String contentType;

  /// The internal path to the temporary file on disk.
  final String tempPath;

  /// The internal path to the temporary directory.
  final String? tempDir;

  /// The size of the file in bytes.
  final int size;

  /// Creates a new [UploadedFile] instance.
  UploadedFile({
    required this.filename,
    required this.contentType,
    required this.tempPath,
    required this.size,
    this.tempDir,
  });

  /// Opens a stream to read the file content.
  Stream<List<int>> openRead() => File(tempPath).openRead();

  /// Reads the entire file content as bytes.
  /// 
  /// 💣 Warning: Calling this on very large files can cause memory issues.
  Future<List<int>> readAsBytes() => File(tempPath).readAsBytes();

  /// Saves the file to the specified [path] and deletes the temporary file.
  Future<File> saveAs(String path) async {
    final file = File(path);
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }
    
    // Copy to destination
    final savedFile = await File(tempPath).copy(path);
    
    // Cleanup temp resources
    await delete();
    
    return savedFile;
  }

  /// Deletes the temporary file and directory. 
  /// 
  /// This is handled automatically by the request context disposal
  /// if not already called.
  Future<void> delete() async {
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
