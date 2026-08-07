// lib/models/order_model.dart
//
// نماذج بيانات مهام العامل القادمة من الباك إند. تغطي:
//   - قائمة المهام:            GET  /workers/tasks
//   - تفاصيل مهمة واحدة:       GET  /workers/tasks/{id}
//   - نتيجة مسح باركود:        POST /workers/tasks/{id}/scan
//   - عناصر ناقصة عند الإكمال: POST /workers/tasks/{id}/complete (409)

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
  });

  factory WorkerTask.fromJson(Map<String, dynamic> j) {
    final related = j['related'] is Map
        ? Map<String, dynamic>.from(j['related'] as Map)
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
    );
  }

  String get displayTitle {
    final entity = relatedEntityType ?? 'Order';
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
      barcode: (product['barcode'] ?? product['piece_barcode'])?.toString(),
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
}

class ScanResult {
  final bool matched;
  final ScanProduct? product;
  final String? warning;
  final List<ScanProgressItem> progressItems;

  const ScanResult({
    required this.matched,
    this.product,
    this.warning,
    required this.progressItems,
  });

  factory ScanResult.fromJson(Map<String, dynamic> j) {
    final progress = j['progress'] is Map
        ? Map<String, dynamic>.from(j['progress'] as Map)
        : null;
    final itemsJson = progress?['items'];

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
    qty: ((j['received'] ?? j['picked'] ?? j['restocked'] ?? 0) as num).toInt(),
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
