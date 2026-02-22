import 'dart:io';

/// Represents a file uploaded via a multipart/form-data request.
class UploadedFile {
  /// The original filename as provided by the client.
  final String filename;

  /// The MIME type of the file.
  final String contentType;

  /// The content of the file as bytes.
  final List<int> bytes;

  /// Creates a new [UploadedFile] instance.
  UploadedFile({
    required this.filename,
    required this.contentType,
    required this.bytes,
  });

  /// The size of the file in bytes.
  int get size => bytes.length;

  /// Saves the file to the specified [path].
  Future<File> saveAs(String path) async {
    final file = File(path);
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }
    return await file.writeAsBytes(bytes);
  }
}
