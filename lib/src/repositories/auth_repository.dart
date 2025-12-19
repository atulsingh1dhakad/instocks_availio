// lib/src/repositories/auth_repository.dart
import '../services/auth_service.dart';

class AuthRepository {
  final AuthService _service;
  AuthRepository(this._service);

  Future<bool> isLoggedIn() => _service.isTokenValid();

  Future<void> persistToken(String token, int expiryMillis) =>
      _service.persistToken(token, expiryMillis);

  Future<void> deleteToken() => _service.clearToken();

  Future<String?> getToken() => _service.getToken();

  /// Restore token into in-memory holder (convenience)
  Future<void> restoreTokenToMemory() => AuthService.restoreToMemory();
}