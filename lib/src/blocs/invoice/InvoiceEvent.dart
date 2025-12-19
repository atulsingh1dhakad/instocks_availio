// lib/src/blocs/invoice/invoice_event.dart
import 'package:equatable/equatable.dart';

abstract class InvoiceEvent extends Equatable {
  const InvoiceEvent();
  @override
  List<Object?> get props => [];
}

class LoadInvoices extends InvoiceEvent {
  final String storeId;
  final String branch;
  final int page;
  final int limit;
  final String? fromDate;
  final String? toDate;
  const LoadInvoices({required this.storeId, required this.branch, this.page = 1, this.limit = 10, this.fromDate, this.toDate});
  @override
  List<Object?> get props => [storeId, branch, page, limit, fromDate, toDate];
}

class RefreshInvoices extends InvoiceEvent {
  final String storeId;
  final String branch;
  const RefreshInvoices({required this.storeId, required this.branch});
  @override
  List<Object?> get props => [storeId, branch];
}

class SearchInvoices extends InvoiceEvent {
  final String query;
  const SearchInvoices(this.query);
  @override
  List<Object?> get props => [query];
}