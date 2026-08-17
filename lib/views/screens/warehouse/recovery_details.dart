// lib/views/screens/warehouse/recovery_details.dart
//
// شاشة تفاصيل مهمة مرتجع (Return) - مربوطة بالكامل:
//   GET  /workers/returns/{returnId}      (تحميل التفاصيل — returnId = task.related_id)
//   POST /workers/tasks/{taskId}/scan     (مسح كل منتج بكاميرا الموبايل — taskId)
//   POST /workers/tasks/{taskId}/complete (تأكيد المهمة — taskId)
//
// مهم: Task ID ≠ Return ID. الـ scan/complete بتستخدم Task ID دايمًا،
// وتحميل التفاصيل بيستخدم Return ID (task.related_id) دايمًا.
//
// ⚠️ ملاحظة: الباك إند ما بيرجع اسم الزبون لمهام المرتجع (فقط لـ Order)،
// فبالكارد العلوي هون بنعرض "سبب الإرجاع" ورقم الطلب الأصلي بدل اسم الزبون.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/order_controller.dart';
import '../../../models/order_model.dart';
import '../../../utils/constants.dart';
import '../../../views/widgets/auth_widgets.dart';
import '../../../views/widgets/barcode_scanner_sheet.dart';
import '../../../views/widgets/section_scan_card.dart';

class RecoveryDetailsScreen extends StatefulWidget {
  final int taskId;
  final int returnId;
  // حالة التاسك الحقيقية (WorkerTask.status) — جاية من شاشة قائمة المهام
  // (Recovery). لازم تنمرر لأنه GET /workers/returns/{returnId} ما بيرجّع
  // حالة التاسك نفسه أبدًا (بيرجّع بس حالة الـ Return)، فبدون هاد
  // الباراميتر isCompleted بتضل false دايمًا حتى لو المهمة completed
  // فعليًا بالسيرفر.
  final TaskStatus? initialStatus;
  const RecoveryDetailsScreen({
    super.key,
    required this.taskId,
    required this.returnId,
    this.initialStatus,
  });

  @override
  State<RecoveryDetailsScreen> createState() => _RecoveryDetailsScreenState();
}

class _RecoveryDetailsScreenState extends State<RecoveryDetailsScreen> {
  // نفس مبدأ receiving_details.dart بالظبط: نخزّن مرجع الـ controller من
  // initState ونستخدمه بـ dispose() لتفادي FlutterError (deactivated widget's
  // ancestor lookup) اللي بيصير لو استخدمنا context.read() جوا dispose() مباشرة.
  late final OrderController _orderController;

