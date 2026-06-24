import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/request_model.dart';
import '../../providers/requests_provider.dart';
import '../../services/chat_service.dart';
import '../../services/request_service.dart';
import '../../widgets/app_snackbar.dart';
import '../shelter/chat_screen.dart';

class MyRequestsScreen extends ConsumerStatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  ConsumerState<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends ConsumerState<MyRequestsScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<DonationRequest> _filtered(List<DonationRequest> all, String status) =>
      all.where((r) => r.status.name == status).toList();

  Future<void> _cancelRequest(DonationRequest request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Request'),
        content: const Text('Are you sure you want to cancel this request?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await RequestService.cancelRequest(request.id);
      ref.invalidate(myRequestsProvider);
      if (mounted) AppSnackBar.showInfo(context, 'Request cancelled');
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, 'Error: $e');
    }
  }

  Future<void> _openChat(DonationRequest req) async {
    try {
      final chat = await ChatService.getOrCreateChat(req.donationId);
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(
        chatId: chat.id,
        title: req.otherPartyName ?? 'Restaurant',
        donationTitle: req.donationTitle ?? '',
      )));
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(myRequestsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(children: [Image.asset('lib/assets/transparent.png', width: 32, height: 32), const SizedBox(width: 10), const Text('My Requests')]),
        bottom: TabBar(controller: _tabController, tabs: const [Tab(text: 'Pending'), Tab(text: 'Approved'), Tab(text: 'Declined')]),
      ),
      body: requestsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (all) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(myRequestsProvider),
          child: TabBarView(
            controller: _tabController,
            children: ['pending', 'approved', 'declined'].map((s) => _requestsList(_filtered(all, s), s)).toList(),
          ),
        ),
      ),
    );
  }

  Widget _requestsList(List<DonationRequest> items, String status) {
    if (items.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(_statusIcon(status), size: 64, color: Theme.of(context).colorScheme.primary.withAlpha(100)),
          const SizedBox(height: 16),
          Text('No $status requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 8),
          Text(_statusMsg(status), style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha(160)), textAlign: TextAlign.center),
        ]),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (_, i) => _requestCard(items[i], status),
    );
  }

  Widget _requestCard(DonationRequest req, String status) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(backgroundColor: const Color(0xFF2E7D32).withAlpha(20), child: const Icon(Icons.restaurant, color: Color(0xFF2E7D32))),
            const SizedBox(width: 12),
            Expanded(child: Text(req.otherPartyName ?? 'Restaurant', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
            _statusBadge(status),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withAlpha(10), borderRadius: BorderRadius.circular(8), border: Border.all(color: Theme.of(context).colorScheme.primary.withAlpha(50))),
            child: Row(children: [
              if (req.donationImageUrls.isNotEmpty)
                ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.network(req.donationImageUrls.first, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder()))
              else
                _placeholder(),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(req.donationTitle ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                if (req.donationQuantity != null || req.donationUnit != null)
                  Text('${req.donationQuantity ?? ''} ${req.donationUnit ?? ''}'.trim(), style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withAlpha(160))),
                if (req.donationExpiryDate != null) Row(children: [
                  Icon(Icons.access_time, size: 12, color: Theme.of(context).colorScheme.onSurface.withAlpha(160)),
                  const SizedBox(width: 4),
                  Text('Expires: ${req.donationExpiryDate!.day}/${req.donationExpiryDate!.month}', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withAlpha(160))),
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
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), minimumSize: const Size(0, 44)),
              )),
              const SizedBox(width: 12),
            ],
            Expanded(child: ElevatedButton.icon(
              onPressed: () => _openChat(req),
              icon: const Icon(Icons.chat, size: 18), label: const Text('Chat'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), minimumSize: const Size(0, 44)),
            )),
          ]),
        ]),
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
