import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class CompressionService {
  static Future<File?> compressFile(File file) async {
    try {
      final String ext = path.extension(file.path).toLowerCase();
      if (ext == '.pdf') return file; // Don't compress PDFs

      final dir = await getTemporaryDirectory();
      final targetPath =
          path.join(dir.path, 'compressed_${path.basename(file.path)}');

      if (ext == '.jpg' || ext == '.jpeg' || ext == '.png') {
        final result = await FlutterImageCompress.compressAndGetFile(
          file.path,
          targetPath,
          quality: 70, // Adjust quality as needed
          minWidth: 1024,
          minHeight: 1024,
        );
        return result != null ? File(result.path) : null;
      }
      return file;
    } catch (e) {
      print('Error compressing file: $e');
      return null;
    }
  }
}
