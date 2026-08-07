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
  final String? status; // مثال متوقع: pending / approved / rejected...
  final String? shipmentName;
  final DateTime? createdAt;

  const Disposal({
    required this.id,
    this.barcode,
    this.productName,
    required this.quantity,
    this.damageReason,
    this.status,
    this.shipmentName,
    this.createdAt,
  });

  factory Disposal.fromJson(Map<String, dynamic> j) {
    final product = j['product'] is Map
        ? Map<String, dynamic>.from(j['product'] as Map)
        : null;
    final shipment = j['shipment'] is Map
        ? Map<String, dynamic>.from(j['shipment'] as Map)
        : null;

    return Disposal(
      id: (j['id'] as num?)?.toInt() ?? 0,
      barcode: (j['barcode'] ?? product?['barcode'])?.toString(),
      productName: (product?['name'] ?? j['product_name'])?.toString(),
      quantity: (j['quantity'] as num?)?.toInt() ?? 0,
      damageReason: (j['damage_reason'] ?? j['reason'])?.toString(),
      status: j['status']?.toString(),
      shipmentName:
          (shipment?['name'] ?? j['shipment_name'] ?? j['warehouse_name'])
              ?.toString(),
      createdAt: DateTime.tryParse(j['created_at']?.toString() ?? ''),
    );
  }

  // العنوان المعروض بالكرت (اسم المنتج لو موجود، وإلا الباركود، وإلا رقم الطلب)
  String get displayTitle => productName ?? barcode ?? shipmentName ?? '#$id';
}

class DisposalsResponse {
  final List<Disposal> items;
  const DisposalsResponse({required this.items});

  factory DisposalsResponse.fromJson(dynamic body) {
    // الباك ممكن يرجع List مباشرة أو Map فيها {"data": [...]} — نتعامل مع الاتنين
    List<dynamic> raw;
    if (body is List) {
      raw = body;
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