import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:instockavailio/src/blocs/dashboard/DashboardEvent.dart';
import 'package:instockavailio/src/blocs/dashboard/DashboardState.dart';

import '../../repositories/dashboard_respository.dart';


class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardRepository repository;

  DashboardBloc(this.repository) : super(DashboardInitial()) {
    on<DashboardRequested>(_onRequested);
    on<DashboardRefreshed>(_onRefreshed);
  }

  Future<void> _onRequested(DashboardRequested event, Emitter<DashboardState> emit) async {
    emit(DashboardLoadInProgress());
    try {
      final data = await repository.fetchDashboard(event.period);
      emit(DashboardLoadSuccess(
        todaysSales: data.todaysSales,
        pendingOrdersCount: data.pendingOrdersCount,
        invoices: data.invoices,
        dataPoints: data.dataPoints,
        selectedPeriod: event.period,
      ));
    } catch (e) {
      emit(DashboardLoadFailure(e.toString()));
    }
  }

  Future<void> _onRefreshed(DashboardRefreshed event, Emitter<DashboardState> emit) async {
    try {
      final data = await repository.fetchDashboard(event.period);
      emit(DashboardLoadSuccess(
        todaysSales: data.todaysSales,
        pendingOrdersCount: data.pendingOrdersCount,
        invoices: data.invoices,
        dataPoints: data.dataPoints,
        selectedPeriod: event.period,
      ));
    } catch (e) {
      emit(DashboardLoadFailure(e.toString()));
    }
  }
}