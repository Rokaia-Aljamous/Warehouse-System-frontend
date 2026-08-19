import 'package:flutter/material.dart';
import 'package:stock_app/controllers/driver_notification_controller.dart';
import 'package:stock_app/models/driver_notification_model.dart';
import 'package:stock_app/utils/constants.dart';
import 'package:stock_app/views/widgets/auth_header_widgets.dart';

class NotificationScreen extends StatelessWidget {
  final DriverNotificationController? driverController;

  const NotificationScreen({super.key, this.driverController});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.beige,
      body: Column(
        children: [
          ReceivingTopHeader(
            height: screenHeight * 0.22,
            title: 'Notification',
          ),
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -24),
              child: driverController == null
                  ? _legacyNotificationList()
                  : AnimatedBuilder(
                      animation: driverController!,
                      builder: (context, _) =>
                          _driverNotificationList(driverController!),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _driverNotificationList(DriverNotificationController controller) {
    if (controller.isLoading && controller.notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.error != null && controller.notifications.isEmpty) {
      return RefreshIndicator(
        onRefresh: controller.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 80),
          children: [Text(controller.error!, textAlign: TextAlign.center)],
        ),
      );
    }

    if (controller.notifications.isEmpty) {
      return RefreshIndicator(
        onRefresh: controller.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 80),
          children: const [
            Text(
              'No notifications yet',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textGrey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          if (controller.unreadNotifications.isNotEmpty) ...[
            const _SectionLabel(label: 'New'),
            const SizedBox(height: 8),
            ...controller.unreadNotifications.map(
              (notification) => _backendItem(notification, controller),
            ),
          ],
          if (controller.unreadNotifications.isNotEmpty &&
              controller.readNotifications.isNotEmpty)
            const SizedBox(height: 12),
          if (controller.readNotifications.isNotEmpty) ...[
            const _SectionLabel(label: 'Earlier'),
            const SizedBox(height: 8),
            ...controller.readNotifications.map(
              (notification) => _backendItem(notification, controller),
            ),
          ],
        ],
      ),
    );
  }

  Widget _backendItem(
    DriverNotification notification,
    DriverNotificationController controller,
  ) {
    final isRead = notification.isRead;
    return _NotificationItem(
      icon: isRead
          ? Icons.notifications_none_rounded
          : Icons.notifications_active_rounded,
      iconBgColor: isRead ? const Color(0xFFEEEEEE) : const Color(0xFFDCF5DC),
      iconColor: isRead ? const Color(0xFF9E9E9E) : const Color(0xFF2E7D32),
      message: notification.displayText,
      time: notification.relativeTime,
      isRead: isRead,
      onTap: isRead ? null : () => controller.markAsRead(notification),
    );
  }

  Widget _legacyNotificationList() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: const [
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
          message: 'New receiving task: Shipment from Supplier X has arrived.',
          time: '15m ago',
          isRead: false,
        ),
        SizedBox(height: 12),
        _SectionLabel(label: 'Earlier'),
        SizedBox(height: 8),
        _NotificationItem(
          icon: Icons.notifications_none_rounded,
          iconBgColor: Color(0xFFEEEEEE),
          iconColor: Color(0xFF9E9E9E),
          message: 'Storage task: Move 50 units of Product A to Zone B.',
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
          message: 'System alert: Inventory levels low for Item #5521.',
          time: 'Yesterday',
          isRead: true,
        ),
      ],
    );
  }
}

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

class _NotificationItem extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String message;
  final String time;
  final bool isRead;
  final VoidCallback? onTap;

  const _NotificationItem({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.message,
    required this.time,
    required this.isRead,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isRead
                        ? AppColors.textGrey.withValues(alpha: 0.4)
                        : AppColors.green,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
