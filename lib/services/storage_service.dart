import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final ImagePicker _picker = ImagePicker();

  Future<File?> pickAndCompressImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image == null) return null;

      final File file = File(image.path);
      final img.Image? originalImage =
          img.decodeImage(await file.readAsBytes());

      if (originalImage == null) return null;

      // Compress image
      final img.Image compressedImage = img.copyResize(
        originalImage,
        width: 800,
        height: (800 * originalImage.height / originalImage.width).round(),
      );

      // Save compressed image
      final Directory tempDir = await getTemporaryDirectory();
      final String tempPath =
          '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final File compressedFile = File(tempPath)
        ..writeAsBytesSync(img.encodeJpg(compressedImage, quality: 85));

      return compressedFile;
    } catch (e) {
      print('Error picking/compressing image: $e');
      return null;
    }
  }

  Future<String?> uploadImage(File image) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/upload');
      final request = http.MultipartRequest('POST', uri);

      request.files.add(await http.MultipartFile.fromPath(
        'image',
        image.path,
      ));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return responseData;
      }
      return null;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> clearCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      await tempDir.delete(recursive: true);
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }
}
