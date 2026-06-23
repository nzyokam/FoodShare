import 'package:flutter/material.dart';
import '../../models/donation_model.dart';
import '../../models/request_model.dart';
import '../../models/restaurant_model.dart';
import '../../services/chat_service.dart';
import '../../services/donation_service.dart';
import '../../services/profile_service.dart';
import '../../services/request_service.dart';
import '../shelter/chat_screen.dart';

class RequestWithDetails {
  final DonationRequest request;
  final Donation donation;
  final Restaurant restaurant;
  RequestWithDetails({required this.request, required this.donation, required this.restaurant});
}

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<RequestWithDetails> _all = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    setState(() => _loading = true);
    try {
      final requests = await RequestService.myRequests();
      final items = <RequestWithDetails>[];
      for (final req in requests) {
        try {
          final donation = await DonationService.getDonation(req.donationId);
          final restaurant = await ProfileService.getRestaurant(donation.donorId);
          if (restaurant == null) continue;
          items.add(RequestWithDetails(request: req, donation: donation, restaurant: restaurant));
        } catch (_) { continue; }
      }
      if (mounted) setState(() { _all = items; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<RequestWithDetails> _filtered(String status) => _all.where((r) => r.request.status.name == status).toList();

  Future<void> _cancelRequest(DonationRequest request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Request'),
        content: const Text('Are you sure you want to cancel this request?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await RequestService.cancelRequest(request.id);
      await _loadRequests();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request cancelled')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _openChat(Donation donation) async {
    try {
      final chat = await ChatService.getOrCreateChat(donation.id);
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(chatId: chat.id, title: 'Restaurant Chat', donationTitle: donation.title)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(children: [Image.asset('lib/assets/transparent.png', width: 32, height: 32), const SizedBox(width: 10), const Text('My Requests')]),
        bottom: TabBar(controller: _tabController, tabs: const [Tab(text: 'Pending'), Tab(text: 'Approved'), Tab(text: 'Declined')]),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadRequests,
              child: TabBarView(
                controller: _tabController,
                children: ['pending', 'approved', 'declined'].map(_requestsList).toList(),
              ),
            ),
    );
  }

  Widget _requestsList(String status) {
    final items = _filtered(status);
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_statusIcon(status), size: 64, color: Theme.of(context).colorScheme.primary.withAlpha(100)),
            const SizedBox(height: 16),
            Text('No $status requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 8),
            Text(_statusMsg(status), style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha(160)), textAlign: TextAlign.center),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (_, i) => _requestCard(items[i], status),
    );
  }

  Widget _requestCard(RequestWithDetails rd, String status) {
    final req = rd.request;
    final donation = rd.donation;
    final restaurant = rd.restaurant;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CircleAvatar(backgroundColor: const Color(0xFF2E7D32).withAlpha(20), child: const Icon(Icons.restaurant, color: Color(0xFF2E7D32))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(restaurant.businessName ?? 'Restaurant', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('${restaurant.city ?? ''} • ${restaurant.cuisineTypes.isNotEmpty ? restaurant.cuisineTypes.first : 'Restaurant'}', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withAlpha(160))),
              ])),
              _statusBadge(status),
            ]),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withAlpha(10), borderRadius: BorderRadius.circular(8), border: Border.all(color: Theme.of(context).colorScheme.primary.withAlpha(50))),
              child: Row(children: [
                if (donation.imageUrls.isNotEmpty)
                  ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.network(donation.imageUrls.first, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder()))
                else
                  _placeholder(),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(donation.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('${donation.quantity ?? ''} ${donation.unit ?? ''}'.trim(), style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withAlpha(160))),
                  if (donation.expiryDate != null) Row(children: [
                    Icon(Icons.access_time, size: 12, color: Theme.of(context).colorScheme.onSurface.withAlpha(160)),
                    const SizedBox(width: 4),
                    Text('Expires: ${donation.expiryDate!.day}/${donation.expiryDate!.month}', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withAlpha(160))),
                  ]),
                ])),
              ]),
            ),
            const SizedBox(height: 16),
            Text('Your Message:', style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 4),
            Text(req.message ?? '(no message)', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha(180))),
            const SizedBox(height: 16),
            Row(children: [
              Icon(Icons.access_time, size: 14, color: Theme.of(context).colorScheme.onSurface.withAlpha(160)),
              const SizedBox(width: 4),
              Text('Requested ${_ago(req.createdAt)}', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withAlpha(160))),
              if (req.respondedAt != null) ...[
                const SizedBox(width: 16),
                Icon(_responseIcon(status), size: 14, color: _statusColor(status)),
                const SizedBox(width: 4),
                Text('${_responseText(status)} ${_ago(req.respondedAt!)}', style: TextStyle(fontSize: 12, color: _statusColor(status))),
              ],
            ]),
            const SizedBox(height: 16),
            Row(children: [
              if (status == 'pending') ...[
                Expanded(child: OutlinedButton.icon(
                  onPressed: () => _cancelRequest(req),
                  icon: const Icon(Icons.cancel, size: 18), label: const Text('Cancel Request'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                )),
                const SizedBox(width: 12),
              ],
              Expanded(child: ElevatedButton.icon(
                onPressed: () => _openChat(donation),
                icon: const Icon(Icons.chat, size: 18), label: const Text('Chat'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              )),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String s) {
    final c = _statusColor(s);
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: c.withAlpha(20), borderRadius: BorderRadius.circular(12)), child: Text(s.toUpperCase(), style: TextStyle(fontSize: 10, color: c, fontWeight: FontWeight.bold)));
  }

  Widget _placeholder() => Container(width: 50, height: 50, color: Colors.grey[300], child: const Icon(Icons.fastfood, size: 20));

  Color _statusColor(String s) => s == 'approved' ? Colors.green : s == 'declined' ? Colors.red : Colors.orange;
  IconData _statusIcon(String s) => s == 'pending' ? Icons.schedule : s == 'approved' ? Icons.check_circle : Icons.cancel;
  IconData _responseIcon(String s) => s == 'approved' ? Icons.check_circle : s == 'declined' ? Icons.cancel : Icons.schedule;
  String _responseText(String s) => s == 'approved' ? 'Approved' : s == 'declined' ? 'Declined' : 'Pending';
  String _statusMsg(String s) => s == 'pending' ? 'Your pending requests will appear here' : s == 'approved' ? 'Approved requests will appear here' : 'Declined requests will appear here';

  String _ago(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inDays > 0) return '${d.inDays} days ago';
    if (d.inHours > 0) return '${d.inHours} hours ago';
    if (d.inMinutes > 0) return '${d.inMinutes} minutes ago';
    return 'just now';
  }
}
