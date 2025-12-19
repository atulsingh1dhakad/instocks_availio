// lib/src/blocs/user/user_event.dart
import 'package:equatable/equatable.dart';

abstract class UserEvent extends Equatable {
  const UserEvent();
  @override
  List<Object?> get props => [];
}

class LoadUserProfile extends UserEvent {}

class RefreshUserProfile extends UserEvent {}