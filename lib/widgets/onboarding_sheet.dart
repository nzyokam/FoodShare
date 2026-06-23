import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_logo.dart';

/// Post-login onboarding carousel — shown once after the user first reaches
/// the dashboard. Presented as a 90% bottom sheet, not dismissible by
/// dragging (the user must tap Skip or complete all pages).
class OnboardingSheet extends StatefulWidget {
  const OnboardingSheet({super.key});

  @override
  State<OnboardingSheet> createState() => _OnboardingSheetState();
}

class _OnboardingSheetState extends State<OnboardingSheet> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    _Page(
      iconWidget: AppLogo(width: 64, height: 64),
      iconBg: Color(0xFFD6E3D3),
      tag: 'Welcome',
      title: 'Connecting Surplus\nFood With Need',
      body: 'FoodShare bridges the gap between restaurants with surplus food and shelters that need it — reducing waste and feeding communities.',
    ),
    _Page(
      icon: Icons.restaurant_rounded,
      iconBg: Color(0xFFD6E3D3),
      iconColor: Color(0xFF38563B),
      tag: 'For Restaurants',
      title: 'Share Surplus\nFood Easily',
      body: 'List your leftover food in seconds. Set a pickup window, choose a category, and let nearby shelters come to you.',
    ),
    _Page(
      icon: Icons.home_rounded,
      iconBg: Color(0xFFDBEAFE),
      iconColor: Color(0xFF1D4ED8),
      tag: 'For Shelters',
      title: 'Find Fresh Food\nNear You',
      body: 'Browse available donations from local restaurants. Request what you need and coordinate pickup — all in one place.',
    ),
    _Page(
      icon: Icons.favorite_rounded,
      iconBg: Color(0xFFD1FAE5),
      iconColor: Color(0xFF047857),
      tag: 'Make a Difference',
      title: 'Every Meal\nShared Matters',
      body: 'Join our growing community. Together we\'re making a measurable impact on hunger and food waste in our cities.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _done() => Navigator.pop(context);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final h = MediaQuery.of(context).size.height;
    final isLast = _page == _pages.length - 1;

    return PopScope(
      canPop: false, // prevent back-swipe dismissal; user must use buttons
      child: Container(
        height: h * 0.9,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: BorderRadius.circular(2)),
                  ),
                  const Spacer(),
                  AnimatedOpacity(
                    opacity: isLast ? 0 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: TextButton(
                      onPressed: isLast ? null : _done,
                      child: Text('Skip', style: GoogleFonts.plusJakartaSans(fontSize: 14, color: cs.onSurfaceVariant, fontWeight: FontWeight.w500)),
                    ),
                  ),
                ],
              ),
            ),

            // ── Page content ─────────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) => _PageView(page: _pages[i]),
              ),
            ),

            // ── Dots + button ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
              child: Column(
                children: [
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) {
                      final active = i == _page;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: active ? 20 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: active ? const Color(0xFF38563B) : cs.outlineVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),

                  // Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        if (isLast) {
                          _done();
                        } else {
                          _controller.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF506F52),
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        elevation: 0,
                      ),
                      child: Text(
                        isLast ? 'Get Started' : 'Next',
                        style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageView extends StatelessWidget {
  final _Page page;
  const _PageView({required this.page});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 0),
      child: Column(
        children: [
          const Spacer(flex: 1),
          // Icon container
          Container(
            width: 140, height: 140,
            decoration: BoxDecoration(shape: BoxShape.circle, color: page.iconBg),
            child: page.iconWidget ?? Icon(page.icon!, size: 64, color: page.iconColor),
          ),
          const Spacer(flex: 1),
          // Tag chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(color: cs.secondaryContainer, borderRadius: BorderRadius.circular(20)),
            child: Text(page.tag, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: cs.onSurface)),
          ),
          const SizedBox(height: 14),
          // Title
          Text(
            page.title,
            style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w800, color: cs.onSurface, height: 1.25),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          // Body
          Text(
            page.body,
            style: GoogleFonts.plusJakartaSans(fontSize: 14, color: cs.onSurfaceVariant, height: 1.6),
            textAlign: TextAlign.center,
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _Page {
  final IconData? icon;
  final Widget? iconWidget;
  final Color iconBg;
  final Color? iconColor;
  final String tag, title, body;
  const _Page({this.icon, this.iconWidget, required this.iconBg, this.iconColor, required this.tag, required this.title, required this.body});
}
