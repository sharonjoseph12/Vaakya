import 'package:sqflite/sqflite.dart';

class LocalDatabase {
  LocalDatabase._();
  static final LocalDatabase instance = LocalDatabase._();
  Database? _database;
  bool _seeded = false;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = '$dbPath/vaakya_cache.db';
    return openDatabase(path, version: 4, onCreate: (db, version) async {
      await db.execute('CREATE TABLE offline_cache (id INTEGER PRIMARY KEY AUTOINCREMENT, keywords TEXT NOT NULL, answer_text TEXT NOT NULL, language TEXT NOT NULL, created_at TEXT NOT NULL)');
      await db.execute('CREATE TABLE bookmarks (id INTEGER PRIMARY KEY AUTOINCREMENT, text TEXT NOT NULL, topic TEXT, created_at TEXT NOT NULL)');
      await db.execute('CREATE TABLE faculty_notes (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, content TEXT NOT NULL, file_path TEXT, created_at TEXT NOT NULL)');
      await db.execute('CREATE TABLE flashcards (id INTEGER PRIMARY KEY AUTOINCREMENT, front TEXT NOT NULL, back TEXT NOT NULL, next_review TEXT NOT NULL, interval_days INTEGER DEFAULT 1, ease_factor REAL DEFAULT 2.5, created_at TEXT NOT NULL)');
    }, onUpgrade: (db, oldV, newV) async {
      if (oldV < 2) await db.execute('CREATE TABLE IF NOT EXISTS bookmarks (id INTEGER PRIMARY KEY AUTOINCREMENT, text TEXT NOT NULL, topic TEXT, created_at TEXT NOT NULL)');
      if (oldV < 3) await db.execute('CREATE TABLE IF NOT EXISTS faculty_notes (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, content TEXT NOT NULL, file_path TEXT, created_at TEXT NOT NULL)');
      if (oldV < 4) await db.execute('CREATE TABLE IF NOT EXISTS flashcards (id INTEGER PRIMARY KEY AUTOINCREMENT, front TEXT NOT NULL, back TEXT NOT NULL, next_review TEXT NOT NULL, interval_days INTEGER DEFAULT 1, ease_factor REAL DEFAULT 2.5, created_at TEXT NOT NULL)');
    });
  }

  /// Pre-seed offline DB with educational content
  Future<void> seedIfNeeded() async {
    if (_seeded) return;
    _seeded = true;
    final db = await database;
    final count = (await db.rawQuery('SELECT COUNT(*) as c FROM offline_cache')).first['c'] as int;
    if (count > 5) return; // Already has data

    final seeds = {
      'trigonometry': 'Trigonometry studies angles and sides of triangles. SOH CAH TOA: Sin=opp/hyp, Cos=adj/hyp, Tan=opp/adj.',
      'photosynthesis': 'Photosynthesis is how plants make food. 6CO2 + 6H2O + light → C6H12O6 + 6O2. Chlorophyll captures sunlight.',
      'newton gravity force': 'Newton\'s 3 laws: 1) Inertia 2) F=ma 3) Action-reaction. Gravity pulls objects toward earth at 9.8m/s².',
      'cell mitochondria nucleus': 'A cell is life\'s basic unit. Nucleus=control center with DNA. Mitochondria=powerhouse. Plant cells have chloroplasts+cell wall.',
      'atom element periodic table': 'Atoms have protons+neutrons (nucleus) and electrons. Periodic table organizes elements by atomic number.',
      'algebra equation quadratic': 'Quadratic: ax²+bx+c=0. Formula: x=(-b±√(b²-4ac))/2a.',
      'independence gandhi freedom': 'India\'s independence: Aug 15, 1947. Gandhi led non-violent movement. Salt March 1930 was pivotal.',
      'water cycle evaporation': 'Water cycle: evaporation→condensation→precipitation→collection. Sun heats water, vapor rises, clouds form, rain falls.',
      'fraction percentage decimal': 'To convert fraction to %: divide numerator by denominator, multiply by 100. 3/4 = 0.75 = 75%.',
      'electricity current voltage': 'Ohm\'s Law: V=IR. Voltage(V) = Current(I) × Resistance(R). Current flows from high to low potential.',
      'त्रिकोणमिति': 'त्रिकोणमिति त्रिभुजों के कोणों और भुजाओं के बीच संबंधों का अध्ययन है। SOH CAH TOA याद रखें।',
      'प्रकाश संश्लेषण': 'प्रकाश संश्लेषण में पौधे सूर्य के प्रकाश से भोजन बनाते हैं। 6CO2 + 6H2O + प्रकाश → C6H12O6 + 6O2',
      'कोशिका': 'कोशिका जीवन की मूल इकाई है। केंद्रक=नियंत्रण केंद्र। माइटोकॉन्ड्रिया=ऊर्जा उत्पादक।',
      'गुरुत्वाकर्षण': 'न्यूटन के तीन नियम: 1) जड़त्व 2) F=ma 3) क्रिया-प्रतिक्रिया।',
    };
    for (final e in seeds.entries) {
      await db.insert('offline_cache', {'keywords': e.key, 'answer_text': e.value, 'language': 'en-IN', 'created_at': DateTime.now().toIso8601String()});
    }
  }

  Future<void> cacheResponse({required String query, required String answer, required String language}) async {
    final db = await database;
    await db.insert('offline_cache', {'keywords': query.toLowerCase().trim(), 'answer_text': answer, 'language': language, 'created_at': DateTime.now().toIso8601String()});
  }

  Future<String?> searchOffline(String query) async {
    final db = await database;
    final n = query.toLowerCase().trim();
    var results = await db.query('offline_cache', where: 'keywords LIKE ?', whereArgs: ['%$n%'], orderBy: 'created_at DESC', limit: 1);
    if (results.isNotEmpty) return results.first['answer_text'] as String;
    final words = n.split(' ').where((w) => w.length > 3).toList();
    for (final word in words) {
      results = await db.query('offline_cache', where: 'keywords LIKE ?', whereArgs: ['%$word%'], orderBy: 'created_at DESC', limit: 1);
      if (results.isNotEmpty) return results.first['answer_text'] as String;
    }
    return null;
  }

  // ── Bookmarks ──
  Future<void> addBookmark(String text, {String? topic}) async {
    final db = await database;
    await db.insert('bookmarks', {'text': text, 'topic': topic ?? '', 'created_at': DateTime.now().toIso8601String()});
  }

  Future<List<Map<String, dynamic>>> getBookmarks() async {
    final db = await database;
    return db.query('bookmarks', orderBy: 'created_at DESC');
  }

  Future<void> removeBookmark(int id) async {
    final db = await database;
    await db.delete('bookmarks', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearCache() async {
    final db = await database;
    await db.delete('offline_cache');
  }

  // ── Faculty Notes ──
  Future<void> addFacultyNote({required String title, required String content, required String filePath}) async {
    final db = await database;
    await db.insert('faculty_notes', {'title': title, 'content': content, 'file_path': filePath, 'created_at': DateTime.now().toIso8601String()});
    // Also cache content for offline AI answers
    final words = title.toLowerCase().split(' ').where((w) => w.length > 2).join(' ');
    await db.insert('offline_cache', {'keywords': words, 'answer_text': content.length > 500 ? content.substring(0, 500) : content, 'language': 'en-IN', 'created_at': DateTime.now().toIso8601String()});
  }

  Future<List<Map<String, dynamic>>> getFacultyNotes() async {
    final db = await database;
    return db.query('faculty_notes', orderBy: 'created_at DESC');
  }

  Future<void> removeFacultyNote(int id) async {
    final db = await database;
    await db.delete('faculty_notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<String> getAllFacultyContent() async {
    final db = await database;
    final notes = await db.query('faculty_notes');
    return notes.map((n) => n['content']).join('\n\n');
  }

  // ── Flashcards (Spaced Repetition) ──
  Future<void> addFlashcard({required String front, required String back}) async {
    final db = await database;
    await db.insert('flashcards', {'front': front, 'back': back, 'next_review': DateTime.now().toIso8601String(), 'interval_days': 1, 'ease_factor': 2.5, 'created_at': DateTime.now().toIso8601String()});
  }

  Future<List<Map<String, dynamic>>> getDueFlashcards() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    return db.query('flashcards', where: 'next_review <= ?', whereArgs: [now], orderBy: 'next_review ASC');
  }

  Future<List<Map<String, dynamic>>> getAllFlashcards() async {
    final db = await database;
    return db.query('flashcards', orderBy: 'created_at DESC');
  }

  Future<void> reviewFlashcard(int id, int quality) async {
    // SM-2 algorithm: quality 0-5 (0=forgot, 5=perfect)
    final db = await database;
    final cards = await db.query('flashcards', where: 'id = ?', whereArgs: [id]);
    if (cards.isEmpty) return;
    final card = cards.first;
    double ef = (card['ease_factor'] as num).toDouble();
    int interval = (card['interval_days'] as int?) ?? 1;
    if (quality < 3) {
      interval = 1; // Reset
    } else {
      if (interval == 1) { interval = 3; }
      else { interval = (interval * ef).round(); }
      ef = ef + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
      if (ef < 1.3) ef = 1.3;
    }
    final nextReview = DateTime.now().add(Duration(days: interval));
    await db.update('flashcards', {'interval_days': interval, 'ease_factor': ef, 'next_review': nextReview.toIso8601String()}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> removeFlashcard(int id) async {
    final db = await database;
    await db.delete('flashcards', where: 'id = ?', whereArgs: [id]);
  }
}
