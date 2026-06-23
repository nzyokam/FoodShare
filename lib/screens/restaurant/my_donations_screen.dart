import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/chat_model.dart';
import '../../models/donation_model.dart';
import '../../services/chat_service.dart';
import '../../services/donation_service.dart';
import '../../widgets/app_logo.dart';
import '../shelter/chat_screen.dart';
import 'add_donation_screen.dart';

const _kGreen    = Color(0xFF38563B);
const _kGreenMid = Color(0xFF506F52);

class MyDonationsScreen extends StatefulWidget {
  const MyDonationsScreen({super.key});

  @override
  State<MyDonationsScreen> createState() => _MyDonationsScreenState();
}

class _MyDonationsScreenState extends State<MyDonationsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Donation> _all = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDonations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDonations() async {
    setState(() => _loading = true);
    try {
      final result = await DonationService.myDonations();
      if (mounted) setState(() { _all = result; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Donation> _filtered(DonationStatus? status) =>
      status == null ? _all : _all.where((d) => d.status == status).toList();

  Future<void> _deleteDonation(Donation donation) async {
    final cs = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Donation', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: cs.onSurface)),
        content: Text('Are you sure you want to delete this donation? This cannot be undone.', style: GoogleFonts.plusJakartaSans(color: cs.onSurfaceVariant)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: cs.onSurfaceVariant))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFBA1A1A), foregroundColor: Colors.white, shape: const StadiumBorder(), elevation: 0),
            child: Text('Delete', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await DonationService.deleteDonation(donation.id);
      await _loadDonations();
      if (mounted) _showSnack('Donation deleted', isError: false);
    } catch (e) {
      if (mounted) _showSnack('Error: $e', isError: true);
    }
  }

  Future<void> _updateStatus(Donation donation, String newStatus) async {
    try {
      await DonationService.updateDonation(donation.id, status: newStatus);
      await _loadDonations();
    } catch (e) {
      if (mounted) _showSnack('Error: $e', isError: true);
    }
  }

