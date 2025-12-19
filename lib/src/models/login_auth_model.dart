// lib/src/models/auth_model.dart
class AuthModel {
  final String accessToken;
  final String tokenType;

  AuthModel({required this.accessToken, required this.tokenType});

  String get authorizationHeader => '${tokenType.trim()} ${accessToken.trim()}';

  Map<String, dynamic> toJson() => {
    'access_token': accessToken,
    'token_type': tokenType,
  };

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    return AuthModel(
      accessToken: (json['access_token'] ?? json['accessToken'] ?? '').toString(),
      tokenType: (json['token_type'] ?? json['tokenType'] ?? 'Bearer').toString(),
    );
  }
}