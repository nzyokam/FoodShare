import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';
import '../widgets/app_snackbar.dart';

class LegalLinks {
  static Future<void> openPrivacyPolicy(BuildContext context) =>
      _open(context, AppConfig.privacyPolicyUrl);

  static Future<void> openTerms(BuildContext context) =>
      _open(context, AppConfig.termsOfServiceUrl);

  static Future<void> _open(BuildContext context, String url) async {
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      AppSnackBar.showError(context, 'Could not open the page. Please try again.');
    }
  }
}
