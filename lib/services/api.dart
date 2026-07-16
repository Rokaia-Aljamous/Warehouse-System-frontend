class Api {
  // 🌟 لو عم تشغّلي Laravel محليًا بـ php artisan serve:
  // - على المحاكي (Android Emulator): استخدمي 10.0.2.2 بدل localhost
  // - على جهاز حقيقي أو iOS Simulator: استخدمي الـ IP المحلي لجهاز الكمبيوتر (مثلاً 192.168.1.x)
  // - لو السيرفر أونلاين: حطي الدومين الحقيقي
 // عدّلي هذا السطر:
static const String baseUrl = "http://10.88.11.104:8000";

  static const String login = "/api/workers/login";
  static const String forgotPassword = "/api/workers/password/forgot";
  static const String resetPassword = "/api/workers/password/reset";
   static const String verifyOtp = "/api/workers/password/verify-otp";
  static const String logout = "/api/workers/logout";
  static const String profile = "/api/workers/profile";
   static const String changePassword = "/api/workers/password/change";

  static String buildUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }
}
