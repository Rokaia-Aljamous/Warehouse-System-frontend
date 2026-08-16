// lib/models/order_model.dart
//
// نماذج بيانات مهام العامل القادمة من الباك إند. تغطي:
//   - قائمة المهام:                 GET  /workers/tasks
//   - تفاصيل مهمة (عام):           GET  /workers/tasks/{taskId}       (Receiving/Returns/Destruction)
//   - تفاصيل مهمة Order preparation: GET  /workers/orders/{orderId}     (Task.related_id)
//   - نتيجة مسح باركود:             POST /workers/tasks/{taskId}/scan
//   - عناصر ناقصة عند الإكمال:      POST /workers/tasks/{taskId}/complete (409)

enum TaskType {
  orderPreparation('order_preparation'),
  orderDelivery('order_delivery'),
  transferPreparation('transfer_preparation'),
  transferDelivery('transfer_delivery'),
  shipmentReceiving('shipment_receiving'),
  damageDisposal('damage_disposal'),
  returnPickup('return_pickup'),
  restockProduct('restock_product');

  final String value;
  const TaskType(this.value);

  static TaskType? fromString(String? v) {
    for (final t in TaskType.values) {
      if (t.value == v) return t;
    }
    return null;
  }
}

enum TaskStatus {
  inPreparation('in_preparation'),
  completed('completed');

  final String value;
  const TaskStatus(this.value);

  static TaskStatus? fromString(String? v) {
    for (final s in TaskStatus.values) {
      if (s.value == v) return s;
    }
    return null;
  }
}

class WorkerTask {
  final int id;
  final TaskType? taskType;
  final TaskStatus? status;
  final int? relatedId;
  final String? relatedType;
  final String? relatedEntityType;
  final String? relatedStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // ---- خاص فقط بمهام الإتلاف الرسمية (task_type: damage_disposal) ----
  // هاي المهمة الوحيدة يلي بترجع منتجها وكميتها مباشرة على مستوى التاسك
  // (مافي "related" — related_id/related_type بيضلو null دايمًا إلها).
  final int? disposalProductId;
  final String? disposalProductName;
  final String? disposalBarcode;
  final int disposalQuantity;
  final int disposalScannedQuantity;
  final String? assignedByName; // من "superadmin.full_name"

  const WorkerTask({
    required this.id,
    this.taskType,
    this.status,
    this.relatedId,
    this.relatedType,
    this.relatedEntityType,
    this.relatedStatus,
    this.createdAt,
    this.updatedAt,
    this.disposalProductId,
    this.disposalProductName,
    this.disposalBarcode,
    this.disposalQuantity = 0,
    this.disposalScannedQuantity = 0,
    this.assignedByName,
  });

