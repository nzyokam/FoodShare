import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class AppSnackBar {
  static const _kBg      = Color(0xFF1C1C1E); // near-black — visible on any background
  static const _kError   = Color(0xFFFF453A);
  static const _kSuccess = Color(0xFF32D74B);
  static const _kInfo    = Color(0xFF0A84FF);
  static const _kWarning = Color(0xFFFF9F0A);

  static void showError(BuildContext context, String message) =>
      _show(context, message, _kError, Icons.error_outline_rounded);

  static void showSuccess(BuildContext context, String message) =>
      _show(context, message, _kSuccess, Icons.check_circle_outline_rounded);

  static void showInfo(BuildContext context, String message) =>
      _show(context, message, _kInfo, Icons.info_outline_rounded);

  static void showWarning(BuildContext context, String message) =>
      _show(context, message, _kWarning, Icons.warning_amber_rounded);

  static void _show(
    BuildContext context,
    String message,
    Color accentColor,
    IconData icon,
  ) {
    final textStyle = GoogleFonts.plusJakartaSans(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: _kBg,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          elevation: 8,
          contentTextStyle: textStyle,
          content: Row(
            children: [
              Icon(icon, color: accentColor, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(message, style: textStyle),
              ),
            ],
          ),
        ),
      );
  }
}
