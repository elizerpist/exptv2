/// Mirrors `Math.round(value).toLocaleString('hu-HU')` used by the frozen
/// B3M-A3 browser reference.
///
/// Hungarian browser formatting does not group four-digit values, but starts
/// grouping at five digits. The rest of the application intentionally keeps
/// its existing formatter; this exact formatter is scoped to Balance parity.
String formatBalanceForint(num value) {
  final rounded = value.round();
  final sign = rounded < 0 ? '-' : '';
  final digits = rounded.abs().toString();
  return '$sign${_groupBalanceDigits(digits)} Ft';
}

String formatBalanceSignedForint(num value) {
  final rounded = value.round();
  final sign = rounded > 0
      ? '+'
      : rounded < 0
      ? '-'
      : '';
  return '$sign${_groupBalanceDigits(rounded.abs().toString())} Ft';
}

/// Formats the hand-authored FastInfo catalog amounts in the frozen B3M-A3.
///
/// Those catalog strings group four-digit values (`-4 250 Ft`,
/// `-3 490 Ft`), unlike the browser-generated transaction and budget values.
String formatBalanceCatalogForint(num value) {
  final rounded = value.round();
  final sign = rounded < 0 ? '-' : '';
  final digits = rounded.abs().toString();
  return '$sign${_groupBalanceDigits(digits, minimumLength: 4)} Ft';
}

String _groupBalanceDigits(String digits, {int minimumLength = 5}) {
  if (digits.length < minimumLength) return digits;
  final firstGroupLength = digits.length % 3 == 0 ? 3 : digits.length % 3;
  final groups = <String>[digits.substring(0, firstGroupLength)];
  for (var index = firstGroupLength; index < digits.length; index += 3) {
    groups.add(digits.substring(index, index + 3));
  }
  return groups.join(' ');
}
