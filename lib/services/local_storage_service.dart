// lib/services/local_storage_service.dart
//
// الطبقة المسؤولة عن التخزين المحلي (SQLite) لفيتشر العمل بلا نت.
// الجداول:
//   - cached_profile          : نسخة من بيانات البروفايل (GET /profile)
//   - cached_tasks             : نسخة من قوائم المهام لكل category
//   - cached_task_details      : نسخة من تفاصيل مهمة واحدة (items + barcode)
//   - cached_disposals         : نسخة من قائمة طلبات الإتلاف الحرة
//   - cached_disposal_details  : نسخة من تفاصيل طلب إتلاف واحد
//   - pending_operations       : طابور العمليات (scan / complete / disposal /
//     profile_update) اللي صارت أوفلاين ولسا ما انبعتت للسيرفر
//
// كل القيم متخزنة كـ JSON نصي (TEXT) عشان نعيد استخدام نفس الـ
// fromJson factories الموجودة أصلاً بالموديلات (order_model.dart...)
// بدون ما نكرر منطق الـ parsing بمكانين.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'stock_app_offline.db');

    return openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE cached_profile (
            id INTEGER PRIMARY KEY CHECK (id = 1),
            data TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE cached_tasks (
            category TEXT PRIMARY KEY,
            data TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE cached_task_details (
            task_id INTEGER PRIMARY KEY,
            data TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE pending_operations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,          -- 'scan' | 'complete' | 'disposal' | 'profile_update'
            task_id INTEGER,
            payload TEXT NOT NULL,       -- JSON: barcode / quantity / ...
            status TEXT NOT NULL DEFAULT 'pending', -- 'pending' | 'failed'
            error_message TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE cached_disposals (
            id INTEGER PRIMARY KEY CHECK (id = 1),
            data TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE cached_disposal_details (
            disposal_id INTEGER PRIMARY KEY,
            data TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // v1 -> v2: إضافة جدول كاش قائمة طلبات الإتلاف الحرة (Disposals)
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS cached_disposals (
              id INTEGER PRIMARY KEY CHECK (id = 1),
              data TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
        }
        // v2 -> v3: إضافة جدول كاش تفاصيل طلب إتلاف واحد (كان ناقص —
        // العطل يلي "تفاصيل المنتج بتختفي أوفلاين" حتى لو انفتحت قبل هيك)
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS cached_disposal_details (
              disposal_id INTEGER PRIMARY KEY,
              data TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
        }
      },
    );
  }

  // ============================================================
  // ملفات معلّقة (حالياً: صورة بروفايل اتغيّرت أوفلاين ولسا ما انرفعت)
  //
  // بنستخدم نفس مجلد قاعدة بيانات sqflite (getDatabasesPath) كأب لمجلد
  // دائم خاص فينا، بدل ما نضيف اعتمادية جديدة (متل path_provider) بس
  // لهاد الغرض. المسار ثابت وخاص بالتطبيق على كل من Android/iOS.
  // ============================================================
  Future<Directory> _pendingUploadsDir() async {
    final dbPath = await getDatabasesPath();
    final dir = Directory(join(dirname(dbPath), 'pending_uploads'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// بينسخ الصورة الملتقطة/المختارة لمجلد دائم خاص فينا (بعيد عن أي
  /// cache مؤقت ممكن النظام ينضّفه)، وبيرجع المسار الجديد. هاد المسار
  /// هو يلي بينخزن بالـ payload بالطابور، وبيتقرأ منه لما نزامن.
  Future<String> persistPendingImage(File sourceFile) async {
    final dir = await _pendingUploadsDir();
    final ext = extension(sourceFile.path);
    final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}$ext';
    final savedPath = join(dir.path, fileName);
    await sourceFile.copy(savedPath);
    return savedPath;
  }

  /// بينظّف ملف صورة معلّق بعد ما ينرفع بنجاح (أو لما تلغى/تتحدّث
  /// العملية) — عشان ما يضل يتراكم مساحة تخزين فاضية بالجهاز.
  Future<void> deletePendingImage(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // أي فشل بالحذف (صلاحيات، الملف انمسح أصلاً...) مش خطأ حرج،
      // بنتجاهله بأمان.
    }
  }

  // ============================================================
  // البروفايل
  // ============================================================
  Future<void> saveProfile(Map<String, dynamic> profileJson) async {
    final db = await _database;
    await db.insert(
      'cached_profile',
      {
        'id': 1,
        'data': jsonEncode(profileJson),
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getProfile() async {
    final db = await _database;
    final rows = await db.query('cached_profile', where: 'id = 1', limit: 1);
    if (rows.isEmpty) return null;
    return jsonDecode(rows.first['data'] as String) as Map<String, dynamic>;
  }

  // ============================================================
  // طلبات الإتلاف الحرة (Disposals) — نسخة وحيدة كاملة من آخر رد ناجح
  // لـ GET /workers/disposals (نفس مبدأ cached_profile بالضبط).
  // ============================================================
  // dynamic (مش Map حصراً) لأن رد GET /workers/disposals ممكن يكون List
  // مباشر أو Map — نفس المرونة يلي DisposalsResponse.fromJson(dynamic)
  // أصلاً بتدعمها.
  Future<void> saveDisposals(dynamic disposalsJson) async {
    final db = await _database;
    await db.insert(
      'cached_disposals',
      {
        'id': 1,
        'data': jsonEncode(disposalsJson),
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<dynamic> getDisposals() async {
    final db = await _database;
    final rows = await db.query('cached_disposals', where: 'id = 1', limit: 1);
    if (rows.isEmpty) return null;
    return jsonDecode(rows.first['data'] as String);
  }

  // تفاصيل طلب إتلاف واحد — نسخة لكل disposal_id لحاله (نفس مبدأ
  // cached_task_details تماماً).
  Future<void> saveDisposalDetails(int disposalId, Map<String, dynamic> data) async {
    final db = await _database;
    await db.insert(
      'cached_disposal_details',
      {
        'disposal_id': disposalId,
        'data': jsonEncode(data),
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getDisposalDetails(int disposalId) async {
    final db = await _database;
    final rows = await db.query(
      'cached_disposal_details',
      where: 'disposal_id = ?',
      whereArgs: [disposalId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return jsonDecode(rows.first['data'] as String) as Map<String, dynamic>;
  }

  // ============================================================
  // قوائم المهام (لكل category نسخة لحالها)
  // ============================================================
  Future<void> saveTasks(String category, Map<String, dynamic> tasksJson) async {
    final db = await _database;
    await db.insert(
      'cached_tasks',
      {
        'category': category,
        'data': jsonEncode(tasksJson),
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getTasks(String category) async {
    final db = await _database;
    final rows = await db.query(
      'cached_tasks',
      where: 'category = ?',
      whereArgs: [category],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return jsonDecode(rows.first['data'] as String) as Map<String, dynamic>;
  }

  // ============================================================
  // تفاصيل مهمة واحدة
  // ============================================================
  Future<void> saveTaskDetails(int taskId, Map<String, dynamic> detailsJson) async {
    final db = await _database;
    await db.insert(
      'cached_task_details',
      {
        'task_id': taskId,
        'data': jsonEncode(detailsJson),
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getTaskDetails(int taskId) async {
    final db = await _database;
    final rows = await db.query(
      'cached_task_details',
      where: 'task_id = ?',
      whereArgs: [taskId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return jsonDecode(rows.first['data'] as String) as Map<String, dynamic>;
  }

  // ============================================================
  // طابور العمليات المعلّقة (pending_operations)
  // ============================================================
  Future<int> addPendingOperation({
    required String type,
    int? taskId,
    required Map<String, dynamic> payload,
  }) async {
    final db = await _database;
    return db.insert('pending_operations', {
      'type': type,
      'task_id': taskId,
      'payload': jsonEncode(payload),
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getPendingOperations({String? status}) async {
    final db = await _database;
    final rows = await db.query(
      'pending_operations',
      where: status != null ? 'status = ?' : null,
      whereArgs: status != null ? [status] : null,
      orderBy: 'id ASC', // FIFO
    );

    return rows.map((row) {
      return {
        'id': row['id'],
        'type': row['type'],
        'task_id': row['task_id'],
        'payload': jsonDecode(row['payload'] as String) as Map<String, dynamic>,
        'status': row['status'],
        'error_message': row['error_message'],
        'created_at': row['created_at'],
      };
    }).toList();
  }

  Future<void> deletePendingOperation(int id) async {
    final db = await _database;
    await db.delete('pending_operations', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> markPendingOperationFailed(int id, String errorMessage) async {
    final db = await _database;
    await db.update(
      'pending_operations',
      {'status': 'failed', 'error_message': errorMessage},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> countPendingOperations() async {
    final db = await _database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as count FROM pending_operations WHERE status = 'pending'",
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ============================================================
  // تنظيف كامل (يُستخدم عند logout مثلاً)
  // ============================================================
  Future<void> clearAll() async {
    final db = await _database;
    await db.delete('cached_profile');
    await db.delete('cached_tasks');
    await db.delete('cached_task_details');
    await db.delete('pending_operations');
    await db.delete('cached_disposals');
    await db.delete('cached_disposal_details');
  }
}
