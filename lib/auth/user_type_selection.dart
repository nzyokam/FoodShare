import 'package:flutter/material.dart';
import 'package:foodshare/models/user_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_snackbar.dart';

class UserTypeSelection extends StatefulWidget {
  const UserTypeSelection({super.key});

  @override
  State<UserTypeSelection> createState() => _UserTypeSelectionState();
}

class _UserTypeSelectionState extends State<UserTypeSelection> {
  UserType? _selectedType;
  bool _isLoading = false;

  Future<void> _continue() async {
    if (_selectedType == null) return;
    setState(() => _isLoading = true);
    try {
      await context.read<AuthProvider>().setUserType(_selectedType!);
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Error: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F5),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FOODSHARE',
                    style: GoogleFonts.bebasNeue(
                      fontSize: 32,
                      color: const Color(0xFF38563B),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Pick your role',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1C1A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Join our community to start sharing abundance or receiving support. How will you participate today?',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: const Color(0xFF424841),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            // ── Role cards ──────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  children: [
                    _RoleCard(
                      type: UserType.restaurant,
                      selected: _selectedType == UserType.restaurant,
                      icon: Icons.restaurant_rounded,
                      title: "I'm a Restaurant",
                      description: 'Share your surplus food with those in need, reduce waste, and support your local community.',
                      features: const [
                        'Reduce daily food waste',
                        'Tax-deductible donations',
                        'Easy pickup scheduling',
                      ],
                      onTap: () => setState(() => _selectedType = UserType.restaurant),
                    ),
                    const SizedBox(height: 16),
                    _RoleCard(
                      type: UserType.shelter,
                      selected: _selectedType == UserType.shelter,
                      icon: Icons.home_rounded,
                      title: "I'm a Shelter",
                      description: 'Connect with local food providers to receive fresh, nutritious meals for your organization.',
                      features: const [
                        'Access fresh, daily meals',
                        'Real-time food alerts',
                        'Direct communication',
                      ],
                      onTap: () => setState(() => _selectedType = UserType.shelter),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // ── Bottom actions ───────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: const BoxDecoration(
                color: Color(0xFFFAF9F5),
                border: Border(top: BorderSide(color: Color(0xFFC2C8BF), width: 0.5)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: (_selectedType == null || _isLoading) ? null : _continue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedType != null ? const Color(0xFF506F52) : const Color(0xFFEEEEEA),
                        foregroundColor: _selectedType != null ? Colors.white : const Color(0xFF737971),
                        shape: const StadiumBorder(),
                        elevation: 0,
                        disabledBackgroundColor: const Color(0xFFEEEEEA),
                        disabledForegroundColor: const Color(0xFF737971),
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(
                              'Continue',
                              style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF424841)),
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: Text(
                          'Log in',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: const Color(0xFF38563B),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
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

class _RoleCard extends StatelessWidget {
  final UserType type;
  final bool selected;
  final IconData icon;
  final String title;
  final String description;
  final List<String> features;
  final VoidCallback onTap;

  const _RoleCard({
    required this.type,
    required this.selected,
    required this.icon,
    required this.title,
    required this.description,
    required this.features,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFF38563B) : const Color(0xFFC2C8BF),
            width: selected ? 2 : 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF506F52).withValues(alpha: selected ? 0.08 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD6E3D3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: const Color(0xFF38563B), size: 24),
                ),
                const Spacer(),
                // Radio
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? const Color(0xFF38563B) : const Color(0xFFC2C8BF),
                      width: selected ? 6 : 1.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1C1A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF424841),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            ...features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, size: 16, color: Color(0xFF38563B)),
                      const SizedBox(width: 8),
                      Text(
                        f,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: const Color(0xFF424841),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
