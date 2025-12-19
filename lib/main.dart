import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to landscape only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Restore any persisted auth token into in-memory holder early.
  // This ensures AuthHolder (in-memory) is populated before blocs/services run.
  await AuthService.restoreToMemory();

  // Initialize services/repositories
  final authService = AuthService();
  final authRepository = AuthRepository(authService);

  // Dashboard repository (uses DashboardService)
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
    // Provide repositories first, then blocs that depend on them.
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: authRepository),
        RepositoryProvider<DashboardRepository>.value(value: dashboardRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          // AuthBloc - used by RootPage to decide navigation
          BlocProvider<AuthBloc>(
            create: (_) => AuthBloc(authRepository)..add(AppStarted()),
          ),

          // DashboardBloc - available to DashboardScreen and any children
          BlocProvider<DashboardBloc>(
            create: (ctx) => DashboardBloc(ctx.read<DashboardRepository>())
              ..add(DashboardRequested(period: 'Daily')),
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
          return const Scaffold(
            body: Center(child: LoadingWidget()),
          );
        } else if (state is AuthAuthenticated) {
          // When authenticated show your homescreen
          return homescreen();
        } else {
          // Unauthenticated -> show login
          return loginscreen();
        }
      },
    );
  }
}