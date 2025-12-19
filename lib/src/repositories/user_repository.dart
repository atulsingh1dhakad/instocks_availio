// lib/src/repositories/user_repository.dart
import '../models/user_profile.dart';
import '../services/user_service.dart';

class UserRepository {
  final UserService service;
  UserRepository({required this.service});

  Future<UserProfile> getProfile() => service.fetchProfile();
}