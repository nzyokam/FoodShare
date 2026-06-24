import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/request_model.dart';
import '../../providers/requests_provider.dart';
import '../../services/chat_service.dart';
import '../../widgets/app_snackbar.dart';
import '../shelter/chat_screen.dart';

class ReservedDonationsScreen extends ConsumerWidget {
  const ReservedDonationsScreen({super.key});

  Future<void> _openChat(BuildContext context, DonationRequest req) async {
    try {
      final chat = await ChatService.getOrCreateChat(req.donationId);
      if (!context.mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(
        chatId: chat.id,
        title: req.otherPartyName ?? 'Restaurant',
        donationTitle: req.donationTitle ?? '',
      )));
    } catch (e) {
      if (context.mounted) AppSnackBar.showError(context, 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(myRequestsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(children: [Image.asset('lib/assets/transparent.png', width: 32, height: 32), const SizedBox(width: 10), const Text('Reserved Donations')]),
      ),
      body: requestsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (all) {
          final reserved = all.where((r) => r.status == RequestStatus.approved).toList();
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myRequestsProvider),
            child: reserved.isEmpty
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
                    itemCount: reserved.length,
                    itemBuilder: (_, i) => _card(context, ref, reserved[i]),
                  ),
          );
        },
      ),
    );
  }

  Widget _card(BuildContext context, WidgetRef ref, DonationRequest req) {
    final expiry = req.donationExpiryDate;
    final now = DateTime.now();
    final isExpiringSoon = expiry != null && expiry.isAfter(now) && expiry.difference(now).inHours < 12;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: isExpiringSoon ? const BorderSide(color: Colors.red, width: 2) : BorderSide.none),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(backgroundColor: const Color(0xFF2E7D32).withAlpha(20), child: const Icon(Icons.restaurant, color: Color(0xFF2E7D32))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(req.otherPartyName ?? 'Restaurant', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.orange.withAlpha(20), borderRadius: BorderRadius.circular(12)),
              child: Text('RESERVED', style: TextStyle(fontSize: 10, color: req.donationStatus == 'completed' ? Colors.green : Colors.orange, fontWeight: FontWeight.bold)),
            ),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            if (req.donationImageUrls.isNotEmpty)
              ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(req.donationImageUrls.first, width: 80, height: 80, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder()))
            else
              _placeholder(),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(req.donationTitle ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              if (req.donationQuantity != null || req.donationUnit != null) ...[
                const SizedBox(height: 4),
                Text('${req.donationQuantity ?? ''} ${req.donationUnit ?? ''}'.trim(), style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface.withAlpha(160))),
              ],
            ])),
          ]),
          if (expiry != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isExpiringSoon ? Colors.red.withAlpha(20) : Theme.of(context).colorScheme.primary.withAlpha(10),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isExpiringSoon ? Colors.red.withAlpha(100) : Theme.of(context).colorScheme.primary.withAlpha(50)),
              ),
              child: Row(children: [
                Icon(Icons.access_time, size: 16, color: isExpiringSoon ? Colors.red : Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  'Expires: ${expiry.day}/${expiry.month} at ${expiry.hour.toString().padLeft(2, '0')}:${expiry.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 14, color: isExpiringSoon ? Colors.red : Colors.grey[600], fontWeight: isExpiringSoon ? FontWeight.w600 : FontWeight.normal),
                ),
                if (isExpiringSoon) ...[const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)), child: const Text('URGENT', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)))],
              ]),
            ),
          ],
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _openChat(context, req),
            icon: const Icon(Icons.chat, size: 18), label: const Text('Chat with Restaurant'),
            style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          ),
        ]),
      ),
    );
  }

  Widget _placeholder() => Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.fastfood, size: 30));
}
