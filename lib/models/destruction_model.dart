// lib/models/destruction_model.dart
//
// نماذج بيانات "طلبات الإتلاف" (Disposals) — منفصلة عن مهام الـ Tasks
// (damage_disposal task) وعن TaskDetail/WorkerTask الموجودين بـ order_model.dart.
//
//   POST /workers/disposals            -> إنشاء طلب إتلاف جديد
//   GET  /workers/disposals            -> قائمة كل الطلبات
//   GET  /workers/disposals/{id}       -> تفاصيل طلب واحد
//
// ⚠️ الكوليكشن ما فيه مثال Response محفوظ لهاد الـ endpoints (بس الـ Request
// Body للإنشاء)، فالـ parsing هون دفاعي ومرن قصداً (كل الحقول nullable ما
// عدا id) حتى ما ينكسر لو شكل الـ JSON الفعلي القادم من الباك مختلف شوي.
// لو حصل استثناء بالأسماء، بس عدّلي أسماء المفاتيح تحت (fromJson).
//
// ⚠️ حقل status: بيترجم زي ما إجا من الباك حرفياً (raw string)، بدون أي
// افتراض لقيم معينة (pending/approved/rejected...) — لأنه ما تأكد شكلها
// الحقيقي بعد. أول ما تجربي مع الباك الفعلي وتعرفي القيم، رجعيلي أضيف
// منطق الألوان/التصنيف حسب القيم الحقيقية.

class Disposal {
  final int id;
  final String? barcode;
  final String? productName;
  final int quantity;
  final String? damageReason;
  final String? status; // فعليًا من الباك: pending / approved (raw كما هو)
  final String? warehouseName;
  final int? taskId; // إذا الطلب نتج عن مسح ضمن مهمة إتلاف رسمية (لا null)
  final DateTime? createdAt;

  // true فقط للطلبات المسجّلة محلياً أثناء انقطاع النت ولسا ما انزامنت
  // مع السيرفر (موجودة بطابور pending_operations). كل طلب راجع فعلياً
  // من الـ API (عبر fromJson) بتضل هاي false دايماً.
  final bool isPendingSync;

  const Disposal({
    required this.id,
    this.barcode,
    this.productName,
    required this.quantity,
    this.damageReason,
    this.status,
    this.warehouseName,
    this.taskId,
    this.createdAt,
    this.isPendingSync = false,
  });

  // يبني تمثيل مؤقت لطلب إتلاف اتسجل أوفلاين وبعده بطابور المزامنة.
  // بيُستخدم فقط عشان يظهر بالقائمة فوراً (نفس فلسفة "locally completed
  // tasks" بـ OrderController) — مش نسخة حقيقية من السيرفر.
  factory Disposal.pendingLocal({
    required int queueId,
    required String barcode,
    required int quantity,
    required String damageReason,
    required DateTime createdAt,
  }) {
    return Disposal(
      // id سالب مقصود حتى ما يتصادم أبداً مع id حقيقي راجع من السيرفر
      // (السيرفر بيرجع IDs موجبة). queueId هو رقم الصف بجدول pending_operations.
      id: -queueId,
      barcode: barcode,
      quantity: quantity,
      damageReason: damageReason,
      status: 'pending_sync',
      createdAt: createdAt,
      isPendingSync: true,
    );
  }

  factory Disposal.fromJson(Map<String, dynamic> j) {
    final product = j['product'] is Map
        ? Map<String, dynamic>.from(j['product'] as Map)
        : null;
    final warehouse = j['warehouse'] is Map
        ? Map<String, dynamic>.from(j['warehouse'] as Map)
        : null;

    return Disposal(
      id: (j['id'] as num?)?.toInt() ?? 0,
      barcode: (j['barcode'] ?? product?['parcel_barcode'])?.toString(),
      productName: (product?['name'] ?? j['product_name'])?.toString(),
      quantity: (j['quantity'] as num?)?.toInt() ?? 0,
      damageReason: (j['damage_reason'] ?? j['reason'])?.toString(),
      status: j['status']?.toString(),
      warehouseName: (warehouse?['warehouse_name'] ?? j['warehouse_name'])
          ?.toString(),
      taskId: (j['task_id'] as num?)?.toInt(),
      createdAt: DateTime.tryParse(j['created_at']?.toString() ?? ''),
    );
  }

  // العنوان المعروض بالكرت (اسم المنتج لو موجود، وإلا الباركود، وإلا رقم الطلب)
  String get displayTitle => productName ?? barcode ?? '#$id';
}

class DisposalsResponse {
  final List<Disposal> items;
  const DisposalsResponse({required this.items});

  factory DisposalsResponse.fromJson(dynamic body) {
    // الشكل الحقيقي: {"damaged_products": [...]}. باقي المفاتيح محتفظ فيها
    // كـ fallback دفاعي بس.
    List<dynamic> raw;
    if (body is List) {
      raw = body;
    } else if (body is Map && body['damaged_products'] is List) {
      raw = body['damaged_products'] as List;
    } else if (body is Map && body['data'] is List) {
      raw = body['data'] as List;
    } else if (body is Map && body['disposals'] is List) {
      raw = body['disposals'] as List;
    } else {
      raw = const [];
    }

    return DisposalsResponse(
      items: raw
          .whereType<Map>()
          .map((e) => Disposal.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}