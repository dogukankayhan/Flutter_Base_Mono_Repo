import 'package:flutter/services.dart';

/// Formats a Turkish mobile phone number as the user types.
///
/// Rules applied in order:
///   1. Strip all non-digit characters.
///   2. Strip a leading 0 (e.g. 05XX… → 5XX…).
///   3. Strip a leading 90 (e.g. 905XX… → 5XX…).
///   4. If any digits remain and the first is not '5', reject the input
///      and return the old value (blocks non-Turkish-mobile pastes).
///   5. Enforce max 10 digits.
///   6. Display as groups 3+3+2+2 → "5XX XXX XX XX".
class PhoneInputFormatter extends TextInputFormatter {
  static const _maxDigits = 10;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (digits.startsWith('0')) digits = digits.substring(1);

    if (digits.startsWith('90') && digits.length > 2) {
      digits = digits.substring(2);
    }

    if (digits.isNotEmpty && !digits.startsWith('5')) return oldValue;

    if (digits.length > _maxDigits) digits = digits.substring(0, _maxDigits);

    final formatted = _format(digits);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _format(String digits) {
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 0) buf.write('(');
      if (i == 3) buf.write(') ');
      if (i == 6 || i == 8) buf.write(' ');
      buf.write(digits[i]);
    }
    return buf.toString();
  }
}
