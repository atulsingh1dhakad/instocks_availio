import 'package:intl/intl.dart';

class Formatters {
  static final _currencyINR = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  static String currencyINR(double v) => _currencyINR.format(v);
}