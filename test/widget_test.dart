import 'package:flutter_test/flutter_test.dart';
import 'package:instockavailio/main.dart';
import 'package:instockavailio/src/models/dashboardModels.dart';
import 'package:instockavailio/src/services/auth_service.dart';
import 'package:instockavailio/src/repositories/auth_repository.dart';

// Imports needed for the fake dashboard repository
import 'package:instockavailio/src/repositories/dashboard_respository.dart';
import 'package:instockavailio/src/services/dashboard_service.dart';

/// A tiny fake that overrides AuthService methods used by AuthRepository/AuthBloc.
class FakeAuthService extends AuthService {
  @override
  Future<bool> isTokenValid() async => false;

  @override
  Future<String?> getToken() async => null;

  @override
  Future<int?> getExpiry() async => null;

  @override
  Future<void> persistToken(String token, int expiryMillis) async {}

  @override
  Future<void> clearToken() async {}
}

/// Fake DashboardRepository to avoid network during tests.
class FakeDashboardRepository extends DashboardRepository {
  FakeDashboardRepository() : super(DashboardService());

  @override
  Future<DashboardData> fetchDashboard(String period) async {
    // Return safe empty data synchronously
    return DashboardData(
      todaysSales: 0.0,
      pendingOrdersCount: 0,
      invoices: <Map<String, dynamic>>[],
      dataPoints: <SalesPoint>[],
    );
  }
}

void main() {
  testWidgets('Login screen smoke test', (WidgetTester tester) async {
    // Provide the fake service via AuthRepository to MyApp
    final authRepo = AuthRepository(FakeAuthService());
    final dashboardRepo = FakeDashboardRepository();

    await tester.pumpWidget(
      // Wrap with MaterialApp is handled inside MyApp
      MyApp(authRepository: authRepo, dashboardRepository: dashboardRepo),
    );

    // Allow bloc to process AppStarted and UI to rebuild
    await tester.pumpAndSettle();

    // Adjust the expectation to the exact text your Login screen shows.
    expect(find.text('Login'), findsOneWidget);
  });
}