class Validators {
  static bool isPositiveNumber(String? s) {
    if (s == null || s.trim().isEmpty) return false;
    final v = double.tryParse(s);
    return v != null && v > 0;
  }
}