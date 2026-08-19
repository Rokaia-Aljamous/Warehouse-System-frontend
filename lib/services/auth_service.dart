// lib/services/auth_service.dart
//
// طبقة الخدمة المسؤولة عن التواصل المباشر مع الـ Backend (Laravel) عبر Dio.
// لا تُستخدم مباشرة من الواجهات، بل تُغلّف داخل AuthProvider.
//
// المسؤوليات:
//   1. إعداد Dio (Base URL + Headers + Interceptor يضيف الـ Token تلقائياً).
//   2. تنفيذ عمليات الـ Authentication:
//        - login
//        - logout (يستدعي الـ Backend أولاً ثم يمسح التخزين المحلي)
//        - forgotPassword (إرسال OTP)
//        - resetPassword (إعادة تعيين كلمة المرور عبر OTP)
//        - changePassword (إلزامي عند أول تسجيل دخول)
//   3. حفظ / استرجاع الجلسة (Token + UserModel + mustChangePassword) من SharedPreferences.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import 'api.dart';

class AuthService {
  // ---- حالة الجلسة الحالية (static ليتمكن الـ Interceptor من قراءتها) ----
  static String? token;
  static UserModel? user;
  static bool mustChangePassword = false;

  final Dio _dio;

  AuthService({Dio? dio}) : _dio = dio ?? _buildDio() {
    // محاولة استرجاع الجلسة المحفوظة عند إنشاء الـ Service.
    _loadStoredSession();
  }

  // ============================================================
  // إعداد Dio
  // ============================================================
  static Dio _buildDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: Api.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: {'Accept': 'application/json'},
      ),
    );

    // Interceptor يضيف الـ Bearer Token لكل الطلبات المحمية تلقائياً.
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
  // حفظ / استرجاع الجلسة من SharedPreferences
  // ============================================================
  Future<void> _loadStoredSession() async {
    final prefs = await SharedPreferences.getInstance();

    token = prefs.getString('auth_token');

    final userJson = prefs.getString('auth_user');
    if (userJson != null && userJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(userJson);
        if (decoded is Map<String, dynamic>) {
          user = UserModel.fromJson(decoded);
        }
      } catch (_) {
        user = null;
      }
    }

    mustChangePassword = prefs.getBool('auth_must_change_password') ?? false;
  }

  Future<String?> getStoredToken() async {
    if (token != null && token!.isNotEmpty) {
      return token;
    }
    await _loadStoredSession();
    return token;
  }

  Future<void> _persistSession() async {
    final prefs = await SharedPreferences.getInstance();

    if (token != null && token!.isNotEmpty) {
      await prefs.setString('auth_token', token!);
    } else {
      await prefs.remove('auth_token');
    }

    if (user != null) {
      await prefs.setString('auth_user', jsonEncode(user!.toJson()));
    } else {
      await prefs.remove('auth_user');
    }

    await prefs.setBool('auth_must_change_password', mustChangePassword);
  }

  // ============================================================
  // Logout: يستدعي الـ Backend أولاً (best-effort) ثم يمسح التخزين المحلي
  // ============================================================
  Future<void> logout() async {
    // 1) محاولة إبطال الـ Token على الـ Backend. أي خطأ لا يمنع تسجيل الخروج محلياً.
    try {
      if (token != null && token!.isNotEmpty) {
        await _dio.post(Api.logout);
      }
    } catch (_) {
      // تجاهل: شبكة / 401 / أي خطأ آخر — نكمل تنظيف الحالة محلياً.
    }

    // 2) تنظيف الحالة في الذاكرة + SharedPreferences
    token = null;
    user = null;
    mustChangePassword = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_user');
    await prefs.remove('auth_must_change_password');
  }

  // ============================================================
  // تسجيل الدخول
  // ============================================================
  Future<Map<String, dynamic>> login({
    required String userName,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        Api.login,
        data: {'user_name': userName, 'password': password},
      );

      final rawBody = response.data;
      if (rawBody is! Map) {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': 'Unexpected response from the server',
        };
      }
      final body = Map<String, dynamic>.from(rawBody);

      token = body['token']?.toString();
      final workerJson = body['worker'];
      user = workerJson is Map
          ? UserModel.fromJson(Map<String, dynamic>.from(workerJson))
          : null;
      mustChangePassword = body['must_change_password'] == true;

      await _persistSession();

      return {
        'success': true,
        'statusCode': response.statusCode,
        'data': body,
        'message': body['message']?.toString() ?? 'Login successful',
        'must_change_password': mustChangePassword,
      };
    } on DioException catch (e) {
      final body = e.response?.data is Map
          ? Map<String, dynamic>.from(e.response!.data as Map)
          : <String, dynamic>{};
      final errors = body['errors'];

      return {
        'success': false,
        'statusCode': e.response?.statusCode,
        'data': body,
        'message':
            errors is Map &&
                errors['user_name'] is List &&
                (errors['user_name'] as List).isNotEmpty
            ? (errors['user_name'][0] ?? 'Login failed').toString()
            : body['message']?.toString() ?? 'Login failed',
      };
    } on SocketException {
      return {'success': false, 'message': 'No internet connection'};
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Request timed out. Please try again.',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================================
  // نسيت كلمة المرور — إرسال OTP
  // ============================================================
  Future<Map<String, dynamic>> forgotPassword(String phoneNumber) async {
    try {
      final response = await _dio.post(
        Api.forgotPassword,
        data: {'phone_number': phoneNumber},
      );

      final body = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data ?? {});

      return {
        'success': true,
        'statusCode': response.statusCode,
        'data': body,
        'message': body['message']?.toString() ?? 'OTP sent successfully',
        // في بيئة local + driver=log فقط، يُعيد الـ Backend الـ OTP للاختبار.
        'debug_otp': body['debug_otp']?.toString(),
      };
    } on DioException catch (e) {
      final body = e.response?.data is Map
          ? Map<String, dynamic>.from(e.response!.data as Map)
          : <String, dynamic>{};
      final errors = body['errors'];

      return {
        'success': false,
        'statusCode': e.response?.statusCode,
        'data': body,
        'message':
            errors is Map &&
                errors['phone_number'] is List &&
                (errors['phone_number'] as List).isNotEmpty
            ? (errors['phone_number'][0] ?? 'Failed to send OTP').toString()
            : body['message']?.toString() ?? 'Failed to send OTP',
      };
    } on SocketException {
      return {'success': false, 'message': 'No internet connection'};
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Request timed out. Please try again.',
      };
    } on Exception catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================================
  // التحقق من صحة كود الـ OTP فقط (بدون تغيير كلمة المرور)
  // ============================================================
  Future<Map<String, dynamic>> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    try {
      final response = await _dio.post(
        Api.verifyOtp,
        data: {'phone_number': phoneNumber, 'code': otp},
      );

      final body = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data ?? {});

      return {
        'success': true,
        'statusCode': response.statusCode,
        'data': body,
        'message': body['message']?.toString() ?? 'OTP verified successfully',
      };
    } on DioException catch (e) {
      final body = e.response?.data is Map
          ? Map<String, dynamic>.from(e.response!.data as Map)
          : <String, dynamic>{};
      final errors = body['errors'];

      String? firstError;
      if (errors is Map) {
        for (final field in ['code', 'phone_number']) {
          final list = errors[field];
          if (list is List && list.isNotEmpty) {
            firstError = list[0]?.toString();
            break;
          }
        }
      }

      return {
        'success': false,
        'statusCode': e.response?.statusCode,
        'data': body,
        'message':
            firstError ?? body['message']?.toString() ?? 'Invalid OTP code',
      };
    } on SocketException {
      return {'success': false, 'message': 'No internet connection'};
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Request timed out. Please try again.',
      };
    } on Exception catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================================
  // إعادة تعيين كلمة المرور عبر OTP
  // ============================================================
  Future<Map<String, dynamic>> resetPassword({
    required String phoneNumber,
    required String otp,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _dio.post(
        Api.resetPassword,
        data: {
          'phone_number': phoneNumber,
          'otp': otp,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );

      final body = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data ?? {});

      return {
        'success': true,
        'statusCode': response.statusCode,
        'data': body,
        'message': body['message']?.toString() ?? 'Password reset successfully',
      };
    } on DioException catch (e) {
      final body = e.response?.data is Map
          ? Map<String, dynamic>.from(e.response!.data as Map)
          : <String, dynamic>{};
      final errors = body['errors'];

      // الـ Backend يُعيد أخطاء الحقول ضمن errors (otp / phone_number / password).
      String? firstError;
      if (errors is Map) {
        for (final field in ['otp', 'phone_number', 'password']) {
          final list = errors[field];
          if (list is List && list.isNotEmpty) {
            firstError = list[0]?.toString();
            break;
          }
        }
      }

      return {
        'success': false,
        'statusCode': e.response?.statusCode,
        'data': body,
        'message':
            firstError ??
            body['message']?.toString() ??
            'Failed to reset password',
      };
    } on SocketException {
      return {'success': false, 'message': 'No internet connection'};
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Request timed out. Please try again.',
      };
    } on Exception catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================================
  // تغيير كلمة المرور (إلزامي عند أول تسجيل دخول)
  // ============================================================
  Future<Map<String, dynamic>> changePassword({
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _dio.post(
        Api.changePassword,
        data: {
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );

      final body = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data ?? {});

      // بعد نجاح التغيير، نُحدّث الحالة المحلية: لم يعد إلزامياً تغيير كلمة المرور.
      mustChangePassword = false;
      await _persistSession();

      return {
        'success': true,
        'statusCode': response.statusCode,
        'data': body,
        'message':
            body['message']?.toString() ?? 'Password changed successfully',
      };
    } on DioException catch (e) {
      final body = e.response?.data is Map
          ? Map<String, dynamic>.from(e.response!.data as Map)
          : <String, dynamic>{};
      final errors = body['errors'];

      String? firstError;
      if (errors is Map) {
        for (final field in ['password', 'password_confirmation']) {
          final list = errors[field];
          if (list is List && list.isNotEmpty) {
            firstError = list[0]?.toString();
            break;
          }
        }
      }

      return {
        'success': false,
        'statusCode': e.response?.statusCode,
        'data': body,
        'message':
            firstError ??
            body['message']?.toString() ??
            'Failed to change password',
      };
    } on SocketException {
      return {'success': false, 'message': 'No internet connection'};
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Request timed out. Please try again.',
      };
    } on Exception catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================================
  // جلب بيانات البروفايل (GET /api/workers/profile)
  // ============================================================
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _dio.get(Api.profile);

      final body = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data ?? {});

      return {'success': true, 'statusCode': response.statusCode, 'data': body};
    } on DioException catch (e) {
      final body = e.response?.data is Map
          ? Map<String, dynamic>.from(e.response!.data as Map)
          : <String, dynamic>{};

      return {
        'success': false,
        'statusCode': e.response?.statusCode,
        'message': body['message']?.toString() ?? 'Failed to load profile',
      };
    } on SocketException {
      return {'success': false, 'message': 'No internet connection'};
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Request timed out. Please try again.',
      };
    } on Exception catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================================
  // تعديل البروفايل (PATCH /api/workers/profile)
  // ملاحظة: full_name / phone_number / birthday كلهم اختياريون (nullable
  // بالباك)، فبنرسل بس يلي انعبى فعلاً. profile_image اختياري كمان
  // (يحتاج مستقبلاً image_picker إذا حبيتي تفعّلي رفع صورة).
  // ============================================================
  Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? birthday, // بصيغة 'YYYY-MM-DD'
    File? profileImage,
  }) async {
    try {
      final formMap = <String, dynamic>{};

      if (fullName != null && fullName.trim().isNotEmpty) {
        formMap['full_name'] = fullName.trim();
      }
      if (phoneNumber != null && phoneNumber.trim().isNotEmpty) {
        formMap['phone_number'] = phoneNumber.trim();
      }
      if (birthday != null && birthday.trim().isNotEmpty) {
        formMap['birthday'] = birthday.trim();
      }
      if (profileImage != null) {
        formMap['profile_image'] = await MultipartFile.fromFile(
          profileImage.path,
          filename: profileImage.path.split('/').last,
        );
      }

      final response = await _dio.patch(
        Api.profile,
        data: FormData.fromMap(formMap),
      );

      final body = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data ?? {});

      return {
        'success': true,
        'statusCode': response.statusCode,
        'data': body,
        'message':
            body['message']?.toString() ?? 'Profile updated successfully',
      };
    } on DioException catch (e) {
      final body = e.response?.data is Map
          ? Map<String, dynamic>.from(e.response!.data as Map)
          : <String, dynamic>{};
      final errors = body['errors'];

      String? firstError;
      if (errors is Map) {
        for (final field in [
          'full_name',
          'phone_number',
          'birthday',
          'profile_image',
        ]) {
          final list = errors[field];
          if (list is List && list.isNotEmpty) {
            firstError = list[0]?.toString();
            break;
          }
        }
      }

      return {
        'success': false,
        'statusCode': e.response?.statusCode,
        'message':
            firstError ??
            body['message']?.toString() ??
            'Failed to update profile',
      };
    } on SocketException {
      return {'success': false, 'message': 'No internet connection'};
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Request timed out. Please try again.',
      };
    } on Exception catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
