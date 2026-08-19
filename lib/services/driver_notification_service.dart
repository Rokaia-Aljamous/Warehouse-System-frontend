import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:stock_app/models/driver_notification_model.dart';
import 'package:stock_app/services/api.dart';
import 'package:stock_app/services/auth_service.dart';

class DriverNotificationService {
  final Dio _dio;

  DriverNotificationService({Dio? dio}) : _dio = dio ?? _buildDio();

  static Dio _buildDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: Api.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: const {'Accept': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = AuthService.token;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );

    return dio;
  }

  Future<Map<String, dynamic>> getNotifications() async {
    try {
      final response = await _dio.get(Api.notifications);
      final body = response.data is Map
          ? Map<String, dynamic>.from(response.data as Map)
          : <String, dynamic>{};
      final rawNotifications = body['data'];
      final notifications = rawNotifications is List
          ? rawNotifications
                .whereType<Map>()
                .map(
                  (item) => DriverNotification.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : <DriverNotification>[];

      return {'success': true, 'data': notifications};
    } on DioException catch (error) {
      return _handleDioError(error, 'Failed to load notifications');
    } on SocketException {
      return {'success': false, 'message': 'No internet connection'};
    } on TimeoutException {
      return {'success': false, 'message': 'Request timed out'};
    } on Exception catch (error) {
      return {'success': false, 'message': error.toString()};
    }
  }

  Future<Map<String, dynamic>> getUnreadCount() async {
    return _request(
      () => _dio.get(Api.notificationUnreadCount),
      'Failed to load unread notification count',
    );
  }

  Future<Map<String, dynamic>> markAsRead(int notificationId) async {
    return _request(
      () => _dio.post(Api.notificationRead(notificationId)),
      'Failed to mark notification as read',
    );
  }

  Future<Map<String, dynamic>> markAllAsRead() async {
    return _request(
      () => _dio.post(Api.notificationReadAll),
      'Failed to mark notifications as read',
    );
  }

  Future<Map<String, dynamic>> registerDeviceToken({
    required String token,
    required String platform,
  }) async {
    return _request(
      () => _dio.post(
        Api.notificationDeviceToken,
        data: {'token': token, 'platform': platform},
      ),
      'Failed to register notification device',
    );
  }

  Future<Map<String, dynamic>> unregisterDeviceToken(String token) async {
    return _request(
      () => _dio.delete(Api.notificationDeviceToken, data: {'token': token}),
      'Failed to unregister notification device',
    );
  }

  Future<Map<String, dynamic>> _request(
    Future<Response<dynamic>> Function() request,
    String fallback,
  ) async {
    try {
      final response = await request();
      final data = response.data is Map
          ? Map<String, dynamic>.from(response.data as Map)
          : <String, dynamic>{};
      return {'success': true, 'statusCode': response.statusCode, 'data': data};
    } on DioException catch (error) {
      return _handleDioError(error, fallback);
    } on SocketException {
      return {'success': false, 'message': 'No internet connection'};
    } on TimeoutException {
      return {'success': false, 'message': 'Request timed out'};
    } on Exception catch (error) {
      return {'success': false, 'message': error.toString()};
    }
  }

  Map<String, dynamic> _handleDioError(DioException error, String fallback) {
    final body = error.response?.data is Map
        ? Map<String, dynamic>.from(error.response!.data as Map)
        : <String, dynamic>{};
    return {
      'success': false,
      'statusCode': error.response?.statusCode,
      'data': body,
      'message': body['message']?.toString() ?? fallback,
    };
  }
}
