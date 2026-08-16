// lib/controllers/destruction_controller.dart
//
// مزود الحالة (State Management) الخاص بـ "طلبات الإتلاف" الحرة (Disposals)
// اللي بيسويها العامل بنفسه من شاشة Request List — منفصل عن OrderController
// اللي بيدير مهام الإتلاف الرسمية المُسندة (Destruction task_type: damage_disposal).
//
// نفس فلسفة OrderController بالظبط: يُغلّف DisposalService ولا تتعامل
// الواجهات مع Dio مباشرة.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stock_app/models/destruction_model.dart';
import 'package:stock_app/services/disposal_service.dart';
import 'package:stock_app/services/local_storage_service.dart';
import 'package:stock_app/services/connectivity_service.dart';
import 'package:stock_app/services/sync_service.dart';

class DestructionController extends ChangeNotifier {
  final DisposalService _disposalService = DisposalService();
  final LocalStorageService _localStorage = LocalStorageService();
  final SyncService _syncService = SyncService();
  StreamSubscription<bool>? _connectivitySub;

  DestructionController() {
    // لما يرجع النت: منزامن كل الطابور (scan/complete/disposal مع بعض —
    // نفس الطابور المشترك يلي بيستخدمه OrderController)، وبعدين منحدّث
    // قائمة طلبات الإتلاف من السيرفر عشان تصير مطابقة تماماً.
    _connectivitySub = ConnectivityService().onStatusChange.listen((isOnline) {
      if (isOnline) _onReconnected();
    });
  }

  Future<void> _onReconnected() async {
    await _syncService.syncPendingOperations();
    if (_lastFetchedDisposals) {
      await fetchDisposals();
    }
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  // ---- قائمة الطلبات (Request List: تبويبَي Incoming / Archive) ----
  bool isLoadingList = false;
  String? listError;
  bool isListFromCache = false;
  bool _lastFetchedDisposals = false;
  List<Disposal> _disposals = [];

  List<Disposal> get disposals => _disposals;

  // ---- تفاصيل طلب واحد ----
  bool isLoadingDetails = false;
  String? detailsError;
  bool isDetailsFromCache = false;
  Disposal? currentDisposal;

  // ---- إنشاء طلب جديد (Destruction Request form) ----
  bool isSubmitting = false;
  String? submitError;
  String? submitSuccessMessage; // من body['message'] الحقيقي بعد النجاح

  // ============================================================
  // 1) جلب كل طلبات الإتلاف
  // ============================================================
  Future<void> fetchDisposals() async {
    _lastFetchedDisposals = true;
    isLoadingList = true;
    listError = null;
    notifyListeners();

    final result = await _disposalService.getDisposals();
    isLoadingList = false;

    if (result['success'] == true) {
      _disposals = DisposalsResponse.fromJson(result['data']).items;
      isListFromCache = false;
      notifyListeners();
      // نخزن نسخة محلية عشان تكون جاهزة لو انقطع النت (نفس نمط
      // OrderController._fetchTasksByCategory مع cached_tasks)
      await _localStorage.saveDisposals(result['data']);
      return;
    }

    // statusCode == null يعني فشل شبكة فعلي (بلا نت)، مش رفض من السيرفر
    final isNetworkFailure = result['statusCode'] == null;

    if (isNetworkFailure) {
      final cached = await _localStorage.getDisposals();
      if (cached != null) {
        _disposals = List.of(DisposalsResponse.fromJson(cached).items);

        // أي طلب إتلاف اتسجل محلياً أوفلاين ولسا بطابور المزامنة، منضيفه
        // فوق القائمة عشان يظهر فوراً (نفس مبدأ "locally completed tasks"
        // بـ OrderController)
        final pendingLocal = await _localPendingDisposals();
        _disposals = [...pendingLocal, ..._disposals];

        isListFromCache = true;
        listError = null;
        notifyListeners();
        return;
      }
    }

    listError = result['message']?.toString() ?? 'Failed to load disposal requests';
    notifyListeners();
  }

  // الطلبات المسجّلة محلياً أوفلاين ولسا بطابور المزامنة (نوع 'disposal')،
  // محوّلة لتمثيل مؤقت Disposal.pendingLocal حتى تظهر بالقائمة فوراً.
  Future<List<Disposal>> _localPendingDisposals() async {
    final ops = await _localStorage.getPendingOperations(status: 'pending');
    final pending = ops.where((op) => op['type'] == 'disposal');

    return pending.map((op) {
      final payload = op['payload'] as Map<String, dynamic>;
      return Disposal.pendingLocal(
        queueId: op['id'] as int,
        barcode: payload['barcode']?.toString() ?? '',
        quantity: (payload['quantity'] as num?)?.toInt() ?? 0,
        damageReason: payload['damage_reason']?.toString() ?? '',
        createdAt:
            DateTime.tryParse(op['created_at']?.toString() ?? '') ??
                DateTime.now(),
      );
    }).toList();
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
      // الشكل الحقيقي: {"damaged_product": {...}}
      final body = data is Map && data['damaged_product'] is Map
          ? Map<String, dynamic>.from(data['damaged_product'] as Map)
          : (data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{});
      currentDisposal = Disposal.fromJson(body);
      isDetailsFromCache = false;
      notifyListeners();
      // نخزن نسخة محلية لهاد الطلب بالذات عشان تنفتح أوفلاين لاحقاً
      await _localStorage.saveDisposalDetails(id, body);
      return true;
    }

    // statusCode == null يعني فشل شبكة فعلي (بلا نت)، مش رفض من السيرفر
    final isNetworkFailure = result['statusCode'] == null;

    if (isNetworkFailure) {
      final cached = await _localStorage.getDisposalDetails(id);
      if (cached != null) {
        currentDisposal = Disposal.fromJson(cached);
        isDetailsFromCache = true;
        detailsError = null;
        notifyListeners();
        return true;
      }
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
      final data = result['data'];
      submitSuccessMessage = data is Map
          ? data['message']?.toString()
          : null;
      notifyListeners();
      await fetchDisposals();
      return true;
    }

    final isNetworkFailure = result['statusCode'] == null;
    if (isNetworkFailure) {
      return _createDisposalOffline(
        barcode: barcode,
        quantity: quantity,
        damageReason: damageReason,
      );
    }

    submitError = result['message']?.toString() ?? 'Failed to submit disposal request';
    notifyListeners();
    return false;
  }

  // ============================================================
  // 3-ب) إنشاء طلب إتلاف أوفلاين — بنسجله بطابور المزامنة، وبنضيف
  // تمثيل مؤقت له فوق القائمة الحالية فورًا (نفس منطق
  // OrderController._completeTaskOffline: نرجع true ونعامله متل نجاح
  // عادي، والـ UI بتكمل نفس مسارها المعتاد بعد نجاح).
  // ============================================================
  Future<bool> _createDisposalOffline({
    required String barcode,
    required int quantity,
    required String damageReason,
  }) async {
    final queueId = await _localStorage.addPendingOperation(
      type: 'disposal',
      payload: {
        'barcode': barcode,
        'quantity': quantity,
        'damage_reason': damageReason,
      },
    );

    final createdAt = DateTime.now();
    _disposals = [
      Disposal.pendingLocal(
        queueId: queueId,
        barcode: barcode,
        quantity: quantity,
        damageReason: damageReason,
        createdAt: createdAt,
      ),
      ..._disposals,
    ];

    submitError = null;
    notifyListeners();
    return true;
  }

  void clearCurrentDisposal() {
    currentDisposal = null;
    detailsError = null;
    isDetailsFromCache = false;
  }
}