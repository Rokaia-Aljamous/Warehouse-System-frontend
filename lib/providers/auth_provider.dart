// lib/providers/auth_provider.dart
//
// مزود الحالة (State Management) لكل ما يخص الـ Authentication.
// يُغلّف AuthService ويُعرف الواجهات على حالة الـ Auth فقط (لا تتعامل الواجهات مع Dio مباشرة).
//
// الحالة المكشوفة للواجهات:
//   - isLoading           : هل توجد عملية جارية؟
//   - isInitializing      : هل التطبيق لا يزال يستعيد الجلسة عند الإقلاع؟
//   - isAuthenticated     : هل العامل مسجّل دخوله (يوجد Token صالح)؟
//   - mustChangePassword  : هل يجب تغيير كلمة المرور عند أول دخول؟
//   - errorMessage        : آخر رسالة خطأ (تُستخدم لإظهارها في الـ UI).
//   - phoneNumber         : رقم الهاتف المُستخدم في تدفّق OTP (يُحفظ بين شاشتي Forgot و Reset).
//   - currentRole         : دور العامل الحالي ('driver' أو 'staff') — يُستخدم للتوجيه بعد الدخول.

import 'package:flutter/material.dart';
import 'package:stock_app/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  // ---- الحالة العامة ----
  bool isLoading = false;
  bool isInitializing = true;
  bool isAuthenticated = false;
  bool mustChangePassword = false;
  String? errorMessage;
  String? phoneNumber;

  // ============================================================
  // 1) تهيئة التطبيق عند الفتح — يسترجع الجلسة المحفوظة
  // ============================================================
  Future<void> initialize() async {
    isInitializing = true;
    notifyListeners();

    await _authService.getStoredToken();
    isAuthenticated =
        AuthService.token != null && AuthService.token!.isNotEmpty;
    mustChangePassword = AuthService.mustChangePassword;

    isInitializing = false;
    notifyListeners();
  }

  // ============================================================
  // 2) تسجيل الدخول
  // ============================================================
  Future<bool> login(String userName, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final result = await _authService.login(
      userName: userName,
      password: password,
    );

    isLoading = false;

    if (result['success'] == true) {
      isAuthenticated =
          AuthService.token != null && AuthService.token!.isNotEmpty;
      mustChangePassword = result['must_change_password'] == true;
      notifyListeners();
      return true;
    }

    errorMessage = result['message']?.toString() ?? 'Login failed';
    notifyListeners();
    return false;
  }

  // ============================================================
  // 3) تسجيل الخروج — يستدعي الـ Backend أولاً ثم يُنظّف الحالة
  // ============================================================
  Future<void> logout() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    await _authService.logout();

    isLoading = false;
    isAuthenticated = false;
    mustChangePassword = false;
    phoneNumber = null;
    notifyListeners();
  }

  // ============================================================
  // 4.5) التحقق من كود الـ OTP فقط (قبل الانتقال لشاشة كلمة المرور)
  // ============================================================
  Future<bool> verifyOtp(String otp) async {
    final normalizedOtp = otp.trim();

    if (phoneNumber == null || phoneNumber!.trim().isEmpty) {
      errorMessage = 'Phone number is missing';
      notifyListeners();
      return false;
    }

    if (normalizedOtp.isEmpty) {
      errorMessage = 'Please enter the code';
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final result = await _authService.verifyOtp(
      phoneNumber: phoneNumber!,
      otp: normalizedOtp,
    );

    isLoading = false;

    if (result['success'] == true) {
      errorMessage = null;
      notifyListeners();
      return true;
    }

    errorMessage = result['message']?.toString() ?? 'Invalid OTP code';
    notifyListeners();
    return false;
  }

  // ============================================================
  // 4) نسيت كلمة المرور — إرسال OTP
  // ============================================================
  Future<bool> sendForgotPassword(String phone) async {
    final normalizedPhone = phone.trim();

    if (normalizedPhone.isEmpty) {
      errorMessage = 'Phone number is required';
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final result = await _authService.forgotPassword(normalizedPhone);

    isLoading = false;

    if (result['success'] == true) {
      phoneNumber = normalizedPhone;
      errorMessage = null;
      notifyListeners();
      return true;
    }

    errorMessage = result['message']?.toString() ?? 'Failed to send OTP';
    notifyListeners();
    return false;
  }

  // ============================================================
  // 5) إعادة تعيين كلمة المرور عبر OTP
  // ============================================================
  Future<bool> resetPassword({
    required String otp,
    required String password,
    required String confirmPassword,
  }) async {
    final normalizedOtp = otp.trim();

    if (phoneNumber == null || phoneNumber!.trim().isEmpty) {
      errorMessage = 'Phone number is missing';
      notifyListeners();
      return false;
    }

    if (normalizedOtp.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      errorMessage = 'Please fill in all fields';
      notifyListeners();
      return false;
    }

    if (password != confirmPassword) {
      errorMessage = 'Passwords do not match';
      notifyListeners();
      return false;
    }

    if (password.length < 8) {
      errorMessage = 'Password must be at least 8 characters';
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final result = await _authService.resetPassword(
      phoneNumber: phoneNumber!,
      otp: normalizedOtp,
      password: password,
      passwordConfirmation: confirmPassword,
    );

    isLoading = false;

    if (result['success'] == true) {
      errorMessage = null;
      notifyListeners();
      return true;
    }

    errorMessage = result['message']?.toString() ?? 'Failed to reset password';
    notifyListeners();
    return false;
  }

  // ============================================================
  // 6) تغيير كلمة المرور (إلزامي عند أول تسجيل دخول)
  // ============================================================
  Future<bool> changePassword({
    required String password,
    required String passwordConfirmation,
  }) async {
    if (password.isEmpty || passwordConfirmation.isEmpty) {
      errorMessage = 'Please fill in all fields';
      notifyListeners();
      return false;
    }

    if (password != passwordConfirmation) {
      errorMessage = 'Passwords do not match';
      notifyListeners();
      return false;
    }

    if (password.length < 8) {
      errorMessage = 'Password must be at least 8 characters';
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final result = await _authService.changePassword(
      password: password,
      passwordConfirmation: passwordConfirmation,
    );

    isLoading = false;

    if (result['success'] == true) {
      mustChangePassword = false;
      errorMessage = null;
      notifyListeners();
      return true;
    }

    errorMessage = result['message']?.toString() ?? 'Failed to change password';
    notifyListeners();
    return false;
  }

  // ============================================================
  // 7) قراءة دور العامل الحالي — تُستخدم للتوجيه بعد الدخول
  // ============================================================
  String? get currentRole => AuthService.user?.role;
}
