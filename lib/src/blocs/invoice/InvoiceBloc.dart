// lib/src/blocs/invoice/invoice_bloc.dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/invoice_repository.dart';
import 'InvoiceEvent.dart';
import 'InvoiceState.dart';

class InvoiceBloc extends Bloc<InvoiceEvent, InvoiceState> {
  final InvoiceRepository repository;

  InvoiceBloc({required this.repository}) : super(InvoiceInitial()) {
    on<LoadInvoices>(_onLoadInvoices);
    on<RefreshInvoices>(_onRefreshInvoices);
    // Search handled in UI by filtering local list; keeping a SearchInvoices event if needed later.
  }

  Future<void> _onLoadInvoices(LoadInvoices event, Emitter<InvoiceState> emit) async {
    emit(InvoiceLoadInProgress());
    try {
      final invoices = await repository.getInvoices(
        storeId: event.storeId,
        branch: event.branch,
        page: event.page,
        limit: event.limit,
        fromDate: event.fromDate,
        toDate: event.toDate,
      );
      emit(InvoiceLoadSuccess(invoices: invoices, page: event.page, limit: event.limit));
    } catch (e) {
      emit(InvoiceLoadFailure(e.toString()));
    }
  }

  Future<void> _onRefreshInvoices(RefreshInvoices event, Emitter<InvoiceState> emit) async {
    add(LoadInvoices(storeId: event.storeId, branch: event.branch));
  }
}