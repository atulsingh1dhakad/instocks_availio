// lib/src/models/user_profile.dart
class UserProfile {
  final String name;
  final String type;
  final String email;
  final String phone;
  final String userId;
  final String storeId;
  final Map<String, dynamic> raw;

  UserProfile({
    required this.name,
    required this.type,
    required this.email,
    required this.phone,
    required this.userId,
    required this.storeId,
    required this.raw,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: (json['name'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      userId: (json['user_id'] ?? json['id'] ?? '').toString(),
      storeId: (json['store_id'] ?? '').toString(),
      raw: Map<String, dynamic>.from(json),
    );
  }

  Map<String, dynamic> toJson() => raw;
}