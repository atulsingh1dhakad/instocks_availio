abstract class DashboardEvent {}

class DashboardRequested extends DashboardEvent {
  final String period;
  DashboardRequested({this.period = "Daily"});
}

class DashboardRefreshed extends DashboardEvent {
  final String period;
  DashboardRefreshed({this.period = "Daily"});
}