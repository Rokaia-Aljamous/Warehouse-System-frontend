import 'package:flutter/material.dart';
import 'package:stock_app/models/driver_task_model.dart';
import 'package:stock_app/utils/constants.dart';

class DriverTaskCard extends StatelessWidget {
  static const Color iconGold = Color(0xFFF3A523);

  final DriverTask task;
  final VoidCallback onTap;

  const DriverTaskCard({super.key, required this.task, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.navy.withValues(alpha: 0.18)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _InfoLine(
                      icon: task.type == DriverTaskType.transferDelivery
                          ? Icons.warehouse_outlined
                          : Icons.person_outline,
                      text: task.displayName,
                      isTitle: true,
                    ),
                  ),
                  _StatusBadge(isCompleted: task.isCompleted),
                ],
              ),
              const SizedBox(height: 12),
              _InfoLine(icon: Icons.assignment_outlined, text: task.typeLabel),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isTitle;

  const _InfoLine({
    required this.icon,
    required this.text,
    this.isTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: DriverTaskCard.iconGold, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: AppColors.navy,
              height: 1.3,
            ).copyWith(fontWeight: isTitle ? FontWeight.w700 : FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isCompleted;

  const _StatusBadge({required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    final color = isCompleted ? AppColors.greenLight : DriverTaskCard.iconGold;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isCompleted ? 'Completed' : 'Pending',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
