
class SalesPoint {
  final String xLabel;
  final double value;
  SalesPoint(this.xLabel, this.value);
}

class DashboardData {
  final double todaysSales;
  final int pendingOrdersCount;
  final List<Map<String, dynamic>> invoices;
  final List<SalesPoint> dataPoints;

  DashboardData({
    required this.todaysSales,
    required this.pendingOrdersCount,
    required this.invoices,
    required this.dataPoints,
  });
}