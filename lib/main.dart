import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'consts.dart';

// Auth
import 'src/blocs/auth/auth_bloc.dart';
import 'package:instockavailio/src/blocs/auth/auth_event.dart' show AppStarted;
import 'package:instockavailio/src/blocs/auth/auth_state.dart';
import 'src/repositories/auth_repository.dart';
import 'src/services/auth_service.dart';

// Dashboard (repository + bloc)
import 'src/services/dashboard_service.dart';
import 'src/repositories/dashboard_respository.dart';
import 'src/blocs/dashboard/DashboardBloc.dart';
import 'src/blocs/dashboard/DashboardEvent.dart';

// UI / theme / helpers
import 'src/style/app_theme.dart';
import 'src/reusable/loading_widget.dart';
import 'src/screens/homescreen.dart';
import 'src/screens/loginscreen.dart';

// Debug overlay
import 'src/widgets/auth_debug_overlay.dart';

class SimpleBlocObserver extends BlocObserver {
  @override
  void onEvent(Bloc bloc, Object? event) {
    debugPrint('[BlocEvent] ${bloc.runtimeType} <- ${event.runtimeType}');
    super.onEvent(bloc, event);
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    debugPrint('[BlocTransition] ${bloc.runtimeType} -> ${transition.nextState.runtimeType}');
    super.onTransition(bloc, transition);
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    debugPrint('[BlocError] ${bloc.runtimeType} -> $error');
    super.onError(bloc, error, stackTrace);
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Bloc.observer = SimpleBlocObserver();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // RESTORE TOKEN FIRST - This is the "static" restoration into memory
  await AuthService.restoreToMemory();

  final authService = AuthService();
  final authRepository = AuthRepository(authService);

  // Initialize DashboardService without passing token - ApiClient now has it static/singleton
  final dashboardRepository = DashboardRepository(DashboardService());

  runApp(MyApp(
    authRepository: authRepository,
    dashboardRepository: dashboardRepository,
  ));
}

class MyApp extends StatelessWidget {
  final AuthRepository authRepository;
  final DashboardRepository dashboardRepository;

  const MyApp({
    Key? key,
    required this.authRepository,
    required this.dashboardRepository,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: authRepository),
        RepositoryProvider<DashboardRepository>.value(value: dashboardRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (_) => AuthBloc(authRepository)..add(AppStarted()),
          ),
          BlocProvider<DashboardBloc>(
            // We NO LONGER dispatch DashboardRequested here to avoid race conditions
            create: (ctx) => DashboardBloc(ctx.read<DashboardRepository>()),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'InStockAvailio',
          theme: AppTheme.lightTheme,
          home: const RootPage(),
        ),
      ),
    );
  }
}

class RootPage extends StatelessWidget {
  const RootPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthUninitialized || state is AuthLoading) {
          return const Scaffold(body: Center(child: LoadingWidget()));
        } else if (state is AuthAuthenticated) {
          return homescreen();
        } else {
          return const loginscreen();
        }
      },
    );
  }
}
