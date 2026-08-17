class DriverProfile {
  final String fullName;
  final String userName;
  final String phoneNumber;
  final String? birthday;
  final String? imageUrl;
  final String role;
  final int? warehouseId;

  const DriverProfile({
    required this.fullName,
    required this.userName,
    required this.phoneNumber,
    this.birthday,
    this.imageUrl,
    required this.role,
    this.warehouseId,
  });

  factory DriverProfile.fromJson(
    Map<String, dynamic> json, {
    String? apiBaseUrl,
  }) {
    final nestedProfile = json['profile'];
    final profile = nestedProfile is Map
        ? Map<String, dynamic>.from(nestedProfile)
        : json;
    final employee = json['employee'] is Map
        ? Map<String, dynamic>.from(json['employee'] as Map)
        : json;

    return DriverProfile(
      fullName: profile['full_name']?.toString() ?? '',
      userName: profile['user_name']?.toString() ?? '',
      phoneNumber: profile['phone_number']?.toString() ?? '',
      birthday: profile['birthday']?.toString(),
      imageUrl: _normalizeImageUrl(
        profile['profile_image']?.toString(),
        apiBaseUrl,
      ),
      role: employee['role']?.toString() ?? 'driver',
      warehouseId: (employee['warehouse_id'] as num?)?.toInt(),
    );
  }
}

String? _normalizeImageUrl(String? value, String? apiBaseUrl) {
  if (value == null || value.trim().isEmpty) return null;
  if (apiBaseUrl == null || apiBaseUrl.trim().isEmpty) return value;

  final imageUri = Uri.tryParse(value);
  final apiUri = Uri.tryParse(apiBaseUrl);
  if (imageUri == null || apiUri == null || apiUri.host.isEmpty) return value;

  final isLoopback =
      imageUri.host == '127.0.0.1' || imageUri.host == 'localhost';
  if (imageUri.hasScheme && !isLoopback) return value;

  var path = imageUri.path;
  if (!path.startsWith('/')) path = '/$path';

  return Uri(
    scheme: apiUri.scheme,
    host: apiUri.host,
    port: apiUri.hasPort ? apiUri.port : null,
    path: path,
    query: imageUri.hasQuery ? imageUri.query : null,
  ).toString();
}
