class DriverNotification {
  final int id;
  final String title;
  final String message;
  final String type;
  final Map<String, dynamic> data;
  final int? referenceId;
  final DateTime? readAt;
  final DateTime? createdAt;

  const DriverNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.data,
    this.referenceId,
    this.readAt,
    this.createdAt,
  });

  factory DriverNotification.fromJson(Map<String, dynamic> json) {
    return DriverNotification(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? 'Notification',
      message: json['message']?.toString() ?? '',
      type: (json['notification_type'] ?? json['type'])?.toString() ?? '',
      data: json['data'] is Map
          ? Map<String, dynamic>.from(json['data'] as Map)
          : const {},
      referenceId: (json['reference_id'] as num?)?.toInt(),
      readAt: DateTime.tryParse(json['read_at']?.toString() ?? ''),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }

  bool get isRead => readAt != null;

  DriverNotification markRead([DateTime? at]) {
    return DriverNotification(
      id: id,
      title: title,
      message: message,
      type: type,
      data: data,
      referenceId: referenceId,
      readAt: at ?? DateTime.now(),
      createdAt: createdAt,
    );
  }

  String get displayText {
    if (message.trim().isEmpty) return title;
    if (title.trim().isEmpty || title.trim() == message.trim()) return message;
    return '$title\n$message';
  }

  String get relativeTime {
    final created = createdAt;
    if (created == null) return '';

    final difference = DateTime.now().difference(created.toLocal());
    if (difference.isNegative || difference.inMinutes < 1) return 'Now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${created.toLocal().year}-${created.toLocal().month.toString().padLeft(2, '0')}-${created.toLocal().day.toString().padLeft(2, '0')}';
  }
}
