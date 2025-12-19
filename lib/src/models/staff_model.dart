// lib/src/models/staff_model.dart
class StaffModel {
  final int productIdFallback = 0; // not used, placeholder
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? role;
  final String? status;
  final String? avatar;
  final Map<String, dynamic> raw;

  StaffModel({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.role,
    this.status,
    this.avatar,
    required this.raw,
  });

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    return StaffModel(
      id: (json['user_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      role: (json['role'] ?? json['user_type'] ?? '').toString(),
      status: json['status']?.toString(),
      avatar: json['avatar']?.toString() ?? json['image']?.toString(),
      raw: Map<String, dynamic>.from(json),
    );
  }

  Map<String, dynamic> toJson() => raw;
}