// lib/src/blocs/auth/auth_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:instockavailio/src/blocs/auth/auth_event.dart';
import 'package:instockavailio/src/blocs/auth/auth_state.dart' show AuthUninitialized, AuthState, AuthLoading, AuthAuthenticated, AuthUnauthenticated;
import '../../repositories/auth_repository.dart' show AuthRepository;

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc(this.authRepository) : super(AuthUninitialized()) {
    on<AppStarted>(_onAppStarted);
    on<LoggedIn>(_onLoggedIn);
    on<LoggedOut>(_onLoggedOut);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      // restoreTokenToMemory handles the logic of checking expiry and setting AuthHolder
      await authRepository.restoreTokenToMemory();
      final isLoggedIn = await authRepository.isLoggedIn();
      
      if (isLoggedIn) {
        final token = await authRepository.getToken();
        emit(AuthAuthenticated(token: token ?? ''));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[AuthBloc] AppStarted error: $e');
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoggedIn(LoggedIn event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      // persistToken internally updates the AuthHolder singleton
      await authRepository.persistToken(event.token, event.expiryMillis);
      emit(AuthAuthenticated(token: event.token));
    } catch (e) {
      if (kDebugMode) debugPrint('[AuthBloc] LoggedIn error: $e');
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoggedOut(LoggedOut event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await authRepository.deleteToken();
      emit(AuthUnauthenticated());
    } catch (e) {
      if (kDebugMode) debugPrint('[AuthBloc] LoggedOut error: $e');
      emit(AuthUnauthenticated());
    }
  }
}
