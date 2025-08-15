import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../services/provider_document_service.dart';
import '../models/provider_document_model.dart'; // Updated import path
import 'package:open_file/open_file.dart';
import '../services/compression_service.dart';
import '../services/document_cache_service.dart';
import '../services/document_sync_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DocumentUploadScreen extends StatefulWidget {
  const DocumentUploadScreen({super.key});

  @override
  _DocumentUploadScreenState createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  final ProviderDocumentService _documentService = ProviderDocumentService();
  final _syncService = DocumentSyncService();
  final _storage = const FlutterSecureStorage();
  List<ProviderDocument> _documents = [];
  bool _isLoading = true;
  bool _isUploading = false;
  String? _uploadingDocType;

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadDocuments();
    _syncService.startAutoSync();
    _checkExpiredDocuments();
  }

  Future<void> _checkAuthAndLoadDocuments() async {
    try {
      final token = await _storage.read(key: 'auth_token') ??
          await _storage.read(key: 'auth_token');
      final userId = await _storage.read(key: 'userId');

      print('🔑 Initial Auth Check:');
      print('Token: ${token != null ? "Present" : "Missing"}');
      print('User ID: ${userId != null ? "Present" : "Missing"}');

      if (token == null) {
        if (mounted) {
          setState(() => _isLoading = false);
          Navigator.of(context).pushReplacementNamed('/login');
        }
        return;
      }

      await _loadDocuments();
    } catch (e) {
      print('❌ Auth check error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showAuthError();
      }
    }
  }

  void _showAuthError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Session expired. Please log in again.'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Login',
          onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
        ),
      ),
    );
  }

  Future<void> _loadDocuments() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      print('📝 Loading documents...');
      final docs = await _documentService.getProviderDocuments();
      print('📦 Received ${docs.length} documents');

      if (!mounted) return;

      setState(() {
        _documents = docs;
        _isLoading = false; // This needs to be inside setState
      });

      print('✅ UI updated with ${_documents.length} documents');
    } catch (e) {
      print('❌ Error loading documents: $e');
      if (!mounted) return;

      setState(() {
        _documents = []; // Clear documents on error
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load documents. Please try again.'),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _loadDocuments,
          ),
        ),
      );
    }
  }

  Future<void> _pickAndUploadFile(String documentType) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);

        await _documentService.validateDocument(file, documentType);
        final compressedFile = await CompressionService.compressFile(file);
        if (compressedFile == null) return;

        setState(() {
          _isUploading = true;
          _uploadingDocType = documentType;
        });

        final success = await _documentService.uploadDocument(
          documentType: documentType,
          file: compressedFile,
          mimeType: result.files.single.extension == 'pdf'
              ? 'application/pdf'
              : 'image/${result.files.single.extension}',
        );

        if (success) {
          await DocumentCacheService.cacheDocument(
            ProviderDocument(
              id: DateTime.now().toString(),
              providerId: 'temp',
              documentType: documentType,
              fileUrl: compressedFile.path,
              status: 'pending',
              uploadedAt: DateTime.now(),
            ),
            compressedFile.path,
          );
          _showSuccess('Document uploaded successfully');
          _loadDocuments();
        }
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() {
        _isUploading = false;
        _uploadingDocType = null;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickAndUploadMultipleFiles(String documentType) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: true,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
        allowCompression: true,
      );

      if (result != null) {
        setState(() => _isLoading = true);

        for (final file in result.files) {
          final originalFile = File(file.path!);

          // Compress file if it's an image
          final compressedFile =
              await CompressionService.compressFile(originalFile);
          if (compressedFile == null) continue;

          final fileSize = await compressedFile.length();
          if (fileSize > 10 * 1024 * 1024) {
            _showError('File ${file.name} exceeds 10MB limit');
            continue;
          }

          final mimeType = file.extension == 'pdf'
              ? 'application/pdf'
              : 'image/${file.extension}';

          final success = await _documentService.uploadDocument(
            documentType: documentType,
            file: compressedFile,
            mimeType: mimeType,
          );

          if (success) {
            // Cache the document locally
            await DocumentCacheService.cacheDocument(
              ProviderDocument(
                id: DateTime.now().toString(),
                providerId: 'temp',
                documentType: documentType,
                fileUrl: compressedFile.path,
                status: 'pending',
                uploadedAt: DateTime.now(),
              ),
              compressedFile.path,
            );
          }
        }

        _showSuccess('Documents uploaded successfully');
        _loadDocuments();
      }
    } catch (e) {
      _showError('Error uploading documents: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Document Upload'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _checkAuthAndLoadDocuments,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Stack(
        children: [
          _isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading documents...'),
                    ],
                  ),
                )
              : _documents.isEmpty
                  ? _buildEmptyState()
                  : _buildDocumentList(),
          if (_isUploading)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.black.withOpacity(0.5),
                height: 80,
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Uploading $_uploadingDocType...'),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _pickAndUploadMultipleFiles('Business License'),
        label: Text('Upload'),
        icon: Icon(Icons.upload_file, semanticLabel: 'Upload Document'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.upload_file, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No documents found',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          ElevatedButton(
            onPressed: _loadDocuments,
            child: Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Text(
        'Upload Required Documents',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDocumentList() {
    final requiredDocuments = [
      'Business License',
      'ID Proof',
      'Insurance Document',
      'Professional Certification',
    ];

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: requiredDocuments.length,
      itemBuilder: (context, index) {
        final documentType = requiredDocuments[index];
        final uploadedDoc = _documents.firstWhere(
          (doc) => doc.documentType == documentType,
          orElse: () => ProviderDocument(
            id: '',
            providerId: '',
            documentType: documentType,
            status: 'pending',
            fileUrl: '',
            uploadedAt: DateTime.now(),
          ),
        );

        return _buildDocumentCard(documentType, uploadedDoc);
      },
    );
  }

  Widget _buildDocumentCard(String documentType, ProviderDocument? document) {
    final status = document?.status ?? 'pending';
    final isExpiring = document?.expiryDate != null &&
        document!.expiryDate!.difference(DateTime.now()).inDays <= 7;
    final statusColor = {
          'verified': Colors.green,
          'pending': Colors.orange,
          'rejected': Colors.red,
        }[status] ??
        Colors.grey;
    final statusIcon = {
          'verified': Icons.check_circle,
          'pending': Icons.hourglass_top,
          'rejected': Icons.cancel,
        }[status] ??
        Icons.help;

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Semantics(
              label: '$documentType Icon',
              child: Icon(_getDocumentIcon(documentType)),
            ),
            title: Text(documentType),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(statusIcon,
                        color: statusColor,
                        size: 18,
                        semanticLabel: 'Status Icon'),
                    SizedBox(width: 4),
                    Text(
                      _getStatusText(status),
                      style: TextStyle(
                          color: statusColor, fontWeight: FontWeight.bold),
                    ),
                    if (isExpiring)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          'Expiring soon!',
                          style: TextStyle(
                              color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                if (document?.adminComment != null && status == 'rejected')
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'Reason: ${document!.adminComment}',
                      style: TextStyle(
                          color: Colors.red, fontStyle: FontStyle.italic),
                    ),
                  ),
                if (document?.expiryDate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text(
                      'Expires: ${document!.expiryDate!.toLocal().toString().split(' ')[0]}',
                      style: TextStyle(
                          color: isExpiring ? Colors.red : Colors.grey),
                    ),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (document?.fileUrl != null && document!.fileUrl.isNotEmpty)
                  Semantics(
                    label: 'Preview Document',
                    child: IconButton(
                      icon: Icon(Icons.remove_red_eye),
                      onPressed: () => _previewDocument(document!),
                    ),
                  ),
                _buildUploadButton(documentType, document),
              ],
            ),
          ),
          if (status == 'rejected')
            Container(
              color: Colors.red.shade50,
              width: double.infinity,
              padding: EdgeInsets.all(8),
              child: Text(
                'Please re-upload this document',
                style: TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'verified':
        return '✅ Verified';
      case 'rejected':
        return '❌ Rejected';
      case 'pending':
        return '⏳ Pending Review';
      default:
        return '📥 Not Uploaded';
    }
  }

  Future<void> _previewDocument(ProviderDocument document) async {
    try {
      setState(() => _isLoading = true);

      // Try local cache first
      final cachedDocs = await DocumentCacheService.getCachedDocuments();
      final cachedDoc = cachedDocs.firstWhere(
        (doc) => doc.id == document.id,
        orElse: () => ProviderDocument(
          id: '',
          providerId: '',
          documentType: '',
          status: '',
          fileUrl: '',
          uploadedAt: DateTime.now(),
        ),
      );

      File? file;
      file = File(cachedDoc.fileUrl);

      if (mounted) {
        await OpenFile.open(file.path);
      }
    } catch (e) {
      _showError('Error previewing document: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildUploadButton(String documentType, ProviderDocument? document) {
    if (document?.status == 'verified') {
      return Semantics(
        label: 'Verified',
        child: Icon(Icons.check_circle, color: Colors.green),
      );
    }
    return Semantics(
      label: document != null ? 'Re-upload Document' : 'Upload Document',
      child: ElevatedButton(
        onPressed: () => _pickAndUploadFile(documentType),
        child: Text(document != null ? 'Re-upload' : 'Upload'),
      ),
    );
  }

  IconData _getDocumentIcon(String documentType) {
    switch (documentType) {
      case 'Business License':
        return Icons.business;
      case 'ID Proof':
        return Icons.person;
      case 'Insurance Document':
        return Icons.security;
      default:
        return Icons.description;
    }
  }

  void _checkExpiredDocuments() {
    _documentService.checkDocumentExpiry();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  void dispose() {
    _syncService.dispose();
    super.dispose();
  }
}
