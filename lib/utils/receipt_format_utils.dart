// Shared Indian-currency amount formatter used by receipt form, list, and detail screens.
String fmtAmount(dynamic raw) {
  if (raw == null) return '-';
  final d = double.tryParse(raw.toString());
  if (d == null) return '-';
  final isNeg = d < 0;
  final fixed = d.abs().toStringAsFixed(2);
  final parts = fixed.split('.');
  String intPart = parts[0];
  final decPart = parts[1];
  if (intPart.length <= 3) {
    return isNeg ? '-₹$intPart.$decPart' : '₹$intPart.$decPart';
  }
  String result = intPart.substring(intPart.length - 3);
  intPart = intPart.substring(0, intPart.length - 3);
  while (intPart.isNotEmpty) {
    final len = intPart.length >= 2 ? 2 : intPart.length;
    result = '${intPart.substring(intPart.length - len)},$result';
    intPart = intPart.substring(0, intPart.length - len);
  }
  return isNeg ? '-₹$result.$decPart' : '₹$result.$decPart';
}
