// lib/views/screens/warehouse/incoming_tab_content.dart
//
// تبويب "Incoming" بشاشة Request List = مهام الإتلاف الرسمية الجاية من
// الأمين (secretary) والمُسندة للعامل لتنفيذها فعلياً — مو طلبات الإتلاف
// الحرة يلي العامل نفسه بيبعتها من تبويب "Request List".
//
//   GET /workers/tasks?category=Destruction   (عبر OrderController.pendingTasks)
//
// زر "Execution" بيفتح شاشة الـ scan/complete الحقيقية
// (destruction_task_details.dart) يلي بتنادي:
//   GET  /workers/tasks/{id}
//   POST /workers/tasks/{id}/scan
//   POST /workers/tasks/{id}/complete

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/order_controller.dart';
import '../../../models/order_model.dart';
import '../../../utils/constants.dart';
import 'destruction_task_details.dart';

class IncomingTabContent extends StatelessWidget {
  const IncomingTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderController>(
      builder: (context, controller, _) {
        if (controller.isLoadingList && controller.pendingTasks.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.listError != null && controller.pendingTasks.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.redAccent, size: 36),
                  const SizedBox(height: 12),
                  Text(controller.listError!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => controller.fetchDestructionTasks(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final tasks = controller.pendingTasks;

        if (tasks.isEmpty) {
          return const Center(
            child: Text(
              'No incoming destruction orders',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                color: Colors.black54,
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.fetchDestructionTasks(),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final WorkerTask task = tasks[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.navy.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Destruction Order',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildRow(Icons.inventory_2_outlined, task.displayTitle),
                    if (task.relatedStatus != null)
                      _buildRow(Icons.info_outline, task.relatedStatus!),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: 120,
                        height: 36,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFBBF7D0),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: Colors.green.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    DestructionTaskDetailsScreen(
                                        taskId: task.id),
                              ),
                            ).then((_) => controller.fetchDestructionTasks());
                          },
                          child: const Text(
                            'Execution',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.navy,
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
        );
      },
    );
  }

  Widget _buildRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.black54),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}