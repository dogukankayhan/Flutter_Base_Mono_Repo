import '../validator_rule.dart';

/// Validates a Turkish mobile phone number.
/// Accepts formatted "(5XX) XXX XX XX" or raw 10 digits.
/// After stripping non-digits: must match ^5\d{9}$.
class PhoneValidator extends Validator<String> {
  const PhoneValidator([super.message]);

  static final _regex = RegExp(r'^5\d{9}$');

  @override
  String? validate(String? value) {
    if (value == null || value.isEmpty) return null;
    final digits = value.replaceAll(RegExp(r'[^\d]'), '');
    if (!_regex.hasMatch(digits)) {
      return resolveMessage(
        'Geçerli bir telefon numarası giriniz ((5XX) XXX XX XX)',
      );
    }
    return null;
  }
}
