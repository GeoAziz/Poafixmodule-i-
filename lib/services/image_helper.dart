import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'dart:convert';

class ImageHelper {
  static final ImagePicker _picker = ImagePicker();

  static Future<String?> pickAndProcessImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512, // Reasonable size for profile picture
        maxHeight: 512,
      );

      if (image == null) return null;

      // Read image file
      final File imageFile = File(image.path);
      final bytes = await imageFile.readAsBytes();

      // Convert to base64
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      return base64Image;
    } catch (e) {
      print('Error processing image: $e');
      return null;
    }
  }
}
