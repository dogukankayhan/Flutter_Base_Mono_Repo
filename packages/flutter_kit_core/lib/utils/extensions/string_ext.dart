extension NullableStringExt on String? {
  bool get isNotEmpty => this != null && this!.isNotEmpty;
  bool get isEmpty => this == null || this!.isEmpty;
}

extension StringExt on String {
  /// "hello world" → "Hello world"
  String get capitalize =>
      isEmpty ? this : this[0].toUpperCase() + substring(1).toLowerCase();

  /// "hello world" → "Hello World"
  String get titleCase =>
      split(' ').where((e) => e.isNotEmpty).map((e) => e.capitalize).join(' ');

  /// "hello-world" / "hello_world" → "Hello world"
  String get humanize => replaceAll(RegExp(r'[-_]'), ' ').capitalize;

  /// "John Doe" → "JD" (avatar initials)
  String get initials => trim()
      .split(' ')
      .where((e) => e.isNotEmpty)
      .map((e) => e[0].toUpperCase())
      .join();

  /// Truncates with ellipsis. "Hello World" truncate(7) → "Hello W…"
  String truncate(int maxLength) =>
      length <= maxLength ? this : '${substring(0, maxLength)}…';

  bool get isEmail => RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(this);

  bool get isNumeric => double.tryParse(this) != null;

  bool get isUrl =>
      Uri.tryParse(this)?.hasAbsolutePath == true && startsWith('http');

  static const Map<String, String> _turkishDiacritics = {
    'ç': 'c', 'Ç': 'C',
    'ğ': 'g', 'Ğ': 'G',
    'ı': 'i', 'İ': 'I',
    'ö': 'o', 'Ö': 'O',
    'ş': 's', 'Ş': 'S',
    'ü': 'u', 'Ü': 'U',
  };

  /// Lowercased with Turkish diacritics folded to their ASCII equivalent, so
  /// e.g. "İstanbul" and "istanbul" match the same search query.
  String get normalizedForSearch {
    final buffer = StringBuffer();
    for (final char in split('')) {
      buffer.write(_turkishDiacritics[char] ?? char);
    }
    return buffer.toString().toLowerCase();
  }
}
