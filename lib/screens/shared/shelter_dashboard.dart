import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_notifier.dart';
import '../../providers/requests_provider.dart';
import '../../providers/donations_provider.dart';
import '../../widgets/onboarding_sheet.dart';
import '../../widgets/app_logo.dart';
import '../../models/request_model.dart';
import '../../models/shelter_model.dart';
import '../../services/profile_service.dart';
import 'browse_donations_screen.dart';
import 'my_requests_screen.dart';
import 'chats_list_screen.dart';
import '../shelter/profile_screen.dart';
import '../shelter/settings_screen.dart';
import 'package:foodshare/models/user_model.dart';

const _kBrandGreen = Color(0xFF38563B);

class ShelterDashboard extends ConsumerStatefulWidget {
  const ShelterDashboard({super.key});

  @override
  ConsumerState<ShelterDashboard> createState() => _ShelterDashboardState();
}

class _ShelterDashboardState extends ConsumerState<ShelterDashboard> {
  int _selectedIndex = 0;
  Shelter? _shelter;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _maybeShowOnboarding();
  }

  void _maybeShowOnboarding() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final auth = ref.read(authNotifierProvider).asData?.value;
      if (auth != null && !auth.hasDoneOnboarding) {
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          isDismissible: false,
          backgroundColor: Colors.transparent,
          builder: (_) => const OnboardingSheet(),
        );
        if (mounted) await ref.read(authNotifierProvider.notifier).markOnboardingDone();
      }
    });
  }

  Future<void> _loadProfile() async {
    final userId = ref.read(authNotifierProvider).asData?.value.user?.id;
    if (userId == null) return;
    final shelter = await ProfileService.getShelter(userId).catchError((_) => null);
    if (mounted && shelter != null) setState(() => _shelter = shelter);
  }

  void _onNavTap(int index) => setState(() => _selectedIndex = index);

  Widget _getBody() {
    switch (_selectedIndex) {
      case 0: return _buildHome();
      case 1: return ChatsListScreen(userType: UserType.shelter, onDrawerItemSelected: _onNavTap);
      case 2: return ProfileScreen(userType: UserType.shelter, onDrawerItemSelected: _onNavTap);
      case 3: return SettingsScreen(onDrawerItemSelected: _onNavTap);
      default: return _buildHome();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: _getBody(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: cs.surfaceContainer, border: Border(top: BorderSide(color: cs.outlineVariant, width: 0.5))),
        child: BottomNavigationBar(
          backgroundColor: cs.surfaceContainer,
          currentIndex: _selectedIndex,
          onTap: _onNavTap,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: cs.primary,
          unselectedItemColor: cs.onSurfaceVariant,
          selectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 11),
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w400, fontSize: 11),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline_rounded), label: 'Chats'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
            BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings'),
          ],
        ),
      ),
    );
  }

  Widget _buildHome() {
    final cs = Theme.of(context).colorScheme;
    final name = _shelter?.organizationName ?? 'Organization';
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';

    final requestsAsync = ref.watch(myRequestsProvider);
    final availableFilter = DonationFilter(city: _shelter?.city);
    final donationsAsync = ref.watch(browseDonationsProvider(availableFilter));

    final requests = requestsAsync.asData?.value ?? [];
    final totalRequests = requests.length;
    final pendingRequests = requests.where((r) => r.status == RequestStatus.pending).length;
    final approvedRequests = requests.where((r) => r.status == RequestStatus.approved).length;
    final availableDonations = donationsAsync.asData?.value.length ?? 0;

    return RefreshIndicator(
      color: cs.primary,
      onRefresh: () async {
        ref.invalidate(myRequestsProvider);
        ref.invalidate(browseDonationsProvider(availableFilter));
        await _loadProfile();
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              color: _kBrandGreen,
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 20, left: 20, right: 20, bottom: 32),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const ClipOval(child: AppLogo(width: 42, height: 42)),
                  const SizedBox(width: 14),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(greeting, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.white.withValues(alpha: 0.7), fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(name, style: GoogleFonts.bebasNeue(fontSize: 28, color: Colors.white, letterSpacing: 1)),
                  ]),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(color: cs.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
              transform: Matrix4.translationValues(0, -16, 0),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Quick Actions', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant, letterSpacing: 0.5)),
                const SizedBox(height: 12),
                _HeroCard(
                  icon: Icons.search_rounded,
                  label: 'Find Food',
                  subtitle: 'Browse available donations near you',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BrowseDonationsScreen()))
                      .then((_) => ref.invalidate(myRequestsProvider)),
                ),
                const SizedBox(height: 10),
                _WideCard(
                  icon: Icons.list_alt_rounded,
                  label: 'My Requests',
                  subtitle: 'Track and manage your donation requests',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyRequestsScreen())),
                ),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _ChipCard(icon: Icons.chat_bubble_outline_rounded, label: 'Chats', onTap: () => _onNavTap(1))),
                  const SizedBox(width: 10),
                  Expanded(child: _ChipCard(icon: Icons.person_outline_rounded, label: 'Profile', onTap: () => _onNavTap(2))),
                ]),
                const SizedBox(height: 28),
                Text('Your Impact', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant, letterSpacing: 0.5)),
                const SizedBox(height: 12),
                _SpotlightStat(icon: Icons.volunteer_activism_rounded, label: 'Available Near You', value: availableDonations, detail: 'donation${availableDonations == 1 ? '' : 's'} ready for pickup'),
                const SizedBox(height: 10),
                Row(children: [
                  _MiniStat(label: 'Total\nRequests', value: totalRequests),
                  const SizedBox(width: 8),
                  _MiniStat(label: 'Approved', value: approvedRequests),
                  const SizedBox(width: 8),
                  _MiniStat(label: 'Pending', value: pendingRequests),
                ]),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  const _HeroCard({required this.icon, required this.label, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(color: _kBrandGreen, borderRadius: BorderRadius.circular(20)),
        child: Row(children: [
          Container(width: 54, height: 54, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: Colors.white, size: 28)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 3),
            Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white.withValues(alpha: 0.75))),
          ])),
          Container(width: 34, height: 34, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle), child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 17)),
        ]),
      ),
    );
  }
}

