// lib/src/blocs/staff/staff_event.dart
import 'package:equatable/equatable.dart';

abstract class StaffEvent extends Equatable {
  const StaffEvent();
  @override
  List<Object?> get props => [];
}

class LoadStaff extends StaffEvent {}

class RefreshStaff extends StaffEvent {}

class AddStaff extends StaffEvent {
  final Map<String, dynamic> payload;
  const AddStaff(this.payload);
  @override
  List<Object?> get props => [payload];
}

class DeleteStaff extends StaffEvent {
  final String userId;
  const DeleteStaff(this.userId);
  @override
  List<Object?> get props => [userId];
}