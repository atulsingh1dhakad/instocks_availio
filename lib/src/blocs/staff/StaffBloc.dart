// lib/src/blocs/staff/staff_bloc.dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'StaffEvent.dart' show LoadStaff, StaffEvent, RefreshStaff, AddStaff, DeleteStaff;
import 'StaffState.dart' show StaffState, StaffInitial, StaffLoadInProgress, StaffActionSuccess, StaffLoadSuccess, StaffLoadFailure, StaffActionInProgress, StaffActionFailure;
import '../../repositories/staff_repository.dart';

class StaffBloc extends Bloc<StaffEvent, StaffState> {
  final StaffRepository repository;
  StaffBloc({required this.repository}) : super(StaffInitial()) {
    on<LoadStaff>(_onLoad);
    on<RefreshStaff>(_onRefresh);
    on<AddStaff>(_onAdd);
    on<DeleteStaff>(_onDelete);
  }

  Future<void> _onLoad(LoadStaff event, Emitter<StaffState> emit) async {
    emit(StaffLoadInProgress());
    try {
      final items = await repository.getStaff();
      emit(StaffLoadSuccess(items));
    } catch (e) {
      emit(StaffLoadFailure(e.toString()));
    }
  }

  Future<void> _onRefresh(RefreshStaff event, Emitter<StaffState> emit) async {
    add(LoadStaff());
  }

  Future<void> _onAdd(AddStaff event, Emitter<StaffState> emit) async {
    emit(StaffActionInProgress());
    try {
      await repository.addStaff(event.payload);
      emit(const StaffActionSuccess('Staff added'));
      add(LoadStaff());
    } catch (e) {
      emit(StaffActionFailure(e.toString()));
      add(LoadStaff());
    }
  }

  Future<void> _onDelete(DeleteStaff event, Emitter<StaffState> emit) async {
    emit(StaffActionInProgress());
    try {
      await repository.removeStaff(event.userId);
      emit(const StaffActionSuccess('Staff deleted'));
      add(LoadStaff());
    } catch (e) {
      emit(StaffActionFailure(e.toString()));
      add(LoadStaff());
    }
  }
}