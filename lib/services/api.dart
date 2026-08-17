class Api {
  // 🌟 لو عم تشغّلي Laravel محليًا بـ php artisan serve:
  // - على المحاكي (Android Emulator): استخدمي 10.0.2.2 بدل localhost
  // - على جهاز حقيقي أو iOS Simulator: استخدمي الـ IP المحلي لجهاز الكمبيوتر (مثلاً 192.168.1.x)
  // - لو السيرفر أونلاين: حطي الدومين الحقيقي
  // عدّلي هذا السطر:
  static const String baseUrl = "http://10.65.1.21:8000";

  static const String login = "/api/workers/login";
  static const String forgotPassword = "/api/workers/password/forgot";
  static const String resetPassword = "/api/workers/password/reset";
  static const String verifyOtp = "/api/workers/password/verify-otp";
  static const String logout = "/api/workers/logout";
  static const String profile = "/api/workers/profile";
  static const String changePassword = "/api/workers/password/change";

  // ---- Tasks (مهام العامل) ----
  static const String tasks = "/api/workers/tasks";
  static String taskDetails(int taskId) => "/api/workers/tasks/$taskId";
  static String taskScan(int taskId) => "/api/workers/tasks/$taskId/scan";
  static String taskComplete(int taskId) =>
      "/api/workers/tasks/$taskId/complete";

  // ---- Order Preparation (خاص فقط بمهام task_type = order_preparation) ----
  // تفاصيل المهمة هون بتيجي عن طريق related_id (Order ID) مش Task ID.
  // Task ID بيضل يستخدم فقط لـ scan/complete فوق.
  static String orderDetails(int orderId) => "/api/workers/orders/$orderId";

  // ---- Receiving a shipment (خاص فقط بمهام task_type = shipment_receiving) ----
  // نفس مبدأ orderDetails تماماً: تفاصيل الشحنة بتيجي عن طريق related_id
  // (Shipment ID) مش Task ID. Task ID بيضل يستخدم فقط لـ scan/complete فوق.
  static String shipmentDetails(int shipmentId) =>
      "/api/workers/shipments/$shipmentId";

  // ---- Returns / Recovery (خاص فقط بمهام task_type = restock_product) ----
  // نفس المبدأ بالظبط: تفاصيل المرتجع بتيجي عن طريق related_id (Return ID)
  // مش Task ID. Task ID بيضل يستخدم فقط لـ scan/complete فوق.
  static String returnDetails(int returnId) =>
      "/api/workers/returns/$returnId";

  // ---- Disposals (طلبات إتلاف مستقلة عن الـ Tasks) ----
  // POST disposals: {"barcode": "...", "quantity": 1, "damage_reason": "..."}
  static const String disposals = "/api/workers/disposals";
  static String disposalDetails(int disposalId) =>
      "/api/workers/disposals/$disposalId";

  static String buildUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }
}
