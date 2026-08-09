// lib/services/local_storage_service.dart
//
// الطبقة المسؤولة عن التخزين المحلي (SQLite) لفيتشر العمل بلا نت.
// أربع جداول:
//   - cached_profile         : نسخة من بيانات البروفايل (GET /profile)
//   - cached_tasks            : نسخة من قوائم المهام لكل category
//   - cached_task_details     : نسخة من تفاصيل مهمة واحدة (items + barcode)
//   - pending_operations      : طابور العمليات (scan / complete / disposal)
//     اللي صارت أوفلاين ولسا ما انبعتت للسيرفر
//
// كل القيم متخزنة كـ JSON نصي (TEXT) عشان نعيد استخدام نفس الـ
// fromJson factories الموجودة أصلاً بالموديلات (order_model.dart...)
// بدون ما نكرر منطق الـ parsing بمكانين.

import 'dart:async';
import 'dart:convert';

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
      version: 1,
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
            type TEXT NOT NULL,          -- 'scan' | 'complete' | 'disposal'
            task_id INTEGER,
            payload TEXT NOT NULL,       -- JSON: barcode / quantity / ...
            status TEXT NOT NULL DEFAULT 'pending', -- 'pending' | 'failed'
            error_message TEXT,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );
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
  }
}
