import 'package:flutter/material.dart';
import '../../models/donation_model.dart';
import '../../models/request_model.dart';
import '../../models/restaurant_model.dart';
import '../../services/chat_service.dart';
import '../../services/donation_service.dart';
import '../../services/profile_service.dart';
import '../../services/request_service.dart';
import '../../widgets/app_snackbar.dart';
import '../shelter/chat_screen.dart';

class _ReservedItem {
  final DonationRequest request;
  final Donation donation;
  final Restaurant restaurant;
  _ReservedItem({required this.request, required this.donation, required this.restaurant});
}

class ReservedDonationsScreen extends StatefulWidget {
  const ReservedDonationsScreen({super.key});

  @override
  State<ReservedDonationsScreen> createState() => _ReservedDonationsScreenState();
}

class _ReservedDonationsScreenState extends State<ReservedDonationsScreen> {
  List<_ReservedItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final requests = await RequestService.myRequests();
      final relevant = requests.where((r) => r.status == RequestStatus.approved).toList();
      final items = <_ReservedItem>[];
      for (final req in relevant) {
        try {
          final donation = await DonationService.getDonation(req.donationId);
          final restaurant = await ProfileService.getRestaurant(donation.donorId);
          if (restaurant == null) continue;
          items.add(_ReservedItem(request: req, donation: donation, restaurant: restaurant));
        } catch (_) { continue; }
      }
      if (mounted) setState(() { _items = items; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openChat(Donation donation) async {
    try {
      final chat = await ChatService.getOrCreateChat(donation.id);
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(chatId: chat.id, title: 'Restaurant Chat', donationTitle: donation.title)));
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: Row(children: [Image.asset('lib/assets/transparent.png', width: 32, height: 32), const SizedBox(width: 10), const Text('Reserved Donations')])),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _items.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                        Center(child: Column(children: [
                          Icon(Icons.bookmark_border, size: 64, color: Theme.of(context).colorScheme.primary.withAlpha(100)),
                          const SizedBox(height: 16),
                          Text('No reserved donations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                          const SizedBox(height: 8),
                          Text('Approved donations will appear here', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha(160))),
                        ])),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _items.length,
                      itemBuilder: (_, i) => _card(_items[i]),
                    ),
            ),
    );
  }

  Widget _card(_ReservedItem item) {
    final donation = item.donation;
    final restaurant = item.restaurant;
    final expiry = donation.expiryDate;
    final pickup = donation.pickupTime;
    final now = DateTime.now();
    final isExpiringSoon = expiry != null && expiry.isAfter(now) && expiry.difference(now).inHours < 12;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: isExpiringSoon ? const BorderSide(color: Colors.red, width: 2) : BorderSide.none),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CircleAvatar(backgroundColor: const Color(0xFF2E7D32).withAlpha(20), child: const Icon(Icons.restaurant, color: Color(0xFF2E7D32))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(restaurant.businessName ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('${restaurant.address ?? ''}, ${restaurant.city ?? ''}', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withAlpha(160)), maxLines: 1, overflow: TextOverflow.ellipsis),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.orange.withAlpha(20), borderRadius: BorderRadius.circular(12)),
                child: Text(donation.status.name.toUpperCase(), style: TextStyle(fontSize: 10, color: donation.status == DonationStatus.completed ? Colors.green : Colors.orange, fontWeight: FontWeight.bold)),
              ),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              if (donation.imageUrls.isNotEmpty)
                ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(donation.imageUrls.first, width: 80, height: 80, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder()))
              else
                _placeholder(),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(donation.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (donation.quantity != null || donation.unit != null) ...[
                  const SizedBox(height: 4),
                  Text('${donation.quantity ?? ''} ${donation.unit ?? ''}'.trim(), style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface.withAlpha(160))),
                ],
                if (donation.category != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFF2E7D32).withAlpha(20), borderRadius: BorderRadius.circular(8)),
                    child: Text(_catName(donation.category!), style: const TextStyle(fontSize: 12, color: Color(0xFF2E7D32))),
                  ),
                ],
              ])),
            ]),
            if (donation.description != null && donation.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(donation.description!, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha(180))),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isExpiringSoon ? Colors.red.withAlpha(20) : Theme.of(context).colorScheme.primary.withAlpha(10),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isExpiringSoon ? Colors.red.withAlpha(100) : Theme.of(context).colorScheme.primary.withAlpha(50)),
              ),
              child: Column(children: [
                if (pickup != null) Row(children: [
                  Icon(Icons.schedule, size: 16, color: Colors.blue[600]),
                  const SizedBox(width: 6),
                  Text('Pickup: ${pickup.day}/${pickup.month} at ${pickup.hour.toString().padLeft(2, '0')}:${pickup.minute.toString().padLeft(2, '0')}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.blue[600])),
                ]),
                if (expiry != null) ...[
                  if (pickup != null) const SizedBox(height: 8),
                  Row(children: [
                    Icon(Icons.access_time, size: 16, color: isExpiringSoon ? Colors.red : Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text('Expires: ${expiry.day}/${expiry.month} at ${expiry.hour.toString().padLeft(2, '0')}:${expiry.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(fontSize: 14, color: isExpiringSoon ? Colors.red : Colors.grey[600], fontWeight: isExpiringSoon ? FontWeight.w600 : FontWeight.normal)),
                    if (isExpiringSoon) ...[const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)), child: const Text('URGENT', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)))],
                  ]),
                ],
              ]),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _openChat(donation),
              icon: const Icon(Icons.chat, size: 18), label: const Text('Chat with Restaurant'),
              style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.fastfood, size: 30));

  String _catName(DonationCategory c) {
    const names = {DonationCategory.fruits: 'Fruits', DonationCategory.vegetables: 'Vegetables', DonationCategory.grains: 'Grains', DonationCategory.dairy: 'Dairy', DonationCategory.meat: 'Meat & Fish', DonationCategory.preparedMeals: 'Prepared Meals', DonationCategory.snacks: 'Snacks', DonationCategory.beverages: 'Beverages', DonationCategory.other: 'Other'};
    return names[c] ?? 'Other';
  }
}