  @override
  void initState() {
    super.initState();
    _orderController = context.read<OrderController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _orderController.fetchReturnDetails(
        widget.taskId,
        widget.returnId,
        knownStatus: widget.initialStatus,
      );
    });
  }

  @override
  void dispose() {
    _orderController.clearCurrentTask();
    super.dispose();
  }

  Future<void> _handleScan(TaskOrderItem item) async {
    final controller = context.read<OrderController>();

    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );

    if (barcode == null || !mounted) return;

    final outcome = await controller.scanBarcode(widget.taskId, barcode);

    if (!mounted) return;

    if (outcome == ScanOutcome.success) {
      if (controller.scanError != null) {
        _showSnack(controller.scanError!, isError: false);
      }
    } else {
      _showSnack(
        controller.scanError ?? 'Failed to scan barcode',
        isError: true,
      );
    }
  }

  void _showSnack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : AppColors.navy,
      ),
    );
  }

  Future<void> _handleScanSection() async {
    final controller = context.read<OrderController>();

    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );

    if (barcode == null || !mounted) return;

    final outcome = await controller.scanSectionBarcode(widget.taskId, barcode);

    if (!mounted) return;

    if (outcome != ScanOutcome.success) {
      _showSnack(
        controller.sectionScanError ?? 'Failed to scan section',
        isError: true,
      );
    }
  }

  Future<void> _handleComplete() async {
    final controller = context.read<OrderController>();
    final success = await controller.completeTask(widget.taskId);

    if (!mounted) return;

    if (success) {
      _showCompletedBottomSheet();
      return;
    }

    if (controller.remainingItems.isNotEmpty) {
      _showRemainingItemsDialog(controller.remainingItems);
    } else {
      _showSnack(
        controller.completeError ?? 'Failed to complete task',
        isError: true,
      );
    }
  }

  void _showRemainingItemsDialog(List<RemainingItem> items) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Some items are not fully scanned'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: items
                .map(
                  (i) => ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.orange,
                    ),
                    title: Text(i.product),
                    subtitle: Text('${i.scanned} of ${i.expected} scanned'),
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showCompletedBottomSheet() {
    final screenHeight = MediaQuery.of(context).size.height;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (context) {
        return Container(
          width: double.infinity,
          height: screenHeight * 0.38,
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.3,
              colors: [Colors.white, Color(0xFFE3E4E8), Color(0xFF8E94A0)],
              stops: [0.0, 0.6, 1.0],
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(55),
              topRight: Radius.circular(55),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 20,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: InkWell(
            onTap: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Confirmed',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 40,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4CAF50),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 20),
                Icon(
                  Icons.verified_outlined,
                  size: 58,
                  color: AppColors.navy.withOpacity(0.9),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.beige,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReceivingTopHeader(
            height: screenHeight * 0.22,
            title: 'Return Details',
          ),
          Expanded(
            child: Consumer<OrderController>(
              builder: (context, controller, _) {
                if (controller.isLoadingDetails &&
                    controller.currentTask == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.detailsError != null &&
                    controller.currentTask == null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.redAccent,
                            size: 40,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            controller.detailsError!,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => controller.fetchReturnDetails(
                              widget.taskId,
                              widget.returnId,
                              knownStatus: widget.initialStatus,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final task = controller.currentTask;
                if (task == null) return const SizedBox.shrink();

                final allScanned = task.allItemsComplete;
                // المهمة completed أصلاً (فُتحت من الأرشيف مثلاً) —
                // عرض فقط: القسم وكل المنتجات خضراء ومقفولة عن التعديل.
                final isTaskCompleted = task.isCompleted;

                return Transform.translate(
                  offset: const Offset(0, -40),
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _InfoCard(task: task, taskId: widget.taskId),
                              const SizedBox(height: 24),
                              SectionScanCard(
                                activeSectionName: controller.activeSection?.name,
                                onScan: _handleScanSection,
                                isReadOnly: isTaskCompleted,
                              ),
                              const Padding(
                                padding: EdgeInsets.only(left: 8.0),
                                child: Text(
                                  'ITEMS TO RESTOCK',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black54,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...task.items.map(
                                (item) => _ProductScanCard(
                                  item: item,
                                  onScan: () => _handleScan(item),
                                  isLocked: !controller.isItemUnlocked(item),
                                  isReadOnly: isTaskCompleted,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24.0, top: 8.0),
                        child: Center(
                          child: GestureDetector(
                            onTap: (!isTaskCompleted &&
                                    allScanned &&
                                    !controller.isCompleting)
                                ? _handleComplete
                                : null,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: (allScanned || isTaskCompleted) ? 180 : 160,
                              height: 50,
                              decoration: BoxDecoration(
                                color: (allScanned || isTaskCompleted)
                                    ? const Color(0xFFBBF7D0)
                                    : AppColors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.navy.withOpacity(0.3),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: controller.isCompleting
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          isTaskCompleted ? 'Completed' : 'Confirm',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: (allScanned || isTaskCompleted)
                                                ? const Color(0xFF2E7D32)
                                                : AppColors.navy,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          (allScanned || isTaskCompleted)
                                              ? Icons.check_circle_outline
                                              : Icons.verified_outlined,
                                          color: AppColors.navy,
                                          size: 22,
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// كرت معلومات المرتجع الأساسية (يختفي فور اكتمال مسح كل المنتجات)
// بيعرض سبب الإرجاع + نوعه + رقم الطلب الأصلي (اسم الزبون مش متوفر
// بالباك إند لهاد النوع من المهام)
// ============================================================
class _InfoCard extends StatelessWidget {
  final TaskDetail task;
  final int taskId;
  const _InfoCard({required this.task, required this.taskId});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.navy.withOpacity(0.6), width: 1.0),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.assignment_return_outlined,
                color: AppColors.navy.withOpacity(0.7),
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  task.returnReason ?? 'Return',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.black87,
                  ),
                ),
              ),
              Text(
                '#$taskId',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                color: AppColors.navy.withOpacity(0.7),
                size: 24,
              ),
              const SizedBox(width: 16),
              Text(
                task.relatedOrderId != null
                    ? 'Original Order #${task.relatedOrderId}'
                    : 'Original order not linked',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                color: AppColors.navy.withOpacity(0.7),
                size: 24,
              ),
              const SizedBox(width: 16),
              Text(
                '${task.items.length} products'
                '${task.returnType != null ? ' • ${task.returnType}' : ''}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// كرت المنتج التفاعلي - سكان بكاميرا الموبايل فعلياً + 3 حالات لونية
// ============================================================
class _ProductScanCard extends StatelessWidget {
  final TaskOrderItem item;
  final VoidCallback onScan;
  final bool isLocked;
  // لما المهمة تكون completed أصلاً، كل منتج لازم يظهر أخضر (تم) دايمًا
  // وما يظل مقفول (رمادي)، بس ممنوع تعديله — عرض فقط.
  final bool isReadOnly;

  const _ProductScanCard({
    required this.item,
    required this.onScan,
    this.isLocked = false,
    this.isReadOnly = false,
  });

  Color _bgColorFor(ItemScanState state) {
    switch (state) {
      case ItemScanState.pending:
        return AppColors.red.withOpacity(0.15);
      case ItemScanState.partial:
        return AppColors.orange.withOpacity(0.25);
      case ItemScanState.done:
        return const Color(0xFFBBF7D0);
    }
  }

  Color _iconColorFor(ItemScanState state) {
    switch (state) {
      case ItemScanState.pending:
        return AppColors.red;
      case ItemScanState.partial:
        return AppColors.orange;
      case ItemScanState.done:
        return AppColors.navy;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = isReadOnly ? ItemScanState.done : item.scanState;
    final isDone = state == ItemScanState.done;
    // بوضع العرض فقط ما منقفل الكرت (رمادي) أبداً — لازم يظهر أخضر "تم"
    // بدل رمادي "مقفول"، بس onTap تحت بيضل معطّل لأنه isDone صار true.
    final locked = isReadOnly ? false : isLocked;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: locked ? Colors.grey.shade200 : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black26, width: 1.0),
      ),
      padding: const EdgeInsets.all(16),
      child: Opacity(
        opacity: locked ? 0.5 : 1.0,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.layers_outlined,
                        size: 18,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Restocked: ${item.pickedQty} / ${item.expectedQty}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  if (item.brand != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.sell_outlined,
                          size: 18,
                          color: Colors.black54,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item.brand!,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            GestureDetector(
              onTap: (isDone || locked) ? null : onScan,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: locked ? Colors.grey.shade300 : _bgColorFor(state),
                  borderRadius: BorderRadius.circular(12),
                  border: isDone
                      ? Border.all(
                          color: const Color(0xFF4CAF50).withOpacity(0.5),
                          width: 1.5,
                        )
                      : null,
                ),
                child: Icon(
                  locked
                      ? Icons.lock_outline_rounded
                      : (isDone
                          ? Icons.check_circle_outline_rounded
                          : Icons.qr_code_scanner_rounded),
                  color: locked ? Colors.black45 : _iconColorFor(state),
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
