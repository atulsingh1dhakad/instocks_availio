// lib/src/blocs/user/user_bloc.dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'user_event.dart';
import 'user_state.dart';
import '../../repositories/user_repository.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final UserRepository repository;

  UserBloc({required this.repository}) : super(UserInitial()) {
    on<LoadUserProfile>(_onLoad);
    on<RefreshUserProfile>(_onRefresh);
  }

  Future<void> _onLoad(LoadUserProfile event, Emitter<UserState> emit) async {
    emit(UserLoadInProgress());
    try {
      final profile = await repository.getProfile();
      emit(UserLoadSuccess(profile));
    } catch (e) {
      emit(UserLoadFailure(e.toString()));
    }
  }

  Future<void> _onRefresh(RefreshUserProfile event, Emitter<UserState> emit) async {
    add(LoadUserProfile());
  }
}