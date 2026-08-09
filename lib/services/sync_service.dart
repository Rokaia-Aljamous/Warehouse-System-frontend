// lib/services/sync_service.dart
//
// المسؤول عن إعادة إرسال العمليات المعلّقة (pending_operations) للسيرفر
// لما يرجع النت. يشتغل بترتيب FIFO (نفس ترتيب حصولها) عشان مثلاً
// عمليات "scan" لمهمة معينة تنبعت قبل عملية "complete" تبعتها.
//
// حالياً بيدعم: scan, complete (خاصين بمهام العامل - TaskService).
// أي نوع عملية غير معروف (مثل disposal لسا ما انبنى) بيتم تجاهله
// بأمان بدون ما يوقف بقية الطابور.

import 'package:stock_app/services/task_service.dart';
import 'package:stock_app/services/local_storage_service.dart';

class SyncResult {
  final int syncedCount;
  final int failedCount;
  const SyncResult({required this.syncedCount, required this.failedCount});
}

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final LocalStorageService _localStorage = LocalStorageService();
  final TaskService _taskService = TaskService();

  bool _isSyncing = false;

  /// يمرّ على كل العمليات المعلّقة ويحاول يبعتها. بيرجع لما يخلص.
  /// إذا انقطع النت بمنتصف المزامنة، بيوقف فورًا (العمليات المتبقية
  /// بتضل pending وبتنحاول تاني بالمرة الجاية).
  Future<SyncResult> syncPendingOperations() async {
    if (_isSyncing) {
      return const SyncResult(syncedCount: 0, failedCount: 0);
    }
    _isSyncing = true;

    var synced = 0;
    var failed = 0;

    try {
      final ops = await _localStorage.getPendingOperations(status: 'pending');

      for (final op in ops) {
        final id = op['id'] as int;
        final type = op['type'] as String;
        final taskId = op['task_id'] as int?;
        final payload = op['payload'] as Map<String, dynamic>;

        final outcome = await _syncOne(type: type, taskId: taskId, payload: payload);

        switch (outcome) {
          case _SyncOutcome.success:
            await _localStorage.deletePendingOperation(id);
            synced++;
            break;
          case _SyncOutcome.rejected:
            // رفض حقيقي من السيرفر (مش مشكلة نت) — منسجله كـ failed
            // ومنكمل بالعمليات التانية بدل ما نوقف الطابور كله
            await _localStorage.markPendingOperationFailed(
              id,
              'Server rejected this operation',
            );
            failed++;
            break;
          case _SyncOutcome.networkStillDown:
            // النت انقطع تاني بمنتصف المزامنة — نوقف هون ونكمل بالمرة الجاية
            return SyncResult(syncedCount: synced, failedCount: failed);
          case _SyncOutcome.skipped:
            break;
        }
      }
    } finally {
      _isSyncing = false;
    }

    return SyncResult(syncedCount: synced, failedCount: failed);
  }

  Future<_SyncOutcome> _syncOne({
    required String type,
    required int? taskId,
    required Map<String, dynamic> payload,
  }) async {
    if (taskId == null) return _SyncOutcome.skipped;

    Map<String, dynamic> result;

    switch (type) {
      case 'scan':
        final barcode = payload['barcode']?.toString();
        if (barcode == null) return _SyncOutcome.skipped;
        result = await _taskService.scanBarcode(taskId, barcode);
        break;
      case 'complete':
        result = await _taskService.completeTask(taskId);
        break;
      default:
        return _SyncOutcome.skipped;
    }

    if (result['success'] == true) return _SyncOutcome.success;

    final isNetworkFailure = result['statusCode'] == null;
    return isNetworkFailure ? _SyncOutcome.networkStillDown : _SyncOutcome.rejected;
  }
}

enum _SyncOutcome { success, rejected, networkStillDown, skipped }
