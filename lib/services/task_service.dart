// lib/services/task_service.dart
//
// طبقة الخدمة المسؤولة عن التواصل مع الباك إند لكل ما يخص مهام العامل
// (Tasks). نفس نمط auth_service.dart تماماً: Dio + Interceptor يضيف
// الـ Bearer Token من AuthService.token تلقائياً، ومعالجة موحّدة للأخطاء.
//
// المسؤوليات:
//   - getTasks(category, status)            -> GET  /workers/tasks
//   - getTaskDetails(taskId)                 -> GET  /workers/tasks/{id}
//   - scanBarcode(taskId, barcode)           -> POST /workers/tasks/{id}/scan
//   - completeTask(taskId)                   -> POST /workers/tasks/{id}/complete

import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

import 'api.dart';
import 'auth_service.dart';

class TaskService {
  final Dio _dio;

  TaskService({Dio? dio}) : _dio = dio ?? _buildDio();

  static Dio _buildDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: Api.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: {'Accept': 'application/json'},
      ),
    );

    // نفس منطق AuthService بالضبط: يقرأ التوكن من الحالة الثابتة المشتركة
    // AuthService.token (اللي بتحدّثه شاشات تسجيل الدخول الموجودة أصلاً).
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final activeToken = AuthService.token;
          if (activeToken != null && activeToken.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $activeToken';
          }
          handler.next(options);
        },
      ),
    );

    return dio;
  }

  // ============================================================
  // قائمة المهام — GET /workers/tasks?category=...&status=...
  // category: "Order preparation" | "Receiving a shipment" | "Destruction" | "Returns"
  // status:   "in_preparation" | "completed"
  // ============================================================
  Future<Map<String, dynamic>> getTasks({String? category, String? status}) async {
    try {
      final response = await _dio.get(
        Api.tasks,
        queryParameters: {
          if (category != null) 'category': category,
          if (status != null) 'status': status,
        },
      );

      final body = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data ?? {});

      return {'success': true, 'statusCode': response.statusCode, 'data': body};
    } on DioException catch (e) {
      return _handleDioError(e, fallback: 'Failed to load tasks');
    } on SocketException {
      return {'success': false, 'message': 'No internet connection'};
    } on TimeoutException {
      return {'success': false, 'message': 'Request timed out. Please try again.'};
    } on Exception catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================================
  // تفاصيل مهمة واحدة — GET /workers/tasks/{taskId}
  // ============================================================
  Future<Map<String, dynamic>> getTaskDetails(int taskId) async {
    try {
      final response = await _dio.get(Api.taskDetails(taskId));

      final body = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data ?? {});

      return {'success': true, 'statusCode': response.statusCode, 'data': body};
    } on DioException catch (e) {
      return _handleDioError(e, fallback: 'Failed to load task details');
    } on SocketException {
      return {'success': false, 'message': 'No internet connection'};
    } on TimeoutException {
      return {'success': false, 'message': 'Request timed out. Please try again.'};
    } on Exception catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================================
  // مسح باركود ضمن مهمة — POST /workers/tasks/{taskId}/scan
  // ملاحظة: كل استدعاء = مسحة وحدة واحدة (الباك ما بيدعم quantity).
  // لمسح أكثر من قطعة لنفس المنتج، بننادي هاد الدالة أكثر من مرة.
  // ============================================================
  Future<Map<String, dynamic>> scanBarcode(int taskId, String barcode) async {
    try {
      final response = await _dio.post(
        Api.taskScan(taskId),
        data: {'barcode': barcode},
      );

      final body = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data ?? {});

      return {'success': true, 'statusCode': response.statusCode, 'data': body};
    } on DioException catch (e) {
      return _handleDioError(e, fallback: 'Failed to scan barcode');
    } on SocketException {
      return {'success': false, 'message': 'No internet connection'};
    } on TimeoutException {
      return {'success': false, 'message': 'Request timed out. Please try again.'};
    } on Exception catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================================
  // إكمال المهمة — POST /workers/tasks/{taskId}/complete
  // عند 409 مع remaining_items، بنرجعهم ضمن body['data']['remaining_items']
  // ============================================================
  Future<Map<String, dynamic>> completeTask(int taskId) async {
    try {
      final response = await _dio.post(Api.taskComplete(taskId));

      final body = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data ?? {});

      return {'success': true, 'statusCode': response.statusCode, 'data': body};
    } on DioException catch (e) {
      return _handleDioError(e, fallback: 'Failed to complete task');
    } on SocketException {
      return {'success': false, 'message': 'No internet connection'};
    } on TimeoutException {
      return {'success': false, 'message': 'Request timed out. Please try again.'};
    } on Exception catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================================
  // معالجة موحّدة لأخطاء Dio (نفس أسلوب auth_service.dart)
  // ============================================================
  Map<String, dynamic> _handleDioError(DioException e, {required String fallback}) {
    final body = e.response?.data is Map
        ? Map<String, dynamic>.from(e.response!.data as Map)
        : <String, dynamic>{};

    return {
      'success': false,
      'statusCode': e.response?.statusCode,
      'data': body,
      'message': body['message']?.toString() ?? fallback,
    };
  }
}
