import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/provider_document_model.dart';

class DocumentCacheService {
  static Database? _database;
  static const String tableName = 'cached_documents';

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDB();
    return _database!;
  }

  static Future<Database> initDB() async {
    final documentsPath = await getDatabasesPath();
    final path = join(documentsPath, 'documents_cache.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE $tableName(
            id TEXT PRIMARY KEY,
            providerId TEXT,
            documentType TEXT,
            fileUrl TEXT,
            status TEXT,
            uploadedAt TEXT,
            verifiedAt TEXT,
            adminComment TEXT,
            localPath TEXT,
            expiryDate TEXT,
            lastSynced TEXT
          )
        ''');
      },
    );
  }

  static Future<void> cacheDocument(
      ProviderDocument document, String localPath) async {
    final db = await database;
    final data = document.toMap()
      ..addAll({
        'localPath': localPath,
        'lastSynced': DateTime.now().toIso8601String(),
      });
    await db.insert(tableName, data,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<ProviderDocument>> getCachedDocuments() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(tableName);
    return List.generate(
        maps.length, (i) => ProviderDocument.fromJson(maps[i]));
  }
}
