// lib/src/blocs/invoice/invoice_state.dart
import 'package:equatable/equatable.dart';
import '../../models/invoice_model.dart';

abstract class InvoiceState extends Equatable {
  const InvoiceState();
  @override
  List<Object?> get props => [];
}

class InvoiceInitial extends InvoiceState {}

class InvoiceLoadInProgress extends InvoiceState {}

class InvoiceLoadSuccess extends InvoiceState {
  final List<InvoiceModel> invoices;
  final int page;
  final int limit;

  const InvoiceLoadSuccess({required this.invoices, this.page = 1, this.limit = 10});
  @override
  List<Object?> get props => [invoices, page, limit];
}

class InvoiceLoadFailure extends InvoiceState {
  final String message;
  const InvoiceLoadFailure(this.message);
  @override
  List<Object?> get props => [message];
}