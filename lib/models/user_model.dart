// lib/models/user_model.dart
//
// نموذج العامل (Worker) الذي يُعاد من الـ Backend عند تسجيل الدخول.
// يُستخدم لتخزين بيانات العامل المسجّل دخوله داخل AuthService و AuthProvider.
//
// الـ Backend يُعيد الـ worker بهذا الشكل:
// {
//   "id": 1,
//   "role": "driver" | "staff",
//   "status": "available" | "busy",
//   "salary": "750.50",
//   "warehouse_id": 1,
//   "owner_id": 1,
//   "system_user": {
//     "id": 5,
//     "full_name": "lilas",
//     "user_name": "lilas_95",
//     "phone_number": "0996282957"
//   }
// }

class UserModel {
  final int id;
  final String role;        // 'driver' أو 'staff' (أو 'manager' / 'warehouse_secretary' من لوحة الـ Dashboard لكن تطبيق العمال لا يدعمها)
  final String status;      // 'available' أو 'busy'
  final String salary;
  final int warehouseId;
  final int? ownerId;
  final SystemUserInfo systemUser;

  const UserModel({
    required this.id,
    required this.role,
    required this.status,
    required this.salary,
    required this.warehouseId,
    this.ownerId,
    required this.systemUser,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final systemUserJson =
        json['system_user'] is Map<String, dynamic>
            ? json['system_user'] as Map<String, dynamic>
            : <String, dynamic>{};

    return UserModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      role: json['role']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      salary: json['salary']?.toString() ?? '0',
      warehouseId: (json['warehouse_id'] as num?)?.toInt() ?? 0,
      ownerId: (json['owner_id'] as num?)?.toInt(),
      systemUser: SystemUserInfo.fromJson(systemUserJson),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role,
        'status': status,
        'salary': salary,
        'warehouse_id': warehouseId,
        if (ownerId != null) 'owner_id': ownerId,
        'system_user': systemUser.toJson(),
      };

  /// اختصار لمعرفة هل العامل الحالي هو سائق.
  bool get isDriver => role == 'driver';

  /// اختصار لمعرفة هل العامل الحالي هو موظف مستودع.
  bool get isStaff => role == 'staff';
}

class SystemUserInfo {
  final int id;
  final String fullName;
  final String userName;
  final String phoneNumber;

  const SystemUserInfo({
    required this.id,
    required this.fullName,
    required this.userName,
    required this.phoneNumber,
  });

  factory SystemUserInfo.fromJson(Map<String, dynamic> json) {
    return SystemUserInfo(
      id: (json['id'] as num?)?.toInt() ?? 0,
      fullName: json['full_name']?.toString() ?? '',
      userName: json['user_name']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'user_name': userName,
        'phone_number': phoneNumber,
      };
}
