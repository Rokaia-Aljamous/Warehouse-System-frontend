// lib/controllers/order_controller.dart
//
// مزود الحالة (State Management) الخاص بمهام العامل (Tasks).
// يُغلّف TaskService ويُعرف الواجهات على حالة المهام فقط (لا تتعامل
// الواجهات مع Dio مباشرة) — نفس فلسفة AuthProvider بالضبط.

import 'package:flutter/material.dart';
import 'package:stock_app/models/order_model.dart';
import 'package:stock_app/services/task_service.dart';

class OrderController extends ChangeNotifier {
  final TaskService _taskService = TaskService();

  // ---- قائمة المهام (PreparingScreen / ReceivingScreen) ----
  bool isLoadingList = false;
  String? listError;
  List<WorkerTask> pendingTasks = [];
  List<WorkerTask> completedTasks = [];

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
      notifyListeners();
      return;
    }

    listError = result['message']?.toString() ?? 'Failed to load tasks';
    notifyListeners();
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
      detailsError = null;
      notifyListeners();
      return true;
    }

    detailsError = result['message']?.toString() ?? 'Failed to load task';
    notifyListeners();
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
      for (final progressItem in scanResult.progressItems) {
        for (final item in currentTask!.items) {
          if (item.productName == progressItem.product) {
            item.pickedQty = progressItem.qty;
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
  // تنظيف حالة تفاصيل المهمة عند مغادرة الشاشة
  // ============================================================
  void clearCurrentTask() {
    currentTask = null;
    detailsError = null;
    scanError = null;
    completeError = null;
    remainingItems = [];
  }
}

enum ScanOutcome { success, notMatched, error }