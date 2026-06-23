import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_logo.dart';

/// Shown every time the user reaches the login screen (not logged in).
/// Brief explanation of what FoodShare is before they sign in.
class WelcomeSheet extends StatelessWidget {
  const WelcomeSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final h = MediaQuery.of(context).size.height;

    return Container(
      height: h * 0.9,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // ── Handle + close ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
            child: Row(
              children: [
                const Spacer(),
                Center(
                  child: Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant, size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // ── Scrollable content ─────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
              child: Column(
                children: [
                  // Logo
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD6E3D3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: const AppLogo(fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Welcome to FoodShare',
                    style: GoogleFonts.bebasNeue(fontSize: 30, color: const Color(0xFF38563B), letterSpacing: 1),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'We connect restaurants with surplus food to shelters and communities that need it — reducing waste and fighting hunger at the same time.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, color: cs.onSurfaceVariant, height: 1.6),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Feature rows
                  const _Feature(
                    icon: Icon(Icons.restaurant_rounded, color: Color(0xFF38563B), size: 24),
                    bg: Color(0xFFD6E3D3),
                    title: 'For Restaurants',
                    body: 'List surplus food in seconds. Schedule pickups and track donations — all in one place.',
                  ),
                  const SizedBox(height: 16),
                  const _Feature(
                    icon: Icon(Icons.home_rounded, color: Color(0xFF1D4ED8), size: 24),
                    bg: Color(0xFFDBEAFE),
                    title: 'For Shelters',
                    body: 'Browse available donations nearby, request what you need, and coordinate pickup with restaurants.',
                  ),
                  const SizedBox(height: 16),
                  const _Feature(
                    icon: AppLogo(width: 24, height: 24),
                    bg: Color(0xFFD1FAE5),
                    title: 'Real Impact',
                    body: 'Every donation reduces food waste and puts a meal on the table. Together we make a difference.',
                  ),
                  const SizedBox(height: 36),

                  // Stats strip
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainer,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cs.outlineVariant, width: 0.5),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _Stat(value: '500+', label: 'Meals shared'),
                        _Divider(),
                        _Stat(value: '50+', label: 'Restaurants'),
                        _Divider(),
                        _Stat(value: '30+', label: 'Shelters'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // ── CTA ────────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF506F52),
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
                child: Text(
                  'Get Started',
                  style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  final Widget icon;
  final Color bg;
  final String title, body;
  const _Feature({required this.icon, required this.bg, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
          child: Center(child: icon),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: cs.onSurface)),
              const SizedBox(height: 3),
              Text(body, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: cs.onSurfaceVariant, height: 1.5)),
            ],
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String value, label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(value, style: GoogleFonts.bebasNeue(fontSize: 22, color: const Color(0xFF38563B), letterSpacing: 1)),
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: cs.onSurfaceVariant)),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 36, color: Theme.of(context).colorScheme.outlineVariant);
  }
}
