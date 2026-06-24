import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class AppSnackBar {
  static const _kError   = Color(0xFFBA1A1A);
  static const _kSuccess = Color(0xFF2E7D32);
  static const _kInfo    = Color(0xFF1565C0);
  static const _kWarning = Color(0xFFE65100);

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
    Color background,
    IconData icon,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: background,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          elevation: 6,
        ),
      );
  }
}
