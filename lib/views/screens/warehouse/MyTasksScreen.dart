// lib/views/screens/warehouse/MyTasksScreen.dart
//
// شاشة "مهامي" — مربوطة بالكامل مع الباك إند:
//   GET /workers/tasks   (بدون category ولا status)
// هاد الـ endpoint لما ينستدعى بلا فلترة بيرجع كل مهام العامل من كل
// الأنواع مع بعض (order_preparation, shipment_receiving, damage_disposal,
// return_pickup, restock_product...) مقسومين جاهزين لـ in_preparation/completed
// — تماماً متل شكل الشاشة (تبويب Pending وتبويب Completed).
//
// عند الضغط على أي كرت، منفتح شاشة التفاصيل الصحيحة حسب task_type (كل نوع
// إلو شاشة تفاصيل مختلفة أصلاً بالمشروع)، وبعد الرجوع منها منعيد الجلب
// عشان لو المهمة اكتملت تنتقل تبويب تلقائياً.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/order_controller.dart';
import '../../../models/order_model.dart';
import '../../../utils/constants.dart';
import '../../../views/widgets/auth_widgets.dart';
import 'destruction_task_details.dart';
import 'order_details.dart';
import 'receiving_details.dart';
import 'recovery_details.dart';

// MyTaskScreen لا يعرض الـ BottomNav بشكل مستقل —
// التنقل يتم من خلال MainShell الموجود في main_shell.dart
class MyTaskScreen extends StatefulWidget {
  const MyTaskScreen({super.key});

  @override
  State<MyTaskScreen> createState() => _MyTaskScreenState();
}

class _MyTaskScreenState extends State<MyTaskScreen> {
  bool isPendingSelected = true;

  @override
  void initState() {
    super.initState();
    // نجيب كل المهام (كل الأنواع مع بعض) فور فتح الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderController>().fetchAllTasks();
    });
  }

  void _openTask(OrderController controller, WorkerTask task) {
    void missingRef() {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This task is missing its reference id from the backend.',
          ),
        ),
      );
    }

    Widget? destination;

    switch (task.taskType) {
      case TaskType.damageDisposal:
        destination = DestructionTaskDetailsScreen(taskId: task.id);
        break;
      case TaskType.orderPreparation:
        if (task.relatedId == null) return missingRef();
        destination = OrderDetailsScreen(
          taskId: task.id,
          orderId: task.relatedId!,
          initialStatus: task.status,
        );
        break;
      case TaskType.shipmentReceiving:
        if (task.relatedId == null) return missingRef();
        destination = ReceivingDetailsScreen(
          taskId: task.id,
          shipmentId: task.relatedId!,
          initialStatus: task.status,
        );
        break;
      case TaskType.returnPickup:
      case TaskType.restockProduct:
        if (task.relatedId == null) return missingRef();
        destination = RecoveryDetailsScreen(
          taskId: task.id,
          returnId: task.relatedId!,
          initialStatus: task.status,
        );
        break;
      default:
        // orderDelivery / transferPreparation / transferDelivery: مهام
        // سائق، ما إلها شاشة تفاصيل بجانب العامل (warehouse) حالياً.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This task type is not supported here yet.'),
          ),
        );
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => destination!),
    ).then((_) {
      // بعد الرجوع من التفاصيل، حدّثي القائمة (ممكن تكون المهمة اكتملت
      // وانتقلت من تبويب لتاني)
      controller.fetchAllTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.beige,
      body: Column(
        children: [
          // 1. الهيدر
          ReceivingTopHeader(height: screenHeight * 0.22, title: 'My Tasks'),

          Transform.translate(
            offset: const Offset(0, -50),
            child: Column(
              children: [
                // 2. التبويب التفاعلي (Pending / Completed)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.navy.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildTabButton('Pending', true),
                        _buildTabButton('Completed', false),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. قائمة المهام
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -30),
              child: Consumer<OrderController>(
                builder: (context, controller, _) {
                  if (controller.isLoadingAllTasks) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (controller.allTasksError != null) {
                    return _ErrorState(
                      message: controller.allTasksError!,
                      onRetry: () => controller.fetchAllTasks(),
                    );
                  }

                  final tasks = isPendingSelected
                      ? controller.allPendingTasks
                      : controller.allCompletedTasks;

                  if (tasks.isEmpty) {
                    return Center(
                      child: Text(
                        isPendingSelected
                            ? 'No pending tasks'
                            : 'No completed tasks',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => controller.fetchAllTasks(),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return GestureDetector(
                          onTap: () => _openTask(controller, task),
                          child: _TaskCard(
                            task: task,
                            showPendingBadge: isPendingSelected,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, bool isPending) {
    bool isSelected = isPendingSelected == isPending;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => isPendingSelected = isPending),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF3EDE4) : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.navy,
              decoration: isSelected
                  ? TextDecoration.underline
                  : TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 15),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

// كرت المهمة — بيعرض عنوان المهمة (مع نوعها) والحالة وتاريخ الإنشاء،
// نفس نمط الكروت المستخدمة بشاشات Preparing/Receiving/Recovery.
class _TaskCard extends StatelessWidget {
  final WorkerTask task;
  final bool showPendingBadge;

  const _TaskCard({required this.task, required this.showPendingBadge});

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.navy.withOpacity(0.6), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 6,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task.displayTitle,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          if (task.assignedByName != null) ...[
            const SizedBox(height: 2),
            Text(
              'Assigned by ${task.assignedByName}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Created: ${_formatDate(task.createdAt)}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.black54,
                ),
              ),
              Text(
                showPendingBadge ? 'In preparation' : 'Completed',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: showPendingBadge
                      ? AppColors.orange
                      : AppColors.greenLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