class _WideCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  const _WideCard({required this.icon, required this.label, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: cs.surfaceContainer, borderRadius: BorderRadius.circular(16), border: Border.all(color: cs.outlineVariant, width: 0.5)),
        child: Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: cs.secondaryContainer, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: cs.primary, size: 22)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: cs.onSurface)),
            const SizedBox(height: 2),
            Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: cs.onSurfaceVariant)),
          ])),
          Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant, size: 22),
        ]),
      ),
    );
  }
}

class _ChipCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ChipCard({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: cs.surfaceContainer, borderRadius: BorderRadius.circular(14), border: Border.all(color: cs.outlineVariant, width: 0.5)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
        ]),
      ),
    );
  }
}

class _SpotlightStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final String detail;
  const _SpotlightStat({required this.icon, required this.label, required this.value, required this.detail});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(20)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onPrimaryContainer.withValues(alpha: 0.7), letterSpacing: 0.3)),
          Text(value.toString(), style: GoogleFonts.bebasNeue(fontSize: 60, color: cs.onPrimaryContainer, letterSpacing: 0.5, height: 1.05)),
          Text(detail, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: cs.onPrimaryContainer.withValues(alpha: 0.65))),
        ])),
        Container(width: 56, height: 56, decoration: BoxDecoration(color: cs.onPrimaryContainer.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, color: cs.onPrimaryContainer, size: 28)),
      ]),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final int value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
        decoration: BoxDecoration(color: cs.surfaceContainer, borderRadius: BorderRadius.circular(14), border: Border.all(color: cs.outlineVariant, width: 0.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value.toString(), style: GoogleFonts.bebasNeue(fontSize: 30, color: cs.primary, letterSpacing: 0.5)),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w500, color: cs.onSurfaceVariant, height: 1.3), maxLines: 2),
        ]),
      ),
    );
  }
}
