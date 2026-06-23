import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/donation_model.dart';
import '../../widgets/app_logo.dart';
import '../../providers/auth_provider.dart';
import '../../services/donation_service.dart';
import '../../services/profile_service.dart';
import '../../services/request_service.dart';

const _kGreen = Color(0xFF38563B);
const _kGreenMid = Color(0xFF506F52);
const _kSage = Color(0xFFD6E3D3);
const _kCream = Color(0xFFFAF9F5);
const _kOnSurface = Color(0xFF1A1C1A);
const _kMuted = Color(0xFF424841);
const _kOutline = Color(0xFFC2C8BF);

class BrowseDonationsScreen extends StatefulWidget {
  const BrowseDonationsScreen({super.key});

  @override
  State<BrowseDonationsScreen> createState() => _BrowseDonationsScreenState();
}

class _BrowseDonationsScreenState extends State<BrowseDonationsScreen> {
  List<Donation> _donations = [];
  bool _loading = true;
  String _selectedCity = '';
  DonationCategory? _selectedCategory;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadShelterCity();
  }

  Future<void> _loadShelterCity() async {
    try {
      final userId = context.read<AuthProvider>().user?.id;
      if (userId != null) {
        final shelter = await ProfileService.getShelter(userId);
        if (shelter?.city != null) setState(() => _selectedCity = shelter!.city!);
      }
    } catch (_) {}
    await _loadDonations();
  }

  Future<void> _loadDonations() async {
    setState(() => _loading = true);
    try {
      final results = await DonationService.listDonations(
        city: _selectedCity.isEmpty ? null : _selectedCity,
        category: _selectedCategory != null ? _categoryToApi(_selectedCategory!) : null,
        status: 'available',
      );
      if (mounted) {
        final filtered = _searchQuery.isEmpty
            ? results
            : results.where((d) =>
                d.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                (d.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)).toList();
        setState(() { _donations = filtered; _loading = false; });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _categoryToApi(DonationCategory cat) {
    if (cat == DonationCategory.preparedMeals) return 'prepared_meals';
    return cat.name;
  }

  Future<void> _requestDonation(Donation donation) async {
    final messageController = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: _kCream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: _kOutline, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text('Request Donation', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: _kOnSurface)),
              const SizedBox(height: 4),
              Text(donation.title, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: _kMuted)),
              const SizedBox(height: 20),
              TextField(
                controller: messageController,
                maxLines: 4,
                style: GoogleFonts.plusJakartaSans(fontSize: 14, color: _kOnSurface),
                decoration: InputDecoration(
                  hintText: 'Explain why your shelter needs this donation...',
                  hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF737971)),
                  filled: true,
                  fillColor: const Color(0xFFF4F4EF),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kOutline)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kOutline)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kGreen, width: 2)),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    final msg = messageController.text.trim();
                    if (msg.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Please add a message')));
                      return;
                    }
                    Navigator.pop(ctx);
                    try {
                      await RequestService.createRequest(donationId: donation.id, message: msg);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Request sent!', style: GoogleFonts.plusJakartaSans()),
                            backgroundColor: _kGreen,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFBA1A1A), behavior: SnackBarBehavior.floating),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: _kGreenMid, foregroundColor: Colors.white, shape: const StadiumBorder(), elevation: 0),
                  child: Text('Send Request', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kCream,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Text('FOODSHARE', style: GoogleFonts.bebasNeue(fontSize: 26, color: _kGreen, letterSpacing: 2)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Search bar ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                onChanged: (v) { _searchQuery = v; _loadDonations(); },
                style: GoogleFonts.plusJakartaSans(fontSize: 14, color: _kOnSurface),
                decoration: InputDecoration(
                  hintText: 'Search donations...',
                  hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF737971)),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF737971), size: 20),
                  filled: true,
                  fillColor: const Color(0xFFF4F4EF),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kOutline, width: 0.5)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kOutline, width: 0.5)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kGreen, width: 2)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Filter chips ──────────────────────────────────────────────────
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _FilterChip(
                    label: _selectedCity.isEmpty ? 'City' : _selectedCity,
                    active: _selectedCity.isNotEmpty,
                    onTap: () => _showCityFilter(),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: _selectedCategory != null ? _catName(_selectedCategory!) : 'Category',
                    active: _selectedCategory != null,
                    onTap: () => _showCategoryFilter(),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'More',
                    active: false,
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── Results ───────────────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: _kGreen))
                  : _donations.isEmpty
                      ? _emptyState()
                      : RefreshIndicator(
                          color: _kGreen,
                          onRefresh: _loadDonations,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: _donations.length,
                            itemBuilder: (_, i) => _donationCard(_donations[i]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72, height: 72,
            decoration: const BoxDecoration(color: _kSage, shape: BoxShape.circle),
            child: const AppLogo(width: 36, height: 36),
          ),
          const SizedBox(height: 16),
          Text('No donations found', style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700, color: _kOnSurface)),
          const SizedBox(height: 8),
          Text('Try adjusting your filters or\ncheck back later', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: _kMuted, height: 1.5), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _donationCard(Donation d) {
    final expiry = d.expiryDate;
    final now = DateTime.now();
    final isExpiringSoon = expiry != null && expiry.difference(now).inHours < 24 && expiry.isAfter(now);
    final isExpired = expiry != null && expiry.isBefore(now);
    final catLabel = d.category != null ? _catName(d.category!) : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kOutline, width: 0.5),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          SizedBox(
            height: 160,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (d.imageUrls.isNotEmpty)
                  Image.network(
                    d.imageUrls.first,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imagePlaceholder(),
                  )
                else
                  _imagePlaceholder(),
                // Category badge
                if (catLabel != null)
                  Positioned(
                    top: 12, right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_offer_rounded, size: 11, color: _kGreen),
                          const SizedBox(width: 4),
                          Text(catLabel, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: _kGreen)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.title, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: _kOnSurface)),
                if (d.description != null && d.description!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(d.description!, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: _kMuted)),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (d.quantity != null || d.unit != null) ...[
                      const Icon(Icons.scale_rounded, size: 14, color: _kMuted),
                      const SizedBox(width: 4),
                      Text('${d.quantity ?? ''} ${d.unit ?? ''}'.trim(), style: GoogleFonts.plusJakartaSans(fontSize: 13, color: _kMuted, fontWeight: FontWeight.w500)),
                      const SizedBox(width: 12),
                    ],
                    if (expiry != null) ...[
                      Icon(Icons.access_time_rounded, size: 14, color: isExpired || isExpiringSoon ? const Color(0xFFBA1A1A) : _kMuted),
                      const SizedBox(width: 4),
                      Text(
                        'Exp: ${_formatDate(expiry)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: isExpired || isExpiringSoon ? const Color(0xFFBA1A1A) : _kMuted,
                        ),
                      ),
                    ],
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _requestDonation(d),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: _kGreenMid, borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Request', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white),
                          ],
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
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: _kSage,
      child: const Center(child: AppLogo(width: 40, height: 40)),
    );
  }

  void _showCityFilter() async {
    final cities = ['', 'Nairobi', 'Mombasa', 'Nakuru', 'Eldoret', 'Kisumu', 'Other'];
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PickerSheet(
        title: 'Select City',
        items: cities,
        selected: _selectedCity,
        labelOf: (c) => c.isEmpty ? 'All Cities' : c,
      ),
    );
    if (picked != null) { _selectedCity = picked; _loadDonations(); }
  }

  void _showCategoryFilter() async {
    final picked = await showModalBottomSheet<DonationCategory?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PickerSheet<DonationCategory?>(
        title: 'Select Category',
        items: const [null, ...DonationCategory.values],
        selected: _selectedCategory,
        labelOf: (c) => c == null ? 'All Categories' : _catName(c),
      ),
    );
    if (picked == null && _selectedCategory != null) {
      setState(() => _selectedCategory = null);
      _loadDonations();
    } else if (picked != null) {
      setState(() => _selectedCategory = picked);
      _loadDonations();
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = dt.difference(now);
    if (diff.inHours < 24 && dt.day == now.day) return 'Today ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')} PM';
    if (dt.day == now.day + 1) return 'Tomorrow ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')} AM';
    return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
  }

  String _catName(DonationCategory c) {
    const names = {DonationCategory.fruits: 'Fruits', DonationCategory.vegetables: 'Produce', DonationCategory.grains: 'Grains', DonationCategory.dairy: 'Dairy', DonationCategory.meat: 'Meat & Fish', DonationCategory.preparedMeals: 'Prepared', DonationCategory.snacks: 'Snacks', DonationCategory.beverages: 'Beverages', DonationCategory.other: 'Other'};
    return names[c] ?? 'Other';
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFD6E3D3) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? const Color(0xFF38563B) : const Color(0xFFC2C8BF), width: active ? 1.5 : 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: active ? FontWeight.w700 : FontWeight.w500, color: active ? const Color(0xFF38563B) : const Color(0xFF424841))),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: active ? const Color(0xFF38563B) : const Color(0xFF737971)),
          ],
        ),
      ),
    );
  }
}

class _PickerSheet<T> extends StatelessWidget {
  final String title;
  final List<T> items;
  final T selected;
  final String Function(T) labelOf;
  const _PickerSheet({required this.title, required this.items, required this.selected, required this.labelOf});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFFFAF9F5), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: const Color(0xFFC2C8BF), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700, color: const Color(0xFF1A1C1A))),
          const SizedBox(height: 12),
          ...items.map((item) {
            final isSelected = item == selected;
            return ListTile(
              onTap: () => Navigator.pop(context, item),
              contentPadding: EdgeInsets.zero,
              title: Text(labelOf(item), style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400, color: isSelected ? const Color(0xFF38563B) : const Color(0xFF1A1C1A))),
              trailing: isSelected ? const Icon(Icons.check_rounded, color: Color(0xFF38563B)) : null,
            );
          }),
        ],
      ),
    );
  }
}
