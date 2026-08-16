// lib/providers/auth_provider.dart
//
// مزود الحالة (State Management) لكل ما يخص الـ Authentication.
// يُغلّف AuthService ويُعرف الواجهات على حالة الـ Auth فقط (لا تتعامل الواجهات مع Dio مباشرة).

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:stock_app/services/auth_service.dart';
import 'package:stock_app/services/local_storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final LocalStorageService _localStorage = LocalStorageService();

  // ---- الحالة العامة ----
  bool isLoading = false;
  bool isInitializing = true;
  bool isAuthenticated = false;
  bool mustChangePassword = false;
  String? errorMessage;
  String? phoneNumber;

  // ---- بيانات البروفايل (تُجلب من GET /profile) ----
  bool isProfileLoading = false;
  String? profileFullName;
  String? profileBirthday;
  String? profilePhoneNumber;
  String? profileUserName;
  String? profileImageUrl;
  String? profileRole;
  String? profileStatus;
  int? profileWarehouseId;
  bool profileIsFromCache = false;
  // true من لحظة ما ننسجل تعديل بروفايل أوفلاين لحد ما ينزامن فعلياً
  // (نفس فلسفة isListFromCache/isDetailsFromCache بـ OrderController)
  bool profileIsPendingSync = false;

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

    // تنظيف ملفات الصور المعلّقة (لو في تعديل بروفايل أوفلاين ما انزامن)
    // قبل ما clearAll() يمسح مرجعها من الطابور، حتى ما تضل ملفات يتيمة
    // على الجهاز.
    final pendingOps = await _localStorage.getPendingOperations(status: 'pending');
    for (final op in pendingOps) {
      if (op['type'] == 'profile_update') {
        final imagePath =
            (op['payload'] as Map<String, dynamic>)['image_path']?.toString();
        if (imagePath != null && imagePath.isNotEmpty) {
          await _localStorage.deletePendingImage(imagePath);
        }
      }
    }

    await _localStorage.clearAll();

    isLoading = false;
    isAuthenticated = false;
    mustChangePassword = false;
    phoneNumber = null;
    // تنظيف بيانات البروفايل أيضاً عند الخروج
    profileFullName = null;
    profileBirthday = null;
    profilePhoneNumber = null;
    profileUserName = null;
    profileImageUrl = null;
    profileRole = null;
    profileStatus = null;
    profileWarehouseId = null;
    profileIsFromCache = false;
    profileIsPendingSync = false;
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
  // 6) تغيير كلمة المرور (إلزامي عند أول تسجيل دخول فقط — الباك
  //    برفض 403 أي استدعاء لهاد الدالة إذا must_change_password=false)
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

  // ============================================================
  // 8) جلب بيانات البروفايل (GET /profile)
  // ============================================================
  Future<void> fetchProfile() async {
    isProfileLoading = true;
    notifyListeners();

    final result = await _authService.getProfile();

    isProfileLoading = false;

    if (result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>;
      _applyProfileJson(data);
      profileIsFromCache = false;
      errorMessage = null;
      await _applyPendingProfileEditIfAny();
      notifyListeners();
      // نخزن النسخة الناجحة محلياً عشان تكون جاهزة لو انقطع النت لاحقاً
      unawaited(_localStorage.saveProfile(data));
      return;
    }

    // statusCode == null يعني فشل على مستوى الشبكة (SocketException/Timeout)
    // مش رفض من السيرفر (401/403...) — بهاي الحالة فقط نرجع للكاش.
    final isNetworkFailure = result['statusCode'] == null;

    if (isNetworkFailure) {
      final cached = await _localStorage.getProfile();
      if (cached != null) {
        _applyProfileJson(cached);
        profileIsFromCache = true;
        errorMessage = null;
        await _applyPendingProfileEditIfAny();
        notifyListeners();
        return;
      }
    }

    errorMessage = result['message']?.toString() ?? 'Failed to load profile';
    notifyListeners();
  }

  // لو في تعديل بروفايل اتسجل أوفلاين ولسا بطابور المزامنة، منطبّق
  // حقوله النصية فوق القيم يلي جبناها لتوّنا (سواء من السيرفر أو الكاش)
  // حتى ما "يرجع" العرض للقيمة القديمة لما المستخدم يزور شاشة البروفايل
  // تاني قبل ما تنزامن العملية المعلّقة فعلياً (نفس مبدأ دمج العمليات
  // المعلّقة المستخدم بـ OrderController/DestructionController).
  Future<void> _applyPendingProfileEditIfAny() async {
    final ops = await _localStorage.getPendingOperations(status: 'pending');
    final pendingEdits = ops.where((op) => op['type'] == 'profile_update');

    if (pendingEdits.isEmpty) {
      profileIsPendingSync = false;
      return;
    }

    // آخر تعديل معلّق هو الأحدث (الطابور FIFO)
    final payload = pendingEdits.last['payload'] as Map<String, dynamic>;
    final fullName = payload['full_name']?.toString();
    final phoneNumber = payload['phone_number']?.toString();
    final birthday = payload['birthday']?.toString();

    if (fullName != null && fullName.isNotEmpty) profileFullName = fullName;
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      profilePhoneNumber = phoneNumber;
    }
    if (birthday != null && birthday.isNotEmpty) profileBirthday = birthday;
    // ملاحظة: ما منطبّق صورة محلية على profileImageUrl لأن الواجهة بتعرضها
    // حصراً عبر NetworkImage — الصورة الجديدة رح تظهر تلقائياً أول ما
    // تنزامن وتنجلب من السيرفر بزيارة لاحقة لشاشة البروفايل.

    profileIsPendingSync = true;
  }

  // الرد الحقيقي لـ GET /profile مقسوم لكائنين متداخلين، مش حقول مباشرة
  // على الجذر: {"profile": {full_name, birthday, phone_number, user_name,
  // profile_image}, "employee": {role, status, warehouse_id}}.
  void _applyProfileJson(Map<String, dynamic> data) {
    final profile = data['profile'] is Map
        ? Map<String, dynamic>.from(data['profile'] as Map)
        : <String, dynamic>{};
    final employee = data['employee'] is Map
        ? Map<String, dynamic>.from(data['employee'] as Map)
        : <String, dynamic>{};

    profileFullName = profile['full_name']?.toString();
    profileBirthday = profile['birthday']?.toString();
    profilePhoneNumber = profile['phone_number']?.toString();
    profileUserName = profile['user_name']?.toString();
    profileImageUrl = profile['profile_image']?.toString();
    profileRole = employee['role']?.toString();
    profileStatus = employee['status']?.toString();
    profileWarehouseId = (employee['warehouse_id'] as num?)?.toInt();
  }

  // ============================================================
  // 9) تعديل البروفايل (PATCH /profile)
  // ============================================================
  Future<bool> updateProfile({
    required String fullName,
    required String phoneNumber,
    String? birthday,
    File? profileImage,
  }) async {
    if (fullName.trim().isEmpty || phoneNumber.trim().isEmpty) {
      errorMessage = 'Please fill in the required fields';
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final result = await _authService.updateProfile(
      fullName: fullName,
      phoneNumber: phoneNumber,
      birthday: birthday,
      profileImage: profileImage,
    );

    isLoading = false;

    if (result['success'] == true) {
      // الرد الحقيقي: {"message": "...", "profile": {id, full_name, birthday,
      // phone_number, user_name, profile_image}} — منثق بالقيم الراجعة من
      // الباك إند كمصدر الحقيقة، مو بالقيم يلي بعتناها إحنا بالطلب.
      final data = result['data'];
      final profile = (data is Map && data['profile'] is Map)
          ? Map<String, dynamic>.from(data['profile'] as Map)
          : null;

      if (profile != null) {
        profileFullName = profile['full_name']?.toString() ?? fullName.trim();
        profilePhoneNumber =
            profile['phone_number']?.toString() ?? phoneNumber.trim();
        profileBirthday = profile['birthday']?.toString() ?? profileBirthday;
        profileUserName = profile['user_name']?.toString() ?? profileUserName;
        profileImageUrl = profile['profile_image']?.toString();
      } else {
        // fallback احتياطي لو الباك رجع شكل غير متوقع
        profileFullName = fullName.trim();
        profilePhoneNumber = phoneNumber.trim();
        if (birthday != null && birthday.isNotEmpty) {
          profileBirthday = birthday;
        }
      }

      errorMessage = null;
      profileIsPendingSync = false;
      notifyListeners();
      return true;
    }

    final isNetworkFailure = result['statusCode'] == null;
    if (isNetworkFailure) {
      return _updateProfileOffline(
        fullName: fullName,
        phoneNumber: phoneNumber,
        birthday: birthday,
        profileImage: profileImage,
      );
    }

    errorMessage = result['message']?.toString() ?? 'Failed to update profile';
    notifyListeners();
    return false;
  }

  // ============================================================
  // 9-ب) تعديل البروفايل أوفلاين — بننسخ الصورة (إذا موجودة) لمجلد
  // دائم، بنسجل العملية بطابور المزامنة، وبنطبّق القيم النصية محلياً
  // فوراً (نفس منطق الـ "fallback احتياطي" الموجود أصلاً بالمسار
  // الأونلاين فوق). الصورة نفسها ما بتنعرض إلا بعد ما تنزامن فعلياً
  // (auth.profileImageUrl معروضة حصراً عبر NetworkImage بالشاشة).
  // ============================================================
  Future<bool> _updateProfileOffline({
    required String fullName,
    required String phoneNumber,
    String? birthday,
    File? profileImage,
  }) async {
    String? imagePath;
    if (profileImage != null) {
      imagePath = await _localStorage.persistPendingImage(profileImage);
    }

    await _localStorage.addPendingOperation(
      type: 'profile_update',
      payload: {
        'full_name': fullName.trim(),
        'phone_number': phoneNumber.trim(),
        if (birthday != null && birthday.isNotEmpty) 'birthday': birthday,
        if (imagePath != null) 'image_path': imagePath,
      },
    );

    profileFullName = fullName.trim();
    profilePhoneNumber = phoneNumber.trim();
    if (birthday != null && birthday.isNotEmpty) {
      profileBirthday = birthday;
    }
    profileIsPendingSync = true;

    errorMessage = null;
    notifyListeners();
    return true;
  }
}