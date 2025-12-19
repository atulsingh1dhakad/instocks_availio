// lib/src/blocs/auth/auth_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:instockavailio/src/blocs/auth/auth_event.dart';
import 'package:instockavailio/src/blocs/auth/auth_state.dart' show AuthUninitialized, AuthState, AuthLoading, AuthAuthenticated, AuthUnauthenticated;
import '../../helpers/login_auth_holder.dart';
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
      // restore token into memory (AuthHolder) first
      await authRepository.restoreTokenToMemory();
      final isLoggedIn = await authRepository.isLoggedIn();
      if (isLoggedIn) {
        final token = await authRepository.getToken();
        // also ensure AuthHolder has it (restoreTokenToMemory did that)
        if (token != null) AuthHolder.instance.setAuthorizationHeader(token);
        emit(AuthAuthenticated(token: token ?? ''));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (_) {
      // make sure memory cleared on error
      AuthHolder.instance.clear();
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoggedIn(LoggedIn event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    // event.token expected to be the full Authorization header string (e.g. "Bearer ...")
    await authRepository.persistToken(event.token, event.expiryMillis);
    // update in-memory holder
    AuthHolder.instance.setAuthorizationHeader(event.token);
    emit(AuthAuthenticated(token: event.token));
  }

  Future<void> _onLoggedOut(LoggedOut event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    await authRepository.deleteToken();
    AuthHolder.instance.clear();
    emit(AuthUnauthenticated());
  }
}