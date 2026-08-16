// lib/controllers/order_controller.dart
//
// مزود الحالة (State Management) الخاص بمهام العامل (Tasks).
// يُغلّف TaskService ويُعرف الواجهات على حالة المهام فقط (لا تتعامل
// الواجهات مع Dio مباشرة) — نفس فلسفة AuthProvider بالضبط.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stock_app/models/order_model.dart';
import 'package:stock_app/services/task_service.dart';
import 'package:stock_app/services/local_storage_service.dart';
import 'package:stock_app/services/connectivity_service.dart';
import 'package:stock_app/services/sync_service.dart';

class OrderController extends ChangeNotifier {
  final TaskService _taskService = TaskService();
  final LocalStorageService _localStorage = LocalStorageService();
  final SyncService _syncService = SyncService();
  StreamSubscription<bool>? _connectivitySub;

  // ---- حالة "بلا نت" (خاصة بمهام التحضير فقط حالياً) ----
  bool isDetailsFromCache = false;
  bool isListFromCache = false;
  String? _lastFetchedCategory;

  // إذا كانت شاشة التفاصيل المفتوحة حاليًا هي "Order preparation" (تجيب
  // بياناتها من /workers/orders/{orderId} وليس /workers/tasks/{taskId})،
  // نخزّن الـ orderId هون عشان إعادة الجلب بعد رجوع النت (_onReconnected).
  int? _currentOrderId;

  // نفس المبدأ بالظبط لكن لمهمة "استلام شحنة" (تجيب بياناتها من
  // /workers/shipments/{shipmentId} وليس /workers/tasks/{taskId}).
  int? _currentShipmentId;

  // نفس المبدأ بالظبط لكن لمهمة "مرتجع" (تجيب بياناتها من
  // /workers/returns/{returnId} وليس /workers/tasks/{taskId}).
  int? _currentReturnId;

  OrderController() {
    // لما يرجع النت: بنبعت كل العمليات المعلّقة، وبعدين بنحدّث الشاشة
    // المفتوحة حالياً (تفاصيل مهمة أو قائمة) عشان "يكمل شغلو طبيعي"
    _connectivitySub = ConnectivityService().onStatusChange.listen((isOnline) {
      if (isOnline) _onReconnected();
    });

    // مزامنة عند إقلاع التطبيق: onStatusChange بيبث بس عند *تغيّر* حالة
    // النت أثناء الجلسة الحالية. لو التطبيق انفتح وهو أونلاين من البداية
    // (بدون ما يصير قطع/وصل فعلي بهاي الجلسة)، أي عمليات معلّقة من جلسة
    // سابقة كانت رح تضل عالقة بالطابور لحد ما يصير تغيّر حقيقي بالنت.
    // هون منتحقق يدوياً عند الإقلاع ومنزامن فوراً لو لقينا نت.
    unawaited(_syncOnStartup());
  }

  Future<void> _syncOnStartup() async {
    final isOnline = await ConnectivityService().checkNow();
    if (isOnline) {
      await _syncService.syncPendingOperations();
    }
  }