  factory WorkerTask.fromJson(Map<String, dynamic> j) {
    final related = j['related'] is Map
        ? Map<String, dynamic>.from(j['related'] as Map)
        : null;

    // منتج مهمة الإتلاف (damage_disposal) — يجي مباشرة كـ "product" على
    // التاسك نفسو، مش جوا "related". الباركود الحقيقي للمسح هو
    // parcel_barcode (نفس مبدأ TaskOrderItem تحت).
    final disposalProduct = j['product'] is Map
        ? Map<String, dynamic>.from(j['product'] as Map)
        : null;

    final superadmin = j['superadmin'] is Map
        ? Map<String, dynamic>.from(j['superadmin'] as Map)
        : null;

    return WorkerTask(
      id: (j['id'] as num?)?.toInt() ?? 0,
      taskType: TaskType.fromString(j['task_type']?.toString()),
      status: TaskStatus.fromString(j['status']?.toString()),
      relatedId: (j['related_id'] as num?)?.toInt(),
      relatedType: j['related_type']?.toString(),
      relatedEntityType: related?['type']?.toString(),
      relatedStatus: related?['status']?.toString(),
      createdAt: DateTime.tryParse(j['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(j['updated_at']?.toString() ?? ''),
      disposalProductId: (disposalProduct?['id'] as num?)?.toInt(),
      disposalProductName: disposalProduct?['name']?.toString(),
      disposalBarcode: (disposalProduct?['parcel_barcode'] ??
              disposalProduct?['barcode'] ??
              disposalProduct?['piece_barcode'])
          ?.toString(),
      disposalQuantity: (j['disposal_quantity'] as num?)?.toInt() ?? 0,
      disposalScannedQuantity:
          (j['disposal_scanned_quantity'] as num?)?.toInt() ?? 0,
      assignedByName: superadmin?['full_name']?.toString(),
    );
  }

  bool get isDamageDisposal => taskType == TaskType.damageDisposal;
  int get disposalRemaining =>
      (disposalQuantity - disposalScannedQuantity).clamp(0, disposalQuantity);

  // تسمية مقروءة حسب نوع المهمة — تُستخدم كـ fallback لما الباك إند ما يرجّع
  // "related" (زي حالات الاختبار الحالية)، ومفيدة أيضاً بشاشة "مهامي" يلي
  // بتعرض كل الأنواع مع بعض فمهم نوضح شو نوع كل كرت.
  String get _taskTypeLabel {
    switch (taskType) {
      case TaskType.orderPreparation:
        return 'Order';
      case TaskType.orderDelivery:
        return 'Delivery';
      case TaskType.transferPreparation:
        return 'Transfer';
      case TaskType.transferDelivery:
        return 'Transfer Delivery';
      case TaskType.shipmentReceiving:
        return 'Shipment';
      case TaskType.returnPickup:
        return 'Return';
      case TaskType.restockProduct:
        return 'Return';
      case TaskType.damageDisposal:
        return 'Disposal';
      case null:
        return 'Task';
    }
  }

  String get displayTitle {
    if (isDamageDisposal) {
      return disposalProductName ?? 'Product #${disposalProductId ?? id}';
    }
    final entity = relatedEntityType ?? _taskTypeLabel;
    return '$entity #${relatedId ?? id}';
  }
}

class WorkerTasksResponse {
  final List<WorkerTask> inPreparation;
  final List<WorkerTask> completed;

  const WorkerTasksResponse({
    required this.inPreparation,
    required this.completed,
  });

  factory WorkerTasksResponse.fromJson(Map<String, dynamic> j) {
    List<WorkerTask> parseList(dynamic v) {
      if (v is List) {
        return v
            .whereType<Map>()
            .map((e) => WorkerTask.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      return [];
    }

    return WorkerTasksResponse(
      inPreparation: parseList(j['in_preparation']),
      completed: parseList(j['completed']),
    );
  }
}

class TaskOrderItem {
  final int id;
  final int? productId;
  final String productName;
  final String? brand;
  final String? barcode;
  final int expectedQty;
  int pickedQty;

  TaskOrderItem({
    required this.id,
    this.productId,
    required this.productName,
    this.brand,
    this.barcode,
    required this.expectedQty,
    required this.pickedQty,
  });

  factory TaskOrderItem.fromJson(Map<String, dynamic> j) {
    final nestedOrderItem = j['order_item'] is Map
        ? Map<String, dynamic>.from(j['order_item'] as Map)
        : null;
    final productJson = (nestedOrderItem?['product'] ?? j['product']);
    final product = productJson is Map
        ? Map<String, dynamic>.from(productJson)
        : <String, dynamic>{};

    final qty = (j['quantity'] as num?)?.toInt() ?? 0;
    final picked =
        (j['picked_quantity'] ??
                j['received_quantity'] ??
                j['restocked_quantity'])
            as num?;

    return TaskOrderItem(
      id: (j['id'] as num?)?.toInt() ?? 0,
      productId:
          (j['product_id'] as num?)?.toInt() ??
          (product['id'] as num?)?.toInt(),
      productName: product['name']?.toString() ?? 'Product',
      brand: product['brand']?.toString(),
      // الباركود الحقيقي للمسح هو parcel_barcode (piece_barcode مش باركود فعلي،
      // مثلاً "2" — مجرد قيمة داخلية بالباك إند).
      barcode: (product['parcel_barcode'] ??
              product['barcode'] ??
              product['piece_barcode'])
          ?.toString(),
      expectedQty: qty,
      pickedQty: picked?.toInt() ?? 0,
    );
  }

  int get remaining => (expectedQty - pickedQty).clamp(0, expectedQty);
  bool get isComplete => expectedQty > 0 && pickedQty >= expectedQty;

  ItemScanState get scanState {
    if (isComplete) return ItemScanState.done;
    if (pickedQty > 0) return ItemScanState.partial;
    return ItemScanState.pending;
  }
}

enum ItemScanState { pending, partial, done }

class TaskDetail {
  final WorkerTask task;
  final String? relatedEntityType;
  final int? customerId;
  final String? customerName;
  final String? factoryName;
  final String? returnReason; // خاص بمهام Returns (Return.return_reason)
  final String? returnType; // خاص بمهام Returns (Return.return_type)
  final int? relatedOrderId; // خاص بمهام Receiving (Shipment.factory_name)
  final List<TaskOrderItem> items;

  const TaskDetail({
    required this.task,
    this.relatedEntityType,
    this.customerId,
    this.customerName,
    this.factoryName,
    this.returnReason,
    this.returnType,
    this.relatedOrderId,
    required this.items,
  });

  factory TaskDetail.fromJson(Map<String, dynamic> j) {
    // ============================================================
    // الحالة الحقيقية الوحيدة يلي بتستخدم هاد الـ fromJson العام حاليًا:
    // مهام الإتلاف الرسمية (damage_disposal) عبر GET /workers/tasks/{taskId}.
    // الباك بيرجع التاسك مباشرة (نفس شكل عنصر قائمة /workers/tasks تمامًا):
    // {id, task_type, status, product: {...}, disposal_quantity,
    //  disposal_scanned_quantity, ...} — بدون "task"/"related" wrapper.
    // ============================================================
    if (j['task'] == null &&
        (j['task_type'] != null ||
            j['product'] != null ||
            j['disposal_quantity'] != null)) {
      final task = WorkerTask.fromJson(j);
      final product = j['product'] is Map
          ? Map<String, dynamic>.from(j['product'] as Map)
          : null;

      final expected = (j['disposal_quantity'] as num?)?.toInt() ?? 0;
      final scanned = (j['disposal_scanned_quantity'] as num?)?.toInt() ?? 0;

      final items = product != null
          ? [
              TaskOrderItem(
                id: (product['id'] as num?)?.toInt() ?? 0,
                productId: (product['id'] as num?)?.toInt(),
                productName: product['name']?.toString() ?? 'Product',
                brand: product['brand']?.toString(),
                barcode: (product['parcel_barcode'] ??
                        product['barcode'] ??
                        product['piece_barcode'])
                    ?.toString(),
                expectedQty: expected,
                pickedQty: scanned,
              ),
            ]
          : <TaskOrderItem>[];

      return TaskDetail(
        task: task,
        relatedEntityType: 'Destruction',
        items: items,
      );
    }

    // ============================================================
    // شكل احتياطي (task/related wrapper) — لأي نوع مهمة تاني ممكن يستخدم
    // نفس الـ endpoint العام مستقبلاً بهاي البنية.
    // ============================================================
    final task = WorkerTask.fromJson(
      j['task'] is Map ? Map<String, dynamic>.from(j['task'] as Map) : {},
    );

    final related = j['related'] is Map
        ? Map<String, dynamic>.from(j['related'] as Map)
        : null;
    final data = related?['data'] is Map
        ? Map<String, dynamic>.from(related!['data'] as Map)
        : null;

    final itemsJson = data?['items'];
    final items = itemsJson is List
        ? itemsJson
              .whereType<Map>()
              .map((e) => TaskOrderItem.fromJson(Map<String, dynamic>.from(e)))
              .toList()
        : <TaskOrderItem>[];

    final customer = data?['customer'] is Map
        ? Map<String, dynamic>.from(data!['customer'] as Map)
        : null;

    final orderJson = data?['order'] is Map
        ? Map<String, dynamic>.from(data!['order'] as Map)
        : null;

    return TaskDetail(
      task: task,
      relatedEntityType: related?['type']?.toString(),
      customerId: (customer?['id'] as num?)?.toInt(),
      customerName:
          customer?['full_name']?.toString() ?? customer?['name']?.toString(),
      factoryName: data?['factory_name']?.toString(),
      returnReason: data?['return_reason']?.toString(),
      returnType: data?['return_type']?.toString(),
      relatedOrderId:
          (data?['order_id'] as num?)?.toInt() ??
          (orderJson?['id'] as num?)?.toInt(),
      items: items,
    );
  }

  bool get allItemsComplete =>
      items.isNotEmpty && items.every((i) => i.isComplete);

  // ============================================================
  // تفاصيل مهمة "تحضير طلب" فقط — GET /workers/orders/{orderId}
  // بنية مختلفة تمامًا عن fromJson العامة فوق: مافي "task"/"related" wrapper،
  // البيانات مباشرة تحت "order" + "progress".
  // الـ [task] هون هو الكائن الأساسي من قائمة المهام (WorkerTask) اللي عنده
  // Task ID الصحيح (يلزم لاحقًا لعمليات scan/complete).
  // ============================================================
  factory TaskDetail.fromOrderJson(
    Map<String, dynamic> j, {
    required WorkerTask task,
  }) {
    final order = j['order'] is Map
        ? Map<String, dynamic>.from(j['order'] as Map)
        : <String, dynamic>{};

    final customer = order['customer'] is Map
        ? Map<String, dynamic>.from(order['customer'] as Map)
        : null;

    final itemsJson = order['items'];
    final items = itemsJson is List
        ? itemsJson
              .whereType<Map>()
              .map((e) => TaskOrderItem.fromJson(Map<String, dynamic>.from(e)))
              .toList()
        : <TaskOrderItem>[];

    return TaskDetail(
      task: task,
      relatedEntityType: 'Order',
      customerId: (customer?['id'] as num?)?.toInt(),
      customerName: customer?['full_name']?.toString(),
      factoryName: null,
      returnReason: null,
      returnType: null,
      relatedOrderId: (order['id'] as num?)?.toInt(),
      items: items,
    );
  }

  // ============================================================
  // تفاصيل مهمة "استلام شحنة" فقط — GET /workers/shipments/{shipmentId}
  // نفس بنية fromOrderJson تمامًا لكن الجذر هون "shipment" مش "order"،
  // ومافي customer (الشحنة جايي من مصنع لا من زبون).
  // الـ [task] هون هو الكائن الأساسي من قائمة المهام (WorkerTask) اللي عنده
  // Task ID الصحيح (يلزم لاحقًا لعمليات scan/complete).
  // ============================================================
  factory TaskDetail.fromShipmentJson(
    Map<String, dynamic> j, {
    required WorkerTask task,
  }) {
    final shipment = j['shipment'] is Map
        ? Map<String, dynamic>.from(j['shipment'] as Map)
        : <String, dynamic>{};

    final itemsJson = shipment['items'];
    final items = itemsJson is List
        ? itemsJson
              .whereType<Map>()
              .map((e) => TaskOrderItem.fromJson(Map<String, dynamic>.from(e)))
              .toList()
        : <TaskOrderItem>[];

    return TaskDetail(
      task: task,
      relatedEntityType: 'Shipment',
      customerId: null,
      customerName: null,
      factoryName: shipment['factory_name']?.toString(),
      returnReason: null,
      returnType: null,
      relatedOrderId: (shipment['id'] as num?)?.toInt(),
      items: items,
    );
  }

  // ============================================================
  // تفاصيل مهمة "مرتجع" فقط — GET /workers/returns/{returnId}
  // الجذر هون "return"، وفيه return_reason/return_type مباشرة، والعناصر
  // كل وحدة فيها order_item متضمّن product جواتو (مو نفس بنية shipment/order
  // اللي فيها product مباشرة على العنصر). TaskOrderItem.fromJson أصلاً
  // بيتحقق من order_item.product كأولوية، فما في داعي لتعديل عليه.
  // ملاحظة: الباك إند ما بيرجع اسم/بيانات الزبون هون (بس order.customer_id
  // كرقم)، فـ customerName بتضل null بقصد.
  // ============================================================
  factory TaskDetail.fromReturnJson(
    Map<String, dynamic> j, {
    required WorkerTask task,
  }) {
    final ret = j['return'] is Map
        ? Map<String, dynamic>.from(j['return'] as Map)
        : <String, dynamic>{};

    final itemsJson = ret['items'];
    final items = itemsJson is List
        ? itemsJson
              .whereType<Map>()
              .map((e) => TaskOrderItem.fromJson(Map<String, dynamic>.from(e)))
              .toList()
        : <TaskOrderItem>[];

    final orderJson = ret['order'] is Map
        ? Map<String, dynamic>.from(ret['order'] as Map)
        : null;

    return TaskDetail(
      task: task,
      relatedEntityType: 'Return',
      customerId: (orderJson?['customer_id'] as num?)?.toInt(),
      customerName: null,
      factoryName: null,
      returnReason: ret['return_reason']?.toString(),
      returnType: ret['return_type']?.toString(),
      relatedOrderId:
          (ret['order_id'] as num?)?.toInt() ??
          (orderJson?['id'] as num?)?.toInt(),
      items: items,
    );
  }
}

class ScanResult {
  final bool matched;
  final ScanProduct? product;
  final String? warning;
  final ScanProgress? progress;
  final List<ScanProgressItem> progressItems;

  const ScanResult({
    required this.matched,
    this.product,
    this.warning,
    this.progress,
    required this.progressItems,
  });

  factory ScanResult.fromJson(Map<String, dynamic> j) {
    final progressJson = j['progress'] is Map
        ? Map<String, dynamic>.from(j['progress'] as Map)
        : null;
    final itemsJson = progressJson?['items'];

    String? warning = j['warning']?.toString();
    if (warning == null && j['warnings'] is List) {
      final list = j['warnings'] as List;
      if (list.isNotEmpty) warning = list.first?.toString();
    }

    return ScanResult(
      matched: j['matched'] == true,
      product: j['product'] is Map
          ? ScanProduct.fromJson(Map<String, dynamic>.from(j['product']))
          : null,
      warning: warning,
      progress: progressJson != null ? ScanProgress.fromJson(progressJson) : null,
      progressItems: itemsJson is List
          ? itemsJson
                .whereType<Map>()
                .map(
                  (e) =>
                      ScanProgressItem.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : [],
    );
  }
}

// تقدّم المنتج المفرد المطابق للباركود المرسول بهاد النداء تحديدًا
// (وليس كل عناصر المهمة) — هيك بيرجعه الباك إند الحقيقي.
class ScanProgress {
  final int expected;
  final int scanned;
  final int remaining;
  final bool complete;

  const ScanProgress({
    required this.expected,
    required this.scanned,
    required this.remaining,
    required this.complete,
  });

  factory ScanProgress.fromJson(Map<String, dynamic> j) => ScanProgress(
    expected: (j['expected'] as num?)?.toInt() ?? 0,
    scanned: (j['scanned'] as num?)?.toInt() ?? (j['picked'] as num?)?.toInt() ?? 0,
    remaining: (j['remaining'] as num?)?.toInt() ?? 0,
    complete: j['complete'] == true,
  );
}

class ScanProduct {
  final int id;
  final String name;
  final String? barcode;

  const ScanProduct({required this.id, required this.name, this.barcode});

  factory ScanProduct.fromJson(Map<String, dynamic> j) => ScanProduct(
    id: (j['id'] as num?)?.toInt() ?? 0,
    name: j['name']?.toString() ?? '',
    barcode: j['barcode']?.toString(),
  );
}

class ScanProgressItem {
  final String product;
  final int expected;
  final int qty;

  const ScanProgressItem({
    required this.product,
    required this.expected,
    required this.qty,
  });

  factory ScanProgressItem.fromJson(Map<String, dynamic> j) => ScanProgressItem(
    product: j['product']?.toString() ?? '',
    expected: (j['expected'] as num?)?.toInt() ?? 0,
    qty: ((j['picked'] ?? j['received'] ?? j['restocked'] ?? 0) as num).toInt(),
  );
}

class RemainingItem {
  final int? productId;
  final String product;
  final int expected;
  final int scanned;
  final int remaining;

  const RemainingItem({
    this.productId,
    required this.product,
    required this.expected,
    required this.scanned,
    required this.remaining,
  });

  factory RemainingItem.fromJson(Map<String, dynamic> j) => RemainingItem(
    productId: (j['product_id'] as num?)?.toInt(),
    product: j['product']?.toString() ?? '',
    expected: (j['expected'] as num?)?.toInt() ?? 0,
    scanned: (j['scanned'] as num?)?.toInt() ?? 0,
    remaining: (j['remaining'] as num?)?.toInt() ?? 0,
  );
}
