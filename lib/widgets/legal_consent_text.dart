import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/legal_links.dart';

class LegalConsentText extends StatefulWidget {
  const LegalConsentText({super.key});

  @override
  State<LegalConsentText> createState() => _LegalConsentTextState();
}

class _LegalConsentTextState extends State<LegalConsentText> {
  late final TapGestureRecognizer _terms;
  late final TapGestureRecognizer _privacy;

  @override
  void initState() {
    super.initState();
    _terms = TapGestureRecognizer()..onTap = () => LegalLinks.openTerms(context);
    _privacy = TapGestureRecognizer()..onTap = () => LegalLinks.openPrivacyPolicy(context);
  }

  @override
  void dispose() {
    _terms.dispose();
    _privacy.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.plusJakartaSans(
      fontSize: 12,
      color: const Color(0xFF737971),
      height: 1.5,
    );
    final link = base.copyWith(
      color: Theme.of(context).colorScheme.primary,
      fontWeight: FontWeight.w700,
      decoration: TextDecoration.underline,
    );
    return Text.rich(
      TextSpan(style: base, children: [
        const TextSpan(text: 'By continuing, you agree to our '),
        TextSpan(text: 'Terms of Service', style: link, recognizer: _terms),
        const TextSpan(text: ' and '),
        TextSpan(text: 'Privacy Policy', style: link, recognizer: _privacy),
        const TextSpan(text: '.'),
      ]),
      textAlign: TextAlign.center,
    );
  }
}
