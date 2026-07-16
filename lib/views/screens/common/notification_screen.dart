// lib/views/screens/common/notification_screen.dart

import 'package:flutter/material.dart';
import 'package:stock_app/utils/constants.dart';
import 'package:stock_app/views/widgets/auth_header_widgets.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.beige,
      body: Column(
        children: [
          // ===== الهيدر المائل المشترك =====
          ReceivingTopHeader(
            height: screenHeight * 0.22,
            title: 'Notification',
          ),

          // ===== قائمة الإشعارات =====
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -24),
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                children: const [
                  // ---- قسم New ----
                  _SectionLabel(label: 'New'),
                  SizedBox(height: 8),
                  _NotificationItem(
                    icon: Icons.notifications_active_rounded,
                    iconBgColor: Color(0xFFDCF5DC),
                    iconColor: Color(0xFF2E7D32),
                    message:
                        'Destruction task assigned: Order #1234 requires processing.',
                    time: '2m ago',
                    isRead: false,
                  ),
                  _NotificationItem(
                    icon: Icons.notifications_active_rounded,
                    iconBgColor: Color(0xFFDCF5DC),
                    iconColor: Color(0xFF2E7D32),
                    message:
                        'New receiving task: Shipment from Supplier X has arrived.',
                    time: '15m ago',
                    isRead: false,
                  ),

                  SizedBox(height: 12),

                  // ---- قسم Earlier ----
                  _SectionLabel(label: 'Earlier'),
                  SizedBox(height: 8),
                  _NotificationItem(
                    icon: Icons.notifications_none_rounded,
                    iconBgColor: Color(0xFFEEEEEE),
                    iconColor: Color(0xFF9E9E9E),
                    message:
                        'Storage task: Move 50 units of Product A to Zone B.',
                    time: '2h ago',
                    isRead: true,
                  ),
                  _NotificationItem(
                    icon: Icons.notifications_none_rounded,
                    iconBgColor: Color(0xFFEEEEEE),
                    iconColor: Color(0xFF9E9E9E),
                    message: 'Inventory check required for Section 4.',
                    time: '5h ago',
                    isRead: true,
                  ),
                  _NotificationItem(
                    icon: Icons.notifications_none_rounded,
                    iconBgColor: Color(0xFFEEEEEE),
                    iconColor: Color(0xFF9E9E9E),
                    message:
                        'System alert: Inventory levels low for Item #5521.',
                    time: 'Yesterday',
                    isRead: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// عنوان القسم (New / Earlier)
// ============================================================
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textGrey,
      ),
    );
  }
}

// ============================================================
// كرت الإشعار الواحد
// ============================================================
class _NotificationItem extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String message;
  final String time;
  final bool isRead;

  const _NotificationItem({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.message,
    required this.time,
    required this.isRead,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- أيقونة الإشعار ----
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),

          // ---- نص الإشعار + الوقت ----
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: isRead ? FontWeight.w400 : FontWeight.w600,
                    color: AppColors.navy,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // ---- نقطة الحالة (مقروء / غير مقروء) ----
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isRead
                    ? AppColors.textGrey.withOpacity(0.4)
                    : AppColors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