  Future<void> _openChat(Donation donation) async {
    try {
      final chats = await ChatService.listChats();
      Chat? chat;
      try { chat = chats.firstWhere((c) => c.donationId == donation.id); } catch (_) {}
      if (!mounted) return;
      if (chat == null) { _showSnack('No conversation started yet', isError: false); return; }
      Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(chatId: chat!.id, title: 'Shelter Chat', donationTitle: donation.title)));
    } catch (e) {
      if (mounted) _showSnack('Error: $e', isError: true);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.plusJakartaSans()),
      backgroundColor: isError ? const Color(0xFFBA1A1A) : _kGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: cs.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(children: [Image.asset('lib/assets/transparent.png', width: 32, height: 32), const SizedBox(width: 10), Text('My Donations', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface))]),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddDonationScreen()));
                _loadDonations();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: _kGreenMid, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text('Add New', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Tabs ─────────────────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: cs.surfaceContainer, borderRadius: BorderRadius.circular(12)),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(9),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: cs.onSurface,
              unselectedLabelColor: cs.onSurfaceVariant,
              labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
              unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w400, fontSize: 13),
              tabs: const [Tab(text: 'All'), Tab(text: 'Available'), Tab(text: 'Reserved'), Tab(text: 'Done')],
            ),
          ),
          const SizedBox(height: 12),

          // ── List ─────────────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: cs.primary))
                : RefreshIndicator(
                    color: cs.primary,
                    onRefresh: _loadDonations,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _donationsList(null),
                        _donationsList(DonationStatus.available),
                        _donationsList(DonationStatus.reserved),
                        _donationsList(DonationStatus.completed),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _donationsList(DonationStatus? status) {
    final cs = Theme.of(context).colorScheme;
    final donations = _filtered(status);
    if (donations.isEmpty) {
      // "Done" tab gets an instructional placeholder — no Add button
      if (status == DonationStatus.completed) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(color: cs.secondaryContainer, shape: BoxShape.circle),
                  child: Icon(Icons.check_circle_outline_rounded, color: cs.primary, size: 36),
                ),
                const SizedBox(height: 16),
                Text('No completed donations', style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700, color: cs.onSurface)),
                const SizedBox(height: 12),
                Text(
                  'Move items to this section from the reserved section by marking them as done when delivery is completed.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: cs.onSurfaceVariant, height: 1.6),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(color: cs.secondaryContainer, shape: BoxShape.circle),
              child: const AppLogo(width: 36, height: 36),
            ),
            const SizedBox(height: 16),
            Text(
              status == null ? 'No donations yet' : 'No ${status.name} donations',
              style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700, color: cs.onSurface),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddDonationScreen()));
                _loadDonations();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(color: _kGreenMid, borderRadius: BorderRadius.circular(24)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text('Add Donation', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                ]),
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: donations.length,
      itemBuilder: (_, i) => _donationCard(donations[i]),
    );
  }

  Widget _donationCard(Donation d) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final expiry = d.expiryDate;
    final isExpired = expiry != null && expiry.isBefore(now);
    final isExpiringSoon = expiry != null && !isExpired && expiry.difference(now).inHours < 24;

    const statusColors = {
      DonationStatus.available:  Color(0xFF38563B),
      DonationStatus.reserved:   Color(0xFFB45309),
      DonationStatus.completed:  Color(0xFF1D4ED8),
      DonationStatus.cancelled:  Color(0xFFBA1A1A),
    };
    const statusBg = {
      DonationStatus.available:  Color(0xFFD6E3D3),
      DonationStatus.reserved:   Color(0xFFFEF3C7),
      DonationStatus.completed:  Color(0xFFDBEAFE),
      DonationStatus.cancelled:  Color(0xFFFFE4E6),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpired ? const Color(0xFFBA1A1A).withValues(alpha: 0.4) : cs.outlineVariant,
          width: isExpired ? 1.5 : 0.5,
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          SizedBox(
            height: 140, width: double.infinity,
            child: Stack(fit: StackFit.expand, children: [
              if (d.imageUrls.isNotEmpty)
                Image.network(d.imageUrls.first, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder(cs))
              else
                _placeholder(cs),
              Positioned(
                top: 10, right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: statusBg[d.status] ?? Colors.grey[100], borderRadius: BorderRadius.circular(20)),
                  child: Text(d.status.name.toUpperCase(), style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: statusColors[d.status] ?? Colors.grey)),
                ),
              ),
            ]),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.title, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: cs.onSurface)),
                const SizedBox(height: 8),
                Row(children: [
                  if (d.quantity != null || d.unit != null) ...[
                    Icon(Icons.scale_rounded, size: 14, color: cs.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text('${d.quantity ?? ''} ${d.unit ?? ''}'.trim(), style: GoogleFonts.plusJakartaSans(fontSize: 13, color: cs.onSurfaceVariant, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 12),
                  ],
                  if (expiry != null) ...[
                    Icon(Icons.calendar_today_outlined, size: 14, color: isExpired || isExpiringSoon ? const Color(0xFFBA1A1A) : cs.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      'Exp: ${expiry.day}/${expiry.month}/${expiry.year}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, color: isExpired || isExpiringSoon ? const Color(0xFFBA1A1A) : cs.onSurfaceVariant, fontWeight: isExpired || isExpiringSoon ? FontWeight.w600 : FontWeight.w400),
                    ),
                    if (isExpired) ...[
                      const SizedBox(width: 6),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFBA1A1A), borderRadius: BorderRadius.circular(8)), child: Text('EXPIRED', style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white))),
                    ] else if (isExpiringSoon) ...[
                      const SizedBox(width: 6),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(8)), child: Text('URGENT', style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white))),
                    ],
                  ],
                ]),
                const SizedBox(height: 12),
                _actionButtons(d, cs),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButtons(Donation d, ColorScheme cs) {
    switch (d.status) {
      case DonationStatus.available:
        return Row(children: [
          Expanded(child: _OutlineBtn(label: 'Edit', icon: Icons.edit_outlined, cs: cs, onTap: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => AddDonationScreen(donation: d)));
            _loadDonations();
          })),
          const SizedBox(width: 8),
          Expanded(child: _FillBtn(label: 'Pause', icon: Icons.pause_circle_outline_rounded, color: const Color(0xFFB45309), onTap: () => _updateStatus(d, 'cancelled'))),
          const SizedBox(width: 8),
          _DeleteBtn(cs: cs, onTap: () => _deleteDonation(d)),
        ]);

      case DonationStatus.reserved:
        return Column(children: [
          Row(children: [
            Expanded(child: _OutlineBtn(label: 'View Chat', icon: Icons.chat_bubble_outline_rounded, cs: cs, onTap: () => _openChat(d))),
            const SizedBox(width: 8),
            Expanded(child: _FillBtn(label: 'Mark Done', icon: Icons.check_circle_outline_rounded, color: const Color(0xFF1D4ED8), onTap: () => _updateStatus(d, 'completed'))),
          ]),
          const SizedBox(height: 8),
          _OutlineBtn(
            label: 'Make Available Again',
            icon: Icons.undo_rounded,
            cs: cs,
            onTap: () => _updateStatus(d, 'available'),
          ),
        ]);

      case DonationStatus.completed:
        return _OutlineBtn(label: 'View Chat', icon: Icons.chat_bubble_outline_rounded, cs: cs, onTap: () => _openChat(d));

      case DonationStatus.cancelled:
        return Row(children: [
          Expanded(child: _FillBtn(label: 'Reactivate', icon: Icons.play_circle_outline_rounded, color: _kGreenMid, onTap: () => _updateStatus(d, 'available'))),
          const SizedBox(width: 8),
          _DeleteBtn(cs: cs, onTap: () => _deleteDonation(d)),
        ]);
    }
  }

  Widget _placeholder(ColorScheme cs) => Container(
    color: cs.secondaryContainer,
    child: const Center(child: AppLogo(width: 40, height: 40)),
  );
}

// ── Reusable button widgets ────────────────────────────────────────────────────

class _OutlineBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final ColorScheme cs;
  const _OutlineBtn({required this.label, required this.icon, required this.onTap, required this.cs});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(border: Border.all(color: cs.outlineVariant), borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: cs.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _FillBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _FillBtn({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class _DeleteBtn extends StatelessWidget {
  final VoidCallback onTap;
  final ColorScheme cs;
  const _DeleteBtn({required this.onTap, required this.cs});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(border: Border.all(color: const Color(0xFFFFDAD6)), borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFBA1A1A)),
      ),
    );
  }
}