  Future<void> _onReconnected() async {
    await _syncService.syncPendingOperations();

    if (currentTask != null) {
      if (_currentOrderId != null) {
        await fetchOrderPreparationDetails(currentTask!.task.id, _currentOrderId!);
      } else if (_currentShipmentId != null) {
        await fetchReceivingDetails(currentTask!.task.id, _currentShipmentId!);
      } else if (_currentReturnId != null) {
        await fetchReturnDetails(currentTask!.task.id, _currentReturnId!);
      } else {
        await fetchTaskDetails(currentTask!.task.id);
      }
    }
    if (_lastFetchedCategory != null) {
      await _fetchTasksByCategory(_lastFetchedCategory!);
    }
    if (_lastFetchedAllTasks) {
      await fetchAllTasks();
    }
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  // ---- قائمة المهام (PreparingScreen / ReceivingScreen) ----
  bool isLoadingList = false;
  String? listError;
  List<WorkerTask> pendingTasks = [];
  List<WorkerTask> completedTasks = [];

  // ---- قائمة "مهامي" الموحّدة — كل أنواع المهام مع بعض (MyTaskScreen) ----
  // منفصلة تمامًا عن pendingTasks/completedTasks فوق: هاي مستخدمة من شاشات
  // بتنفتح بالـ Navigator.push (توب فوق بعض بلحظة معينة)، بينما MyTaskScreen
  // موجودة دايمًا حية جوا IndexedStack بـ MainShell. لو استخدمنا نفس القوائم،
  // فتح أي شاشة تصنيف (Preparing/Receiving/...) كان رح يبهدل قائمة "مهامي".
  static const String _allTasksCacheKey = '__all__';
  bool isLoadingAllTasks = false;
  String? allTasksError;
  bool isAllTasksFromCache = false;
  List<WorkerTask> allPendingTasks = [];
  List<WorkerTask> allCompletedTasks = [];
  bool _lastFetchedAllTasks = false;

  // ---- تفاصيل مهمة واحدة (order_details / receiving_details) ----
  bool isLoadingDetails = false;
  String? detailsError;
  TaskDetail? currentTask;

  // ---- حالة المسح ----
  final Set<int> scanningProductIds = {};
  String? scanError;

  // ---- حالة تأكيد المهمة ----
  bool isCompleting = false;
  String? completeError;
  List<RemainingItem> remainingItems = [];

  // ============================================================
  // 1) جلب قائمة مهام "التحضير" — Order preparation
  // ============================================================
  Future<void> fetchOrderPreparationTasks() async {
    await _fetchTasksByCategory('Order preparation');
  }

  // ============================================================
  // 1-ب) جلب قائمة مهام "الاستلام" — Receiving a shipment
  // ============================================================
  Future<void> fetchReceivingTasks() async {
    await _fetchTasksByCategory('Receiving a shipment');
  }
  Future<void> fetchRecoveryTasks() async {
    await _fetchTasksByCategory('Returns');
  }

  // ============================================================
  // 1-ج) جلب قائمة مهام "الإتلاف" — Destruction (task_type: damage_disposal)
  // نفس آلية Recovery بالظبط، هاي فقط مهام الإتلاف المُسندة رسمياً للعامل
  // (مش طلبات الإتلاف الحرة اللي بيسويها العامل بنفسه من DestructionController)
  // ============================================================
  Future<void> fetchDestructionTasks() async {
    await _fetchTasksByCategory('Destruction');
  }

  // دالة عامة مشتركة يستخدمها Processing و Receiving و Recovery و Destruction
  // بدل تكرار نفس الكود بكل مرة
  Future<void> _fetchTasksByCategory(String category) async {
    _lastFetchedCategory = category;
    isLoadingList = true;
    listError = null;
    notifyListeners();

    final result = await _taskService.getTasks(category: category);

    isLoadingList = false;

    if (result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>;
      final parsed = WorkerTasksResponse.fromJson(data);
      pendingTasks = parsed.inPreparation;
      completedTasks = parsed.completed;
      isListFromCache = false;
      notifyListeners();
      // نخزن نسخة محلية عشان تكون جاهزة لو انقطع النت
      unawaited(_localStorage.saveTasks(category, data));
      return;
    }

    // statusCode == null يعني فشل شبكة فعلي (بلا نت)، مش رفض من السيرفر
    final isNetworkFailure = result['statusCode'] == null;

    if (isNetworkFailure) {
      final cached = await _localStorage.getTasks(category);
      if (cached != null) {
        final parsed = WorkerTasksResponse.fromJson(cached);
        pendingTasks = List.of(parsed.inPreparation);
        completedTasks = List.of(parsed.completed);

        // أي مهمة اتأكدت محلياً (أوفلاين) ولسا ما انزامنت، نرحّلها
        // لتبويب "Completed" حتى لو الكاش الأصلي لسا حاطها Pending
        final locallyCompletedIds = await _localCompletedTaskIds();
        if (locallyCompletedIds.isNotEmpty) {
          final movedOut = <WorkerTask>[];
          pendingTasks.removeWhere((t) {
            if (locallyCompletedIds.contains(t.id)) {
              movedOut.add(t);
              return true;
            }
            return false;
          });
          completedTasks.addAll(movedOut);
        }

        isListFromCache = true;
        listError = null;
        notifyListeners();
        return;
      }
    }

    listError = result['message']?.toString() ?? 'Failed to load tasks';
    notifyListeners();
  }

  // ============================================================
  // 1-د) "مهامي" — جلب كل المهام من كل الأنواع مع بعض (بلا فلترة category)
  // GET /workers/tasks بدون أي query params بترجع in_preparation/completed
  // شاملين كل task_type (order_preparation, shipment_receiving,
  // damage_disposal, return_pickup, restock_product...) بنفس الرد.
  // ============================================================
  Future<void> fetchAllTasks() async {
    _lastFetchedAllTasks = true;
    isLoadingAllTasks = true;
    allTasksError = null;
    notifyListeners();

    final result = await _taskService.getTasks();

    isLoadingAllTasks = false;

    if (result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>;
      final parsed = WorkerTasksResponse.fromJson(data);
      allPendingTasks = parsed.inPreparation;
      allCompletedTasks = parsed.completed;
      isAllTasksFromCache = false;
      notifyListeners();
      unawaited(_localStorage.saveTasks(_allTasksCacheKey, data));
      return;
    }

    final isNetworkFailure = result['statusCode'] == null;

    if (isNetworkFailure) {
      final cached = await _localStorage.getTasks(_allTasksCacheKey);
      if (cached != null) {
        final parsed = WorkerTasksResponse.fromJson(cached);
        allPendingTasks = List.of(parsed.inPreparation);
        allCompletedTasks = List.of(parsed.completed);

        final locallyCompletedIds = await _localCompletedTaskIds();
        if (locallyCompletedIds.isNotEmpty) {
          final movedOut = <WorkerTask>[];
          allPendingTasks.removeWhere((t) {
            if (locallyCompletedIds.contains(t.id)) {
              movedOut.add(t);
              return true;
            }
            return false;
          });
          allCompletedTasks.addAll(movedOut);
        }

        isAllTasksFromCache = true;
        allTasksError = null;
        notifyListeners();
        return;
      }
    }

    allTasksError = result['message']?.toString() ?? 'Failed to load tasks';
    notifyListeners();
  }

  // مجموعة الـ taskId يلي انأكدو محلياً (أوفلاين) ولسا بطابور المزامنة
  Future<Set<int>> _localCompletedTaskIds() async {
    final ops = await _localStorage.getPendingOperations(status: 'pending');
    return ops
        .where((op) => op['type'] == 'complete' && op['task_id'] != null)
        .map((op) => op['task_id'] as int)
        .toSet();
  }

  // ============================================================
  // 2) جلب تفاصيل مهمة واحدة
  // ============================================================
  Future<bool> fetchTaskDetails(int taskId) async {
    isLoadingDetails = true;
    detailsError = null;
    notifyListeners();

    final result = await _taskService.getTaskDetails(taskId);

    isLoadingDetails = false;

    if (result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>;
      currentTask = TaskDetail.fromJson(data);
      isDetailsFromCache = false;
      detailsError = null;
      await _applyPendingScansToCurrentTask(taskId);
      notifyListeners();
      unawaited(_localStorage.saveTaskDetails(taskId, data));
      return true;
    }

    final isNetworkFailure = result['statusCode'] == null;

    if (isNetworkFailure) {
      final cached = await _localStorage.getTaskDetails(taskId);
      if (cached != null) {
        currentTask = TaskDetail.fromJson(cached);
        isDetailsFromCache = true;
        detailsError = null;
        await _applyPendingScansToCurrentTask(taskId);
        notifyListeners();
        return true;
      }
    }

    detailsError = result['message']?.toString() ?? 'Failed to load task';
    notifyListeners();
    return false;
  }

  // ============================================================
  // 2-ب) تفاصيل مهمة "تحضير طلب" فقط — GET /workers/orders/{orderId}
  // taskId: يلزم لعمليات scan/complete لاحقًا (نفس شاشة order_details).
  // orderId: هو task.related_id من قائمة المهام (Order ID ≠ Task ID).
  // ============================================================
  Future<bool> fetchOrderPreparationDetails(int taskId, int orderId) async {
    _currentOrderId = orderId;
    isLoadingDetails = true;
    detailsError = null;
    notifyListeners();

    final result = await _taskService.getOrderDetails(orderId);

    isLoadingDetails = false;

    if (result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>;
      currentTask = TaskDetail.fromOrderJson(
        data,
        task: WorkerTask(id: taskId, relatedId: orderId),
      );
      isDetailsFromCache = false;
      detailsError = null;
      await _applyPendingScansToCurrentTask(taskId);
      notifyListeners();
      unawaited(_localStorage.saveTaskDetails(taskId, data));
      return true;
    }

    final isNetworkFailure = result['statusCode'] == null;

    if (isNetworkFailure) {
      final cached = await _localStorage.getTaskDetails(taskId);
      if (cached != null) {
        currentTask = TaskDetail.fromOrderJson(
          cached,
          task: WorkerTask(id: taskId, relatedId: orderId),
        );
        isDetailsFromCache = true;
        detailsError = null;
        await _applyPendingScansToCurrentTask(taskId);
        notifyListeners();
        return true;
      }
    }

    detailsError = result['message']?.toString() ?? 'Failed to load order';
    notifyListeners();
    return false;
  }

  // ============================================================
  // 2-ج) تفاصيل مهمة "استلام شحنة" فقط — GET /workers/shipments/{shipmentId}
  // taskId: يلزم لعمليات scan/complete لاحقًا (نفس شاشة receiving_details).
  // shipmentId: هو task.related_id من قائمة المهام (Shipment ID ≠ Task ID).
  // ============================================================
  Future<bool> fetchReceivingDetails(int taskId, int shipmentId) async {
    _currentShipmentId = shipmentId;
    isLoadingDetails = true;
    detailsError = null;
    notifyListeners();

    final result = await _taskService.getShipmentDetails(shipmentId);

    isLoadingDetails = false;

    if (result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>;
      currentTask = TaskDetail.fromShipmentJson(
        data,
        task: WorkerTask(id: taskId, relatedId: shipmentId),
      );
      isDetailsFromCache = false;
      detailsError = null;
      await _applyPendingScansToCurrentTask(taskId);
      notifyListeners();
      unawaited(_localStorage.saveTaskDetails(taskId, data));
      return true;
    }

    final isNetworkFailure = result['statusCode'] == null;

    if (isNetworkFailure) {
      final cached = await _localStorage.getTaskDetails(taskId);
      if (cached != null) {
        currentTask = TaskDetail.fromShipmentJson(
          cached,
          task: WorkerTask(id: taskId, relatedId: shipmentId),
        );
        isDetailsFromCache = true;
        detailsError = null;
        await _applyPendingScansToCurrentTask(taskId);
        notifyListeners();
        return true;
      }
    }

    detailsError = result['message']?.toString() ?? 'Failed to load shipment';
    notifyListeners();
    return false;
  }

  // ============================================================
  // 2-د) تفاصيل مهمة "مرتجع" فقط — GET /workers/returns/{returnId}
  // taskId: يلزم لعمليات scan/complete لاحقًا (نفس شاشة recovery_details).
  // returnId: هو task.related_id من قائمة المهام (Return ID ≠ Task ID).
  // ============================================================
  Future<bool> fetchReturnDetails(int taskId, int returnId) async {
    _currentReturnId = returnId;
    isLoadingDetails = true;
    detailsError = null;
    notifyListeners();

    final result = await _taskService.getReturnDetails(returnId);

    isLoadingDetails = false;

    if (result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>;
      currentTask = TaskDetail.fromReturnJson(
        data,
        task: WorkerTask(id: taskId, relatedId: returnId),
      );
      isDetailsFromCache = false;
      detailsError = null;
      await _applyPendingScansToCurrentTask(taskId);
      notifyListeners();
      unawaited(_localStorage.saveTaskDetails(taskId, data));
      return true;
    }

    final isNetworkFailure = result['statusCode'] == null;

    if (isNetworkFailure) {
      final cached = await _localStorage.getTaskDetails(taskId);
      if (cached != null) {
        currentTask = TaskDetail.fromReturnJson(
          cached,
          task: WorkerTask(id: taskId, relatedId: returnId),
        );
        isDetailsFromCache = true;
        detailsError = null;
        await _applyPendingScansToCurrentTask(taskId);
        notifyListeners();
        return true;
      }
    }

    detailsError = result['message']?.toString() ?? 'Failed to load return';
    notifyListeners();
    return false;
  }

  // يطبّق أي عمليات مسح (scan) محفوظة بطابور المزامنة لهاد الـ taskId
  // فوق currentTask.items، عشان الشاشة تعرض دايماً آخر حالة حقيقية
  // حتى لو السيرفر لسا ما بيعرف فيها (لسا ما انبعتت).
  Future<void> _applyPendingScansToCurrentTask(int taskId) async {
    if (currentTask == null) return;

    final ops = await _localStorage.getPendingOperations(status: 'pending');
    final pendingScans = ops.where(
      (op) => op['type'] == 'scan' && op['task_id'] == taskId,
    );

    for (final op in pendingScans) {
      final barcode = (op['payload'] as Map)['barcode']?.toString();
      if (barcode == null) continue;
      _incrementItemByBarcode(barcode);
    }
  }

  // يزيد pickedQty لمنتج واحد بمقدار قطعة (نفس منطق السيرفر: كل مسحة = قطعة)
  // بيرجع true إذا لقى تطابق فعلي وقدر يزيد، false إذا ما لقى أو المنتج مكتمل أصلاً
  bool _incrementItemByBarcode(String barcode) {
    if (currentTask == null) return false;
    final normalized = barcode.trim().toLowerCase();

    for (final item in currentTask!.items) {
      final itemBarcode = item.barcode?.trim().toLowerCase();
      if (itemBarcode != null && itemBarcode == normalized) {
        if (item.pickedQty < item.expectedQty) {
          item.pickedQty += 1;
        }
        return true;
      }
    }
    return false;
  }

  // ============================================================
  // 3) مسح باركود ضمن المهمة الحالية
  // ============================================================
  Future<ScanOutcome> scanBarcode(int taskId, String barcode) async {
    scanError = null;
    notifyListeners();

    final result = await _taskService.scanBarcode(taskId, barcode);

    if (result['success'] != true) {
      final isNetworkFailure = result['statusCode'] == null;
      if (isNetworkFailure) {
        return _scanBarcodeOffline(taskId, barcode);
      }
      scanError = result['message']?.toString() ?? 'Failed to scan barcode';
      notifyListeners();
      return ScanOutcome.error;
    }

    final data = result['data'] as Map<String, dynamic>;
    final scanResult = ScanResult.fromJson(data);

    if (scanResult.matched != true) {
      scanError = scanResult.warning ?? 'Product not found for this barcode';
      notifyListeners();
      return ScanOutcome.notMatched;
    }

    if (currentTask != null) {
      // الأولوية للمطابقة عبر product.id (دقيقة، وما بتأثر على منتجات
      // تانية بنفس المهمة). إذا الباك إند ما رجّع id للمنتج (نوع مهمة
      // تاني بعده على الشكل القديم)، نرجع للمطابقة بالاسم كـ fallback.
      final matchedProductId = scanResult.product?.id;
      bool updatedById = false;

      if (matchedProductId != null && matchedProductId != 0) {
        for (final item in currentTask!.items) {
          if (item.productId == matchedProductId) {
            if (scanResult.progress != null) {
              item.pickedQty = scanResult.progress!.scanned;
            } else {
              item.pickedQty =
                  (item.pickedQty + 1).clamp(0, item.expectedQty);
            }
            updatedById = true;
            break;
          }
        }
      }

      if (!updatedById) {
        for (final progressItem in scanResult.progressItems) {
          for (final item in currentTask!.items) {
            if (item.productName == progressItem.product) {
              item.pickedQty = progressItem.qty;
            }
          }
        }
      }
    }

    if (scanResult.warning != null) {
      scanError = scanResult.warning;
    }

    notifyListeners();
    return ScanOutcome.success;
  }

  // ============================================================
  // 3-ب) مسح باركود أوفلاين — مطابقة محلية على currentTask.items
  // (متوفرة أصلاً لأن الباركود بيجي مع تفاصيل المهمة)، ثم تسجيل
  // العملية بطابور المزامنة لحد ما يرجع النت.
  // ============================================================
  Future<ScanOutcome> _scanBarcodeOffline(int taskId, String barcode) async {
    if (currentTask == null) {
      scanError = 'No internet connection';
      notifyListeners();
      return ScanOutcome.error;
    }

    final normalized = barcode.trim().toLowerCase();
    TaskOrderItem? matchedItem;
    for (final item in currentTask!.items) {
      if (item.barcode?.trim().toLowerCase() == normalized) {
        matchedItem = item;
        break;
      }
    }

    if (matchedItem == null) {
      scanError = 'Product not found for this barcode';
      notifyListeners();
      return ScanOutcome.notMatched;
    }

    if (matchedItem.pickedQty >= matchedItem.expectedQty) {
      scanError = 'This item is already fully scanned';
      notifyListeners();
      return ScanOutcome.success;
    }

    matchedItem.pickedQty += 1;
    scanError = null;
    notifyListeners();

    await _localStorage.addPendingOperation(
      type: 'scan',
      taskId: taskId,
      payload: {'barcode': barcode},
    );

    return ScanOutcome.success;
  }

  // ============================================================
  // 4) تأكيد إكمال المهمة
  // ============================================================
  Future<bool> completeTask(int taskId) async {
    isCompleting = true;
    completeError = null;
    remainingItems = [];
    notifyListeners();

    final result = await _taskService.completeTask(taskId);

    isCompleting = false;

    if (result['success'] == true) {
      completeError = null;
      notifyListeners();
      return true;
    }

    final isNetworkFailure = result['statusCode'] == null;
    if (isNetworkFailure) {
      return _completeTaskOffline(taskId);
    }

    final data = result['data'];
    if (data is Map && data['remaining_items'] is List) {
      remainingItems = (data['remaining_items'] as List)
          .whereType<Map>()
          .map((e) => RemainingItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    completeError = result['message']?.toString() ?? 'Failed to complete task';
    notifyListeners();
    return false;
  }

  // ============================================================
  // 4-ب) إكمال المهمة أوفلاين — نتحقق محلياً إنه كل العناصر مكتملة
  // (نفس منطق task.allItemsComplete المستخدم أصلاً بالـ UI)، وإذا
  // تمام نسجل عملية "complete" بالطابور لحد ما يرجع النت.
  // ============================================================
  Future<bool> _completeTaskOffline(int taskId) async {
    if (currentTask == null) {
      completeError = 'No internet connection';
      notifyListeners();
      return false;
    }

    if (!currentTask!.allItemsComplete) {
      remainingItems = currentTask!.items
          .where((i) => !i.isComplete)
          .map(
            (i) => RemainingItem(
              productId: i.productId,
              product: i.productName,
              expected: i.expectedQty,
              scanned: i.pickedQty,
              remaining: i.remaining,
            ),
          )
          .toList();
      completeError = null;
      notifyListeners();
      return false;
    }

    // تجنّب تكرار تسجيل نفس عملية الإكمال أكتر من مرة
    final existingOps = await _localStorage.getPendingOperations(status: 'pending');
    final alreadyQueued = existingOps.any(
      (op) => op['type'] == 'complete' && op['task_id'] == taskId,
    );

    if (!alreadyQueued) {
      await _localStorage.addPendingOperation(
        type: 'complete',
        taskId: taskId,
        payload: {},
      );
    }

    completeError = null;
    notifyListeners();
    return true;
  }

  // ============================================================
  // تنظيف حالة تفاصيل المهمة عند مغادرة الشاشة
  // ============================================================
  void clearCurrentTask() {
    currentTask = null;
    detailsError = null;
    scanError = null;
    completeError = null;
    remainingItems = [];
    _currentOrderId = null;
    _currentShipmentId = null;
    _currentReturnId = null;
  }
}

enum ScanOutcome { success, notMatched, error }