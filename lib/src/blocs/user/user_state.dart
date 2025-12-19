// lib/src/blocs/user/user_state.dart
import 'package:equatable/equatable.dart';
import '../../models/user_profile.dart';

abstract class UserState extends Equatable {
  const UserState();
  @override
  List<Object?> get props => [];
}

class UserInitial extends UserState {}

class UserLoadInProgress extends UserState {}

class UserLoadSuccess extends UserState {
  final UserProfile profile;
  const UserLoadSuccess(this.profile);
  @override
  List<Object?> get props => [profile];
}

class UserLoadFailure extends UserState {
  final String message;
  const UserLoadFailure(this.message);
  @override
  List<Object?> get props => [message];
}