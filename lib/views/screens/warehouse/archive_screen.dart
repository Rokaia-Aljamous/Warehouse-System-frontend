// lib/views/screens/warehouse/archive_tab_content.dart
//
// تبويب "Archive" بشاشة Request List = أرشيف شامل لكل شي إتلاف، من مصدرين:
//   1) طلبات العامل الحرة  -> DestructionController.disposals (GET /disposals)
//   2) مهام الأمين الرسمية -> OrderController tasks (GET /tasks?category=Destruction)
//
// كل الحقول المعروضة راجعة حرفياً من الباك (status، إلخ). حالة statusText
// ملوّنة حسب القيمة (approved/completed = أخضر، pending/in_preparation = أحمر).
// كل كرت قابل للضغط يفتح تفاصيله الحقيقية.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/destruction_controller.dart';
import '../../../controllers/order_controller.dart';
import '../../../models/order_model.dart';
import '../../../utils/constants.dart';
import 'disposal_details_screen.dart';
import 'destruction_task_details.dart';

class ArchiveTabContent extends StatelessWidget {
  const ArchiveTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<DestructionController, OrderController>(
      builder: (context, destructionController, orderController, _) {
        final isLoading = (destructionController.isLoadingList &&
                destructionController.disposals.isEmpty) ||
            (orderController.isLoadingList &&
                orderController.pendingTasks.isEmpty &&
                orderController.completedTasks.isEmpty);

        if (isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // الأرشيف = بس الطلبات الحرة يلي توافق عليها الأدمن (status: approved).
        // يلي لسا Pending (ما توافق عليه بعد) بتضل بتبويب "Request List" بس،
        // حتى ما تتكرر أو تظهر كأنها منجزة قبل ما تصير فعلاً.
        final disposals = destructionController.disposals
            .where((d) => d.status == 'approved')
            .toList();
        // الأرشيف = مهام الإتلاف الرسمية يلي *خلصت* فقط (status: completed).
        // يلي لسا شغالة عليها (in_preparation) بتضل بتبويب Incoming بس.
        final tasks = orderController.completedTasks;

        if (disposals.isEmpty && tasks.isEmpty) {
          return const Center(
            child: Text(
              'Archive is empty',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                color: Colors.black54,
              ),
            ),
          );
        }

        Future<void> refresh() async {
          await Future.wait([
            destructionController.fetchDisposals(),
            orderController.fetchDestructionTasks(),
          ]);
        }

        return RefreshIndicator(
          onRefresh: refresh,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            children: [
              // ---- طلبات العامل الحرة (My Order) ----
              ...disposals.map(
                (d) => GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          DisposalDetailsScreen(disposalId: d.id),
                    ),
                  ),
                  child: _ArchiveCard(
                    statusText: d.status ?? '-',
                    lines: [
                      d.displayTitle,
                      'Qty: ${d.quantity} Units',
                      if (d.damageReason != null) d.damageReason!,
                    ],
                    originLabel: 'My Order',
                  ),
                ),
              ),
              // ---- مهام الأمين الرسمية (Admin) ----
              ...tasks.map(
                (t) => GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          DestructionTaskDetailsScreen(taskId: t.id),
                    ),
                  ).then((_) => orderController.fetchDestructionTasks()),
                  child: _ArchiveCard(
                    statusText: t.status?.value ?? '-',
                    lines: [
                      t.displayTitle,
                      'Destroyed: ${t.disposalScannedQuantity} / ${t.disposalQuantity}',
                      if (t.assignedByName != null)
                        'Assigned by: ${t.assignedByName}',
                    ],
                    originLabel: 'Admin',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ArchiveCard extends StatelessWidget {
  final String statusText; // raw status/relatedStatus متل ما إجا من الباك
  final List<String> lines;
  final String originLabel; // 'My Order' or 'Admin'

  const _ArchiveCard({
    required this.statusText,
    required this.lines,
    required this.originLabel,
  });

  // أخضر لـ approved/completed، أحمر لـ pending، رمادي لأي قيمة تانية
  Color get _statusColor {
    switch (statusText) {
      case 'approved':
      case 'completed':
        return const Color(0xFF2E7D32);
      case 'pending':
      case 'in_preparation':
        return const Color(0xFFD32F2F);
      default:
        return AppColors.navy;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.navy.withOpacity(0.3), width: 1),
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
          Text(
            statusText,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _statusColor,
            ),
          ),
          const SizedBox(height: 8),
          ...lines.map((l) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text(
                  l,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              )),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              originLabel,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: originLabel == 'Admin'
                    ? AppColors.orange
                    : AppColors.navy,
              ),
            ),
          ),
        ],
      ),
    );
  }
}