import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:stock_app/models/driver_notification_model.dart';
import 'package:stock_app/services/driver_notification_service.dart';
import 'package:stock_app/services/firebase_messaging_manager.dart';

class DriverNotificationController extends ChangeNotifier {
  final DriverNotificationService _service;
  final FirebaseMessagingManager _firebase;

  DriverNotificationController({
    DriverNotificationService? service,
    FirebaseMessagingManager? firebase,
  }) : _service = service ?? DriverNotificationService(),
       _firebase = firebase ?? FirebaseMessagingManager.instance;

  List<DriverNotification> notifications = const [];
  int unreadCount = 0;
  bool isLoading = false;
  String? error;

  StreamSubscription<void>? _notificationSubscription;
  StreamSubscription<String>? _tokenSubscription;
  String? _registeredToken;

  List<DriverNotification> get unreadNotifications =>
      notifications.where((item) => !item.isRead).toList();
  List<DriverNotification> get readNotifications =>
      notifications.where((item) => item.isRead).toList();

  Future<void> initialize() async {
    _notificationSubscription = _firebase.notificationEvents.listen((_) {
      unawaited(refresh());
    });
    _tokenSubscription = _firebase.tokenRefresh.listen((token) {
      unawaited(_registerToken(token));
    });

    await Future.wait([refresh(), _enablePushNotifications()]);
  }

  Future<void> refresh() async {
    isLoading = notifications.isEmpty;
    error = null;
    notifyListeners();

    final results = await Future.wait([
      _service.getNotifications(),
      _service.getUnreadCount(),
    ]);
    final notificationsResult = results[0];
    final countResult = results[1];

    if (notificationsResult['success'] == true) {
      notifications = List<DriverNotification>.from(
        notificationsResult['data'] as List,
      );
    } else {
      error = notificationsResult['message']?.toString();
    }

    if (countResult['success'] == true) {
      final data = countResult['data'];
      if (data is Map) {
        unreadCount = (data['unread_count'] as num?)?.toInt() ?? 0;
      }
    } else {
      unreadCount = unreadNotifications.length;
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> markAsRead(DriverNotification notification) async {
    if (notification.isRead) return;

    final result = await _service.markAsRead(notification.id);
    if (result['success'] != true) {
      error = result['message']?.toString();
      notifyListeners();
      return;
    }

    notifications = notifications
        .map((item) => item.id == notification.id ? item.markRead() : item)
        .toList();
    unreadCount = unreadCount > 0 ? unreadCount - 1 : 0;
    notifyListeners();
  }

  Future<void> markAllAsRead() async {
    final result = await _service.markAllAsRead();
    if (result['success'] != true) {
      error = result['message']?.toString();
      notifyListeners();
      return;
    }

    notifications = notifications.map((item) => item.markRead()).toList();
    unreadCount = 0;
    notifyListeners();
  }

  Future<void> unregisterDevice() async {
    final token = _registeredToken;
    if (token != null && token.isNotEmpty) {
      await _service.unregisterDeviceToken(token);
    }
    await _firebase.deleteToken();
    _registeredToken = null;
  }

  Future<void> _enablePushNotifications() async {
    final token = await _firebase.enableForAuthenticatedDriver();
    if (token != null && token.isNotEmpty) {
      await _registerToken(token);
    }
  }

  Future<void> _registerToken(String token) async {
    final previousToken = _registeredToken;
    if (previousToken != null && previousToken != token) {
      await _service.unregisterDeviceToken(previousToken);
    }

    final platform = Platform.isIOS ? 'ios' : 'android';
    final result = await _service.registerDeviceToken(
      token: token,
      platform: platform,
    );
    if (result['success'] == true) {
      _registeredToken = token;
    }
  }

  @override
  void dispose() {
    unawaited(_notificationSubscription?.cancel());
    unawaited(_tokenSubscription?.cancel());
    super.dispose();
  }
}
