// lib/controllers/destruction_controller.dart
//
// مزود الحالة (State Management) الخاص بـ "طلبات الإتلاف" الحرة (Disposals)
// اللي بيسويها العامل بنفسه من شاشة Request List — منفصل عن OrderController
// اللي بيدير مهام الإتلاف الرسمية المُسندة (Destruction task_type: damage_disposal).
//
// نفس فلسفة OrderController بالظبط: يُغلّف DisposalService ولا تتعامل
// الواجهات مع Dio مباشرة.

import 'package:flutter/material.dart';
import 'package:stock_app/models/destruction_model.dart';
import 'package:stock_app/services/disposal_service.dart';

class DestructionController extends ChangeNotifier {
  final DisposalService _disposalService = DisposalService();

  // ---- قائمة الطلبات (Request List: تبويبَي Incoming / Archive) ----
  bool isLoadingList = false;
  String? listError;
  List<Disposal> _disposals = [];

  List<Disposal> get disposals => _disposals;

  // ---- تفاصيل طلب واحد ----
  bool isLoadingDetails = false;
  String? detailsError;
  Disposal? currentDisposal;

  // ---- إنشاء طلب جديد (Destruction Request form) ----
  bool isSubmitting = false;
  String? submitError;

  // ============================================================
  // 1) جلب كل طلبات الإتلاف
  // ============================================================
  Future<void> fetchDisposals() async {
    isLoadingList = true;
    listError = null;
    notifyListeners();

    final result = await _disposalService.getDisposals();
    isLoadingList = false;

    if (result['success'] == true) {
      _disposals = DisposalsResponse.fromJson(result['data']).items;
      notifyListeners();
      return;
    }

    listError = result['message']?.toString() ?? 'Failed to load disposal requests';
    notifyListeners();
  }

  // ============================================================
  // 2) تفاصيل طلب واحد
  // ============================================================
  Future<bool> fetchDisposalDetails(int id) async {
    isLoadingDetails = true;
    detailsError = null;
    notifyListeners();

    final result = await _disposalService.getDisposalDetails(id);
    isLoadingDetails = false;

    if (result['success'] == true) {
      final data = result['data'];
      final body = data is Map && data['data'] is Map
          ? Map<String, dynamic>.from(data['data'] as Map)
          : (data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{});
      currentDisposal = Disposal.fromJson(body);
      notifyListeners();
      return true;
    }

    detailsError = result['message']?.toString() ?? 'Failed to load disposal details';
    notifyListeners();
    return false;
  }

  // ============================================================
  // 3) إنشاء طلب إتلاف جديد — POST /workers/disposals
  // بعد النجاح، بيحدّث القائمة تلقائياً حتى تظهر بتبويب Request List فوراً
  // ============================================================
  Future<bool> createDisposal({
    required String barcode,
    required int quantity,
    required String damageReason,
  }) async {
    isSubmitting = true;
    submitError = null;
    notifyListeners();

    final result = await _disposalService.createDisposal(
      barcode: barcode,
      quantity: quantity,
      damageReason: damageReason,
    );

    isSubmitting = false;

    if (result['success'] == true) {
      submitError = null;
      notifyListeners();
      await fetchDisposals();
      return true;
    }

    submitError = result['message']?.toString() ?? 'Failed to submit disposal request';
    notifyListeners();
    return false;
  }

  void clearCurrentDisposal() {
    currentDisposal = null;
    detailsError = null;
  }
}