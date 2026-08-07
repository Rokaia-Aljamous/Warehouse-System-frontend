// lib/services/disposal_service.dart
//
// طبقة الخدمة المسؤولة عن "طلبات الإتلاف" (Disposals). نفس نمط
// task_service.dart بالظبط: Dio + Interceptor يضيف Bearer Token تلقائياً
// من AuthService.token، ومعالجة موحّدة للأخطاء.
//
//   createDisposal(barcode, quantity, damageReason) -> POST /workers/disposals
//   getDisposals()                                  -> GET  /workers/disposals
//   getDisposalDetails(id)                          -> GET  /workers/disposals/{id}

import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

import 'api.dart';
import 'auth_service.dart';

class DisposalService {
  final Dio _dio;

  DisposalService({Dio? dio}) : _dio = dio ?? _buildDio();

  static Dio _buildDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: Api.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: {'Accept': 'application/json'},
      ),
    );

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
  // إنشاء طلب إتلاف — POST /workers/disposals
  // ============================================================
  Future<Map<String, dynamic>> createDisposal({
    required String barcode,
    required int quantity,
    required String damageReason,
  }) async {
    try {
      final response = await _dio.post(
        Api.disposals,
        data: {
          'barcode': barcode,
          'quantity': quantity,
          'damage_reason': damageReason,
        },
      );

      return {
        'success': true,
        'statusCode': response.statusCode,
        'data': response.data,
      };
    } on DioException catch (e) {
      return _handleDioError(e, fallback: 'Failed to submit disposal request');
    } on SocketException {
      return {'success': false, 'message': 'No internet connection'};
    } on TimeoutException {
      return {'success': false, 'message': 'Request timed out. Please try again.'};
    } on Exception catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================================
  // قائمة طلبات الإتلاف — GET /workers/disposals
  // ============================================================
  Future<Map<String, dynamic>> getDisposals() async {
    try {
      final response = await _dio.get(Api.disposals);
      return {
        'success': true,
        'statusCode': response.statusCode,
        'data': response.data,
      };
    } on DioException catch (e) {
      return _handleDioError(e, fallback: 'Failed to load disposal requests');
    } on SocketException {
      return {'success': false, 'message': 'No internet connection'};
    } on TimeoutException {
      return {'success': false, 'message': 'Request timed out. Please try again.'};
    } on Exception catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================================
  // تفاصيل طلب إتلاف واحد — GET /workers/disposals/{id}
  // ============================================================
  Future<Map<String, dynamic>> getDisposalDetails(int id) async {
    try {
      final response = await _dio.get(Api.disposalDetails(id));
      return {
        'success': true,
        'statusCode': response.statusCode,
        'data': response.data,
      };
    } on DioException catch (e) {
      return _handleDioError(e, fallback: 'Failed to load disposal details');
    } on SocketException {
      return {'success': false, 'message': 'No internet connection'};
    } on TimeoutException {
      return {'success': false, 'message': 'Request timed out. Please try again.'};
    } on Exception catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

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
