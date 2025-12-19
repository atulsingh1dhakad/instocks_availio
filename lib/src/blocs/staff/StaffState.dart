// lib/src/blocs/staff/staff_state.dart
import 'package:equatable/equatable.dart';
import '../../models/staff_model.dart';

abstract class StaffState extends Equatable {
  const StaffState();
  @override
  List<Object?> get props => [];
}

class StaffInitial extends StaffState {}

class StaffLoadInProgress extends StaffState {}

class StaffLoadSuccess extends StaffState {
  final List<StaffModel> staff;
  const StaffLoadSuccess(this.staff);
  @override
  List<Object?> get props => [staff];
}

class StaffLoadFailure extends StaffState {
  final String message;
  const StaffLoadFailure(this.message);
  @override
  List<Object?> get props => [message];
}

class StaffActionInProgress extends StaffState {}

class StaffActionSuccess extends StaffState {
  final String message;
  const StaffActionSuccess([this.message = 'Success']);
  @override
  List<Object?> get props => [message];
}

class StaffActionFailure extends StaffState {
  final String message;
  const StaffActionFailure(this.message);
  @override
  List<Object?> get props => [message];
}