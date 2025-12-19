
import '../../models/dashboardModels.dart';

abstract class DashboardState {}

class DashboardInitial extends DashboardState {}

class DashboardLoadInProgress extends DashboardState {}

class DashboardLoadSuccess extends DashboardState {
  final double todaysSales;
  final int pendingOrdersCount;
  final List<Map<String, dynamic>> invoices;
  final List<SalesPoint> dataPoints;
  final String selectedPeriod;

  DashboardLoadSuccess({
    required this.todaysSales,
    required this.pendingOrdersCount,
    required this.invoices,
    required this.dataPoints,
    required this.selectedPeriod,
  });
}

class DashboardLoadFailure extends DashboardState {
  final String message;
  DashboardLoadFailure(this.message);
}