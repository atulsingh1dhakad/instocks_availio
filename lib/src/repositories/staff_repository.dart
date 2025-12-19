// lib/src/repositories/staff_repository.dart
import '../models/staff_model.dart';
import '../services/staff_service.dart';

class StaffRepository {
  final StaffService service;
  StaffRepository({required this.service});

  Future<List<StaffModel>> getStaff() => service.fetchStaff();

  Future<void> addStaff(Map<String, dynamic> payload) => service.createStaff(payload);

  Future<void> removeStaff(String userId) => service.deleteStaff(userId);
}