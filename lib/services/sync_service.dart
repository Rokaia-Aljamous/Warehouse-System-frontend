// lib/services/sync_service.dart
//
// المسؤول عن إعادة إرسال العمليات المعلّقة (pending_operations) للسيرفر
// لما يرجع النت. يشتغل بترتيب FIFO (نفس ترتيب حصولها) عشان مثلاً
// عمليات "scan" لمهمة معينة تنبعت قبل عملية "complete" تبعتها.
//
// بيدعم: scan, complete (خاصين بمهام العامل - TaskService)، disposal
// (طلبات الإتلاف الحرة - DisposalService)، وprofile_update (تعديل
// البروفايل بما فيه الصورة - AuthService).
// أي نوع عملية غير معروف بيتم تجاهله بأمان بدون ما يوقف بقية الطابور.

import 'dart:io';

import 'package:stock_app/services/task_service.dart';
import 'package:stock_app/services/local_storage_service.dart';
import 'package:stock_app/services/disposal_service.dart';
import 'package:stock_app/services/auth_service.dart';

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
  final DisposalService _disposalService = DisposalService();
  final AuthService _authService = AuthService();

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
    Map<String, dynamic> result;

    switch (type) {
      case 'scan':
        {
          if (taskId == null) return _SyncOutcome.skipped;
          final barcode = payload['barcode']?.toString();
          if (barcode == null) return _SyncOutcome.skipped;
          result = await _taskService.scanBarcode(taskId, barcode);
          break;
        }
      case 'complete':
        if (taskId == null) return _SyncOutcome.skipped;
        result = await _taskService.completeTask(taskId);
        break;
      case 'disposal':
        {
          // طلبات الإتلاف الحرة مش مرتبطة بـ task_id (task_id = null بالطابور
          // دايماً لهاد النوع) — البيانات كلها موجودة بالـ payload.
          final barcode = payload['barcode']?.toString();
          final quantity = (payload['quantity'] as num?)?.toInt();
          final damageReason = payload['damage_reason']?.toString();
          if (barcode == null || quantity == null || damageReason == null) {
            return _SyncOutcome.skipped;
          }
          result = await _disposalService.createDisposal(
            barcode: barcode,
            quantity: quantity,
            damageReason: damageReason,
          );
          break;
        }
      case 'profile_update':
        {
          // نفس مبدأ 'disposal': ما إلها task_id، وكل البيانات بالـ payload.
          // imagePath (إذا موجود) هو مسار الصورة المحفوظة محلياً بواسطة
          // LocalStorageService.persistPendingImage عند التسجيل أوفلاين.
          final fullName = payload['full_name']?.toString();
          final phoneNumber = payload['phone_number']?.toString();
          final birthday = payload['birthday']?.toString();
          final imagePath = payload['image_path']?.toString();

          File? imageFile;
          if (imagePath != null && imagePath.isNotEmpty) {
            final candidate = File(imagePath);
            if (await candidate.exists()) {
              imageFile = candidate;
            }
            // لو الملف مش موجود (انمسح بطريقة ما)، منكمل بدون صورة بدل
            // ما نوقف مزامنة باقي الحقول النصية.
          }

          result = await _authService.updateProfile(
            fullName: fullName,
            phoneNumber: phoneNumber,
            birthday: birthday,
            profileImage: imageFile,
          );

          if (result['success'] == true && imagePath != null && imagePath.isNotEmpty) {
            // انرفعت الصورة بنجاح — منحذف النسخة المحلية المؤقتة.
            await _localStorage.deletePendingImage(imagePath);
          }
          break;
        }
      default:
        return _SyncOutcome.skipped;
    }

    if (result['success'] == true) return _SyncOutcome.success;

    final isNetworkFailure = result['statusCode'] == null;
    return isNetworkFailure ? _SyncOutcome.networkStillDown : _SyncOutcome.rejected;
  }
}

enum _SyncOutcome { success, rejected, networkStillDown, skipped }
