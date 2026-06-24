import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/request_model.dart';
import '../../providers/requests_provider.dart';
import '../../services/chat_service.dart';
import '../../services/request_service.dart';
import '../../widgets/app_snackbar.dart';
import '../shelter/chat_screen.dart';

class DonationRequestsScreen extends ConsumerStatefulWidget {
  const DonationRequestsScreen({super.key});

  @override
  ConsumerState<DonationRequestsScreen> createState() => _DonationRequestsScreenState();
}

class _DonationRequestsScreenState extends ConsumerState<DonationRequestsScreen> with TickerProviderStateMixin {
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

  Future<void> _handleRequest(DonationRequest request, bool approve) async {
    try {
      if (approve) {
        await RequestService.approveRequest(request.id);
      } else {
        await RequestService.declineRequest(request.id);
      }
      ref.invalidate(receivedRequestsProvider);
      if (mounted) {
        approve ? AppSnackBar.showSuccess(context, 'Request approved!') : AppSnackBar.showWarning(context, 'Request declined');
      }
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, 'Error: $e');
    }
  }

  Future<void> _openChat(DonationRequest request) async {
    try {
      final chat = await ChatService.getOrCreateChat(request.donationId, shelterId: request.shelterId);
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(
        chatId: chat.id,
        title: request.otherPartyName ?? 'Shelter Chat',
        donationTitle: request.donationTitle ?? '',
      )));
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(receivedRequestsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(children: [Image.asset('lib/assets/transparent.png', width: 32, height: 32), const SizedBox(width: 10), const Text('Donation Requests')]),
        bottom: TabBar(controller: _tabController, tabs: const [Tab(text: 'Pending'), Tab(text: 'Approved'), Tab(text: 'Declined')]),
      ),
      body: requestsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (all) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(receivedRequestsProvider),
          child: TabBarView(
            controller: _tabController,
            children: ['pending', 'approved', 'declined'].map((s) => _requestsList(_filtered(all, s), s)).toList(),
          ),
        ),
      ),
    );
  }

  Widget _requestsList(List<DonationRequest> requests, String status) {
    if (requests.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(_statusIcon(status), size: 64, color: Theme.of(context).colorScheme.primary.withAlpha(100)),
          const SizedBox(height: 16),
          Text('No $status requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 8),
          Text(_statusMessage(status), style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha(160)), textAlign: TextAlign.center),
        ]),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: requests.length,
      itemBuilder: (_, i) => _requestCard(requests[i], status),
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
            CircleAvatar(backgroundColor: const Color(0xFF2E7D32).withAlpha(20), child: const Icon(Icons.home, color: Color(0xFF2E7D32))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(req.otherPartyName ?? 'Shelter', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ])),
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
              ])),
            ]),
          ),
          const SizedBox(height: 16),
          Text('Request Message:', style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 4),
          Text(req.message ?? '(no message)', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha(180))),
          const SizedBox(height: 16),
          Row(children: [
            Icon(Icons.access_time, size: 14, color: Theme.of(context).colorScheme.onSurface.withAlpha(160)),
            const SizedBox(width: 4),
            Text('Requested ${_ago(req.createdAt)}', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withAlpha(160))),
            if (req.respondedAt != null) ...[
              const SizedBox(width: 16),
              Text('Responded ${_ago(req.respondedAt!)}', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withAlpha(160))),
            ],
          ]),
          if (status == 'pending') ...[
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: ElevatedButton.icon(onPressed: () => _handleRequest(req, true), icon: const Icon(Icons.check, size: 18), label: const Text('Approve'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))))),
              const SizedBox(width: 12),
              Expanded(child: OutlinedButton.icon(onPressed: () => _handleRequest(req, false), icon: const Icon(Icons.close, size: 18), label: const Text('Decline'), style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))))),
            ]),
          ],
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _openChat(req),
            icon: const Icon(Icons.chat, size: 16),
            label: const Text('Chat with shelter'),
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
          ),
        ]),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final c = _statusColor(status);
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: c.withAlpha(20), borderRadius: BorderRadius.circular(12)), child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, color: c, fontWeight: FontWeight.bold)));
  }

  Widget _placeholder() => Container(width: 50, height: 50, color: Colors.grey[300], child: const Icon(Icons.fastfood, size: 20));

  Color _statusColor(String s) => s == 'approved' ? Colors.green : s == 'declined' ? Colors.red : Colors.orange;
  IconData _statusIcon(String s) => s == 'approved' ? Icons.check_circle : s == 'declined' ? Icons.cancel : Icons.pending;
  String _statusMessage(String s) => s == 'pending' ? 'New requests will appear here' : s == 'approved' ? 'Approved requests will appear here' : 'Declined requests will appear here';

  String _ago(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inDays > 0) return '${d.inDays} days ago';
    if (d.inHours > 0) return '${d.inHours} hours ago';
    if (d.inMinutes > 0) return '${d.inMinutes} minutes ago';
    return 'just now';
  }
}
