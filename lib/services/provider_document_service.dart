import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;
import '../models/provider_document_model.dart';
import '../config/api_config.dart';

class ProviderDocumentService {
  final _storage = const FlutterSecureStorage();
  final _client = http.Client();

  Future<String?> _getAuthToken() async {
    try {
      final possibleKeys = ['auth_token', 'token', 'access_token'];
      String? token;
      for (String key in possibleKeys) {
        token = await _storage.read(key: key);
        if (token != null) break;
      }
      return token;
    } catch (e) {
      print('Error getting auth token: $e');
      return null;
    }
  }

  Future<String?> _getUserId() async {
    try {
      return await _storage.read(key: 'userId') ??
          await _storage.read(key: 'user_id');
    } catch (e) {
      print('Error getting user ID: $e');
      return null;
    }
  }

  Future<List<ProviderDocument>> getProviderDocuments() async {
    try {
      final token = await _getAuthToken();
      final providerId = await _getUserId();
      if (token == null || providerId == null) {
        throw Exception('Authentication required');
      }
      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/provider-documents/$providerId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((doc) => ProviderDocument.fromJson(doc)).toList();
      }
      throw Exception('Failed to load documents: ${response.statusCode}');
    } catch (e) {
      print('Error in getProviderDocuments: $e');
      rethrow;
    }
  }

  Future<bool> uploadDocument({
    required String documentType,
    required File file,
    required String mimeType,
  }) async {
    try {
      final token = await _getAuthToken();
      final providerId = await _getUserId();
      if (token == null || providerId == null) {
        throw Exception('Authentication required');
      }
      var uri = Uri.parse('${ApiConfig.baseUrl}/provider-documents/upload');
      var request = http.MultipartRequest('POST', uri)
        ..headers.addAll({'Authorization': 'Bearer $token'})
        ..fields['providerId'] = providerId
        ..fields['documentType'] = documentType
        ..files.add(await http.MultipartFile.fromPath(
          'document',
          file.path,
          contentType: MediaType.parse(mimeType),
        ));
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return response.statusCode == 201;
    } catch (e) {
      print('Error uploading document: $e');
      return false;
    }
  }

  Future<bool> validateDocument(File file, String type) async {
    final size = await file.length();
    final ext = path.extension(file.path).toLowerCase();
    if (size > 10 * 1024 * 1024) {
      throw 'File size must be less than 10MB';
    }
    final validTypes = {
      'image': ['.jpg', '.jpeg', '.png'],
      'document': ['.pdf']
    };
    if (!(validTypes['image']!.contains(ext) ||
        validTypes['document']!.contains(ext))) {
      throw 'Invalid file type. Allowed: JPG, PNG, PDF';
    }
    return true;
  }

  Future<void> checkDocumentExpiry() async {
    try {
      final docs = await getProviderDocuments();
      for (var doc in docs) {
        if (doc.expiryDate != null &&
            doc.expiryDate!.difference(DateTime.now()).inDays <= 30) {
          // You can add notification logic here
          print('Document ${doc.documentType} will expire soon.');
        }
      }
    } catch (e) {
      print('Error checking document expiry: $e');
    }
  }

  /// Returns true if the provider has documents pending verification.
  Future<bool> needsVerification() async {
    // TODO: Replace with real API call or logic.
    // For now, always return false (no pending verification).
    return false;
  }
}
