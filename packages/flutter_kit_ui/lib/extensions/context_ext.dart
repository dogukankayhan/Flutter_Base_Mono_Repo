import 'package:flutter/material.dart';

extension BuildContextExt on BuildContext {
  // ─── Keyboard ────────────────────────────────────────────────────────────

  void dismissKeyboard() {
    final scope = FocusScope.of(this);
    if (scope.hasFocus) scope.unfocus();
  }

  // ─── Safe area ───────────────────────────────────────────────────────────

  double get topSafe => MediaQuery.paddingOf(this).top;
  double get bottomSafe => MediaQuery.paddingOf(this).bottom;

  /// Bottom padding that grows when the software keyboard appears.
  EdgeInsets get bottomInsetPadding =>
      EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(this).bottom);

  // ─── Screen size ─────────────────────────────────────────────────────────

  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;
  Size get screenSize => MediaQuery.sizeOf(this);

  // ─── Theme shortcuts ─────────────────────────────────────────────────────

  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  // ─── Snackbar ────────────────────────────────────────────────────────────

  void showSnackBar(String message, {Duration duration = const Duration(seconds: 3)}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(message), duration: duration),
    );
  }
}
