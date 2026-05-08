import 'package:sqflite/sqflite.dart';

/// SQLite-backed offline cache for chat answers.
class LocalDatabase {
  LocalDatabase._();
  static final LocalDatabase instance = LocalDatabase._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = '$dbPath/voiceguru_cache.db';

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE offline_cache (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            keywords TEXT NOT NULL,
            answer_text TEXT NOT NULL,
            language TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  /// Cache a successful API response for offline usage.
  Future<void> cacheResponse({
    required String query,
    required String answer,
    required String language,
  }) async {
    final db = await database;
    // Normalize keywords: lowercase, trimmed
    final keywords = query.toLowerCase().trim();

    await db.insert('offline_cache', {
      'keywords': keywords,
      'answer_text': answer,
      'language': language,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Search offline cache by keyword matching.
  /// Returns the best-matching answer or `null`.
  Future<String?> searchOffline(String query) async {
    final db = await database;
    final normalized = query.toLowerCase().trim();

    // Try exact-ish match first
    final results = await db.query(
      'offline_cache',
      where: 'keywords LIKE ?',
      whereArgs: ['%$normalized%'],
      orderBy: 'created_at DESC',
      limit: 1,
    );

    if (results.isNotEmpty) {
      return results.first['answer_text'] as String;
    }

    // Fallback: try individual words
    final words =
        normalized.split(' ').where((w) => w.length > 3).toList();
    for (final word in words) {
      final wordResults = await db.query(
        'offline_cache',
        where: 'keywords LIKE ?',
        whereArgs: ['%$word%'],
        orderBy: 'created_at DESC',
        limit: 1,
      );
      if (wordResults.isNotEmpty) {
        return wordResults.first['answer_text'] as String;
      }
    }

    return null;
  }

  /// Clear all cached responses.
  Future<void> clearCache() async {
    final db = await database;
    await db.delete('offline_cache');
  }
}
