import '../models/dashboardModels.dart' show DashboardData;
import '../services/dashboard_service.dart';

class DashboardRepository {
  final DashboardService service;
  DashboardRepository(this.service);

  Future<DashboardData> fetchDashboard(String period) => service.fetchAll(period);
}