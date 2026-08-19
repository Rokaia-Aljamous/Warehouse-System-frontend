import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:stock_app/services/api.dart';
import 'package:stock_app/services/auth_service.dart';

class DriverTaskService {
  final Dio _dio;

  DriverTaskService({Dio? dio}) : _dio = dio ?? _buildDio();

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

  Future<Map<String, dynamic>> getTasks() async {
    return _get(Api.tasks, 'Failed to load driver tasks');
  }

  Future<Map<String, dynamic>> getDailySummary() async {
    return _get(Api.taskSummary, 'Failed to load today summary');
  }

  Future<Map<String, dynamic>> getTaskDetails(int taskId) async {
    return _get(Api.taskDetails(taskId), 'Failed to load task details');
  }

  Future<Map<String, dynamic>> getOrderDetails(int orderId) async {
    return _get(
      Api.orderDetails(orderId),
      'Failed to load customer and destination details',
    );
  }

  Future<Map<String, dynamic>> getReturnDetails(int returnId) async {
    return _get(
      Api.returnDetails(returnId),
      'Failed to load return pickup details',
    );
  }

  Future<Map<String, dynamic>> scanTaskBarcode({
    required int taskId,
    required String barcode,
  }) async {
    try {
      final response = await _dio.post(
        Api.taskScan(taskId),
        data: {'barcode': barcode},
      );
      final body = response.data is Map
          ? Map<String, dynamic>.from(response.data as Map)
          : <String, dynamic>{};

      return {
        'success': body['matched'] == true,
        'statusCode': response.statusCode,
        'data': body,
        'message':
            body['warning']?.toString() ??
            body['message']?.toString() ??
            'Barcode scanned successfully',
      };
    } on DioException catch (error) {
      return _handleDioError(error, 'Barcode does not match this task');
    } on SocketException {
      return {'success': false, 'message': 'No internet connection'};
    } on TimeoutException {
      return {'success': false, 'message': 'Request timed out'};
    } on Exception catch (error) {
      return {'success': false, 'message': error.toString()};
    }
  }

  Future<Map<String, dynamic>> updateCurrentLocation({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _dio.post(
        Api.driverLocation,
        data: {'latitude': latitude, 'longitude': longitude},
      );

      return {
        'success': true,
        'statusCode': response.statusCode,
        'data': response.data,
      };
    } on DioException catch (error) {
      return _handleDioError(error, 'Failed to update driver location');
    } on SocketException {
      return {'success': false, 'message': 'No internet connection'};
    } on TimeoutException {
      return {'success': false, 'message': 'Request timed out'};
    } on Exception catch (error) {
      return {'success': false, 'message': error.toString()};
    }
  }

  Future<Map<String, dynamic>> _get(String path, String fallbackMessage) async {
    try {
      final response = await _dio.get(path);
      final body = response.data is Map
          ? Map<String, dynamic>.from(response.data as Map)
          : <String, dynamic>{};

      return {'success': true, 'statusCode': response.statusCode, 'data': body};
    } on DioException catch (error) {
      return _handleDioError(error, fallbackMessage);
    } on SocketException {
      return {'success': false, 'message': 'No internet connection'};
    } on TimeoutException {
      return {'success': false, 'message': 'Request timed out'};
    } on Exception catch (error) {
      return {'success': false, 'message': error.toString()};
    }
  }

  Map<String, dynamic> _handleDioError(
    DioException error,
    String fallbackMessage,
  ) {
    final body = error.response?.data is Map
        ? Map<String, dynamic>.from(error.response!.data as Map)
        : <String, dynamic>{};

    return {
      'success': false,
      'statusCode': error.response?.statusCode,
      'data': body,
      'message': body['message']?.toString() ?? fallbackMessage,
    };
  }
}
