import 'dart:async';
import 'dart:io';
import '../services/document_cache_service.dart';
import '../services/provider_document_service.dart';

class DocumentSyncService {
  final _documentService = ProviderDocumentService();
  Timer? _syncTimer;

  void startAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(Duration(minutes: 15), (_) => syncDocuments());
  }

  Future<void> syncDocuments() async {
    try {
      final cachedDocs = await DocumentCacheService.getCachedDocuments();
      for (var doc in cachedDocs) {
        if (doc.status == 'pending') {
          await _documentService.uploadDocument(
            documentType: doc.documentType,
            file: File(doc.fileUrl),
            mimeType: 'application/octet-stream',
          );
        }
      }
    } catch (e) {
      print('Error syncing documents: $e');
    }
  }

  void dispose() {
    _syncTimer?.cancel();
  }
}
