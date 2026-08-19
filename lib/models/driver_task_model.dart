enum DriverTaskType {
  orderDelivery('order_delivery'),
  transferDelivery('transfer_delivery'),
  returnPickup('return_pickup');

  final String value;
  const DriverTaskType(this.value);

  static DriverTaskType? fromString(String? value) {
    for (final type in values) {
      if (type.value == value) return type;
    }
    return null;
  }
}

class DriverTaskItem {
  final int? productId;
  final String name;
  final int quantity;

  const DriverTaskItem({
    this.productId,
    required this.name,
    required this.quantity,
  });

  factory DriverTaskItem.fromJson(Map<String, dynamic> json) {
    return DriverTaskItem(
      productId: (json['product_id'] as num?)?.toInt(),
      name: json['product_name']?.toString() ?? 'Product',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    );
  }

  factory DriverTaskItem.fromReturnJson(Map<String, dynamic> json) {
    final orderItem = _asMap(json['order_item']);
    final product = _asMap(orderItem['product']);

    return DriverTaskItem(
      productId:
          (product['id'] as num?)?.toInt() ??
          (orderItem['product_id'] as num?)?.toInt(),
      name: product['name']?.toString() ?? 'Product',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    );
  }
}

class DriverTask {
  final int id;
  final DriverTaskType? type;
  final String status;
  final int? relatedId;
  final int? orderId;
  final String? relatedType;
  final String? relatedStatus;
  final int? customerId;
  final String? customerName;
  final String? customerPhone;
  final String? destinationLabel;
  final String? deliveryRegion;
  final double? destinationLatitude;
  final double? destinationLongitude;
  final String? orderQrCode;
  final double? totalPrice;
  final int? itemsCount;
  final String? returnReason;
  final String? returnType;
  final String? fromWarehouseName;
  final String? fromWarehouseLocation;
  final String? toWarehouseName;
  final String? toWarehouseLocation;
  final List<DriverTaskItem> items;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DriverTask({
    required this.id,
    required this.type,
    required this.status,
    this.relatedId,
    this.orderId,
    this.relatedType,
    this.relatedStatus,
    this.customerId,
    this.customerName,
    this.customerPhone,
    this.destinationLabel,
    this.deliveryRegion,
    this.destinationLatitude,
    this.destinationLongitude,
    this.orderQrCode,
    this.totalPrice,
    this.itemsCount,
    this.returnReason,
    this.returnType,
    this.fromWarehouseName,
    this.fromWarehouseLocation,
    this.toWarehouseName,
    this.toWarehouseLocation,
    this.items = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory DriverTask.fromJson(Map<String, dynamic> json) {
    final related = _asMap(json['related']);
    final customer = _asMap(related['customer']);
    final fromWarehouse = _asMap(related['from_warehouse']);
    final toWarehouse = _asMap(related['to_warehouse']);
    final rawItems = related['returned_items'];
    final type = DriverTaskType.fromString(json['task_type']?.toString());
    final relatedId = (json['related_id'] as num?)?.toInt();

    return DriverTask(
      id: (json['id'] as num?)?.toInt() ?? 0,
      type: type,
      status: json['status']?.toString() ?? '',
      relatedId: relatedId,
      orderId:
          (related['order_id'] as num?)?.toInt() ??
          (type == DriverTaskType.orderDelivery ? relatedId : null),
      relatedType: json['related_type']?.toString(),
      relatedStatus: related['status']?.toString(),
      customerId: (customer['id'] as num?)?.toInt(),
      customerName: customer['full_name']?.toString(),
      customerPhone: customer['phone_number']?.toString(),
      destinationLabel: related['customer_location']?.toString(),
      deliveryRegion: related['delivery_region']?.toString(),
      destinationLatitude: _asDouble(related['customer_latitude']),
      destinationLongitude: _asDouble(related['customer_longitude']),
      orderQrCode: related['order_qr_code']?.toString(),
      totalPrice: _asDouble(related['total_price']),
      itemsCount: (related['items_count'] as num?)?.toInt(),
      returnReason: related['return_reason']?.toString(),
      returnType: related['return_type']?.toString(),
      fromWarehouseName: fromWarehouse['name']?.toString(),
      fromWarehouseLocation: fromWarehouse['location']?.toString(),
      toWarehouseName: toWarehouse['name']?.toString(),
      toWarehouseLocation: toWarehouse['location']?.toString(),
      items: rawItems is List
          ? rawItems
                .whereType<Map>()
                .map(
                  (item) =>
                      DriverTaskItem.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : const [],
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
    );
  }

  DriverTask withOrderDetails(Map<String, dynamic> order) {
    final customer = _asMap(order['customer']);
    final orderItems = order['items'];

    return DriverTask(
      id: id,
      type: type,
      status: status,
      relatedId: relatedId,
      orderId: (order['id'] as num?)?.toInt() ?? orderId,
      relatedType: relatedType,
      relatedStatus: order['status']?.toString() ?? relatedStatus,
      customerId: (customer['id'] as num?)?.toInt() ?? customerId,
      customerName: customer['full_name']?.toString() ?? customerName,
      customerPhone: customer['phone_number']?.toString() ?? customerPhone,
      destinationLabel:
          order['customer_location']?.toString() ?? destinationLabel,
      deliveryRegion: order['delivery_region']?.toString() ?? deliveryRegion,
      destinationLatitude:
          _asDouble(order['customer_latitude']) ?? destinationLatitude,
      destinationLongitude:
          _asDouble(order['customer_longitude']) ?? destinationLongitude,
      orderQrCode: order['order_qr_code']?.toString() ?? orderQrCode,
      totalPrice: _asDouble(order['total_price']) ?? totalPrice,
      itemsCount: orderItems is List ? orderItems.length : itemsCount,
      returnReason: returnReason,
      returnType: returnType,
      fromWarehouseName: fromWarehouseName,
      fromWarehouseLocation: fromWarehouseLocation,
      toWarehouseName: toWarehouseName,
      toWarehouseLocation: toWarehouseLocation,
      items: items,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  DriverTask withReturnDetails(Map<String, dynamic> returnData) {
    final order = _asMap(returnData['order']);
    final rawItems = returnData['items'];

    return DriverTask(
      id: id,
      type: type,
      status: status,
      relatedId: relatedId,
      orderId:
          (returnData['order_id'] as num?)?.toInt() ??
          (order['id'] as num?)?.toInt() ??
          orderId,
      relatedType: relatedType,
      relatedStatus: returnData['status']?.toString() ?? relatedStatus,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      destinationLabel: destinationLabel,
      deliveryRegion: deliveryRegion,
      destinationLatitude: destinationLatitude,
      destinationLongitude: destinationLongitude,
      orderQrCode: order['order_qr_code']?.toString() ?? orderQrCode,
      totalPrice: totalPrice,
      itemsCount: rawItems is List ? rawItems.length : itemsCount,
      returnReason: returnData['return_reason']?.toString() ?? returnReason,
      returnType: returnData['return_type']?.toString() ?? returnType,
      fromWarehouseName: fromWarehouseName,
      fromWarehouseLocation: fromWarehouseLocation,
      toWarehouseName: toWarehouseName,
      toWarehouseLocation: toWarehouseLocation,
      items: rawItems is List
          ? rawItems
                .whereType<Map>()
                .map(
                  (item) => DriverTaskItem.fromReturnJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : items,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  bool get isCompleted => status == 'completed';

  bool get hasCoordinates =>
      destinationLatitude != null && destinationLongitude != null;

  String get typeLabel {
    switch (type) {
      case DriverTaskType.orderDelivery:
        return 'Order Delivery';
      case DriverTaskType.transferDelivery:
        return 'Transfer Delivery';
      case DriverTaskType.returnPickup:
        return 'Return Pickup';
      case null:
        return 'Delivery Task';
    }
  }

  String get referenceLabel {
    final reference = relatedId ?? id;
    switch (type) {
      case DriverTaskType.orderDelivery:
        return 'Order #$reference';
      case DriverTaskType.transferDelivery:
        return 'Transfer #$reference';
      case DriverTaskType.returnPickup:
        return 'Return #$reference';
      case null:
        return 'Task #$id';
    }
  }

  String get displayName {
    if (customerName != null && customerName!.trim().isNotEmpty) {
      return customerName!;
    }
    if (type == DriverTaskType.transferDelivery && toWarehouseName != null) {
      return toWarehouseName!;
    }
    return referenceLabel;
  }

  String get displayLocation {
    if (destinationLabel != null && destinationLabel!.trim().isNotEmpty) {
      return destinationLabel!;
    }
    if (type == DriverTaskType.transferDelivery) {
      return toWarehouseLocation ??
          'Destination warehouse location unavailable';
    }
    return deliveryRegion ?? 'Location unavailable';
  }
}

class DriverTasksResponse {
  final List<DriverTask> pending;
  final List<DriverTask> completed;

  const DriverTasksResponse({required this.pending, required this.completed});

  factory DriverTasksResponse.fromJson(Map<String, dynamic> json) {
    final pending = <DriverTask>[];
    final completed = <DriverTask>[];

    for (final key in const [
      'order_delivery',
      'transfer_delivery',
      'return_pickup',
    ]) {
      final group = _asMap(json[key]);
      pending.addAll(_parseTasks(group['in_preparation']));
      completed.addAll(_parseTasks(group['completed']));
    }

    int newestFirst(DriverTask a, DriverTask b) {
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    }

    pending.sort(newestFirst);
    completed.sort(newestFirst);

    return DriverTasksResponse(pending: pending, completed: completed);
  }
}

class DriverDailySummary {
  final DateTime? date;
  final int total;
  final int pending;
  final int completed;
  final double completionPercentage;

  const DriverDailySummary({
    this.date,
    required this.total,
    required this.pending,
    required this.completed,
    required this.completionPercentage,
  });

  const DriverDailySummary.empty()
    : date = null,
      total = 0,
      pending = 0,
      completed = 0,
      completionPercentage = 0;

  factory DriverDailySummary.fromJson(Map<String, dynamic> json) {
    return DriverDailySummary(
      date: DateTime.tryParse(json['date']?.toString() ?? ''),
      total: (json['total'] as num?)?.toInt() ?? 0,
      pending: (json['in_preparation'] as num?)?.toInt() ?? 0,
      completed: (json['completed'] as num?)?.toInt() ?? 0,
      completionPercentage: _asDouble(json['completion_percentage']) ?? 0,
    );
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

double? _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

List<DriverTask> _parseTasks(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((task) => DriverTask.fromJson(Map<String, dynamic>.from(task)))
      .toList();
}
