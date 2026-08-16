// lib/views/screens/warehouse/PreparingScreen.dart
//
// شاشة "Processing" (Order preparation) — مربوطة بالكامل مع الباك إند:
//   GET /workers/tasks?category=Order preparation
// وتفرزهم تلقائياً بين "Pending" (in_preparation) و "Completed".

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/order_controller.dart';
import '../../../models/order_model.dart';
import '../../../utils/constants.dart';
import '../../../views/widgets/auth_widgets.dart';
import 'order_details.dart';

class PreparingScreen extends StatefulWidget {
  const PreparingScreen({super.key});

  @override
  State<PreparingScreen> createState() => _PreparingScreenState();
}

class _PreparingScreenState extends State<PreparingScreen> {
  bool isPendingSelected = true;

  @override
  void initState() {
    super.initState();
    // نجيب القائمة فور فتح الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderController>().fetchOrderPreparationTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.beige,
      body: Column(
        children: [
          ReceivingTopHeader(height: screenHeight * 0.22, title: 'Preparation'),

          Transform.translate(
            offset: const Offset(0, -50),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.greyLine.withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => isPendingSelected = true),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isPendingSelected
                                    ? const Color(0xFFF3EDE4)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Pending',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.navy,
                                  decoration: isPendingSelected
                                      ? TextDecoration.underline
                                      : TextDecoration.none,
                                  decorationColor: AppColors.navy,
                                  decorationThickness: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => isPendingSelected = false),
                            child: Container(
                              decoration: BoxDecoration(
                                color: !isPendingSelected
                                    ? const Color(0xFFF3EDE4)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Completed',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.navy,
                                  decoration: !isPendingSelected
                                      ? TextDecoration.underline
                                      : TextDecoration.none,
                                  decorationColor: AppColors.navy,
                                  decorationThickness: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: Divider(color: Colors.black12, thickness: 1),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -50),
              child: Consumer<OrderController>(
                builder: (context, controller, _) {
                  if (controller.isLoadingList) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (controller.listError != null) {
                    return _ErrorState(
                      message: controller.listError!,
                      onRetry: () =>
                          controller.fetchOrderPreparationTasks(),
                    );
                  }

                  final tasks = isPendingSelected
                      ? controller.pendingTasks
                      : controller.completedTasks;

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
                    onRefresh: () => controller.fetchOrderPreparationTasks(),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 0,
                      ),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return GestureDetector(
                          onTap: () {
                            // task.relatedId = Order ID (لا يساوي بالضرورة
                            // task.id). لو لأي سبب غير موجود، منمنع الدخول
                            // بدل ما نفترض إنه نفس Task ID.
                            if (task.relatedId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'This task is missing its order reference from the backend.',
                                  ),
                                ),
                              );
                              return;
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OrderDetailsScreen(
                                  taskId: task.id,
                                  orderId: task.relatedId!,
                                ),
                              ),
                            ).then((_) {
                              // بعد الرجوع من التفاصيل، حدّثي القائمة (ممكن
                              // تكون المهمة اكتملت وانتقلت من تبويب لتاني)
                              controller.fetchOrderPreparationTasks();
                            });
                          },
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

// ============================================================
// كرت المهمة — بيعرض كل شي متوفر فعلياً من الباك إند بقائمة المهام
// (اسم الزبون وعدد المنتجات مش متوفرين بهاد الـ endpoint، فبيظهروا فقط
// بشاشة التفاصيل بعد الضغط على الكارد)
// ============================================================
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
              fontSize: 26,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 2),
          if (task.relatedStatus != null)
            Text(
              task.relatedStatus!,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: Colors.black87,
              ),
            ),
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
