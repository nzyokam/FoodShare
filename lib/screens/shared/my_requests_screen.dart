// screens/shelter/my_requests_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/donation_model.dart';
import '../../models/request_model.dart';
import '../../models/restaurant_model.dart';
import '../shelter/chat_screen.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
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

  Stream<List<RequestWithDetails>> _getMyRequestsStream(String status) {
    final user = _authService.currentUser!;
    
    return FirebaseFirestore.instance
        .collection('requests')
        .where('shelterId', isEqualTo: user.uid)
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      List<RequestWithDetails> requests = [];
      
      for (var doc in snapshot.docs) {
        final request = DonationRequest.fromJson(doc.data(), docId: doc.id);
        
        // Get donation details
        final donationDoc = await FirebaseFirestore.instance
            .collection('donations')
            .doc(request.donationId)
            .get();
        
        if (!donationDoc.exists) continue;
        
        final donation = Donation.fromJson(donationDoc.data()!, docId: donationDoc.id);
        
        // Get restaurant details
        final restaurantDoc = await FirebaseFirestore.instance
            .collection('restaurants')
            .doc(donation.donorId)
            .get();
        
        if (!restaurantDoc.exists) continue;
        
        final restaurant = Restaurant.fromJson(restaurantDoc.data()!);
        
        requests.add(RequestWithDetails(
          request: request,
          donation: donation,
          restaurant: restaurant,
        ));
      }
      
      return requests;
    });
  }

  Future<void> _cancelRequest(DonationRequest request) async {
    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cancel Request'),
          content: const Text('Are you sure you want to cancel this request?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Yes, Cancel'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      await FirebaseFirestore.instance
          .collection('requests')
          .doc(request.id)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request cancelled successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cancelling request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('My Requests'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
            Tab(text: 'Declined'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRequestsList('pending'),
          _buildRequestsList('approved'),
          _buildRequestsList('declined'),
        ],
      ),
    );
  }

  Widget _buildRequestsList(String status) {
    return StreamBuilder<List<RequestWithDetails>>(
      stream: _getMyRequestsStream(status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading requests: ${snapshot.error}'),
          );
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getStatusIcon(status),
                  size: 64,
                  color: Theme.of(context).colorScheme.primary.withAlpha(100),
                ),
                const SizedBox(height: 16),
                Text(
                  'No $status requests',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getStatusMessage(status),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final requestDetails = requests[index];
            return _buildRequestCard(requestDetails, status);
          },
        );
      },
    );
  }

  Widget _buildRequestCard(RequestWithDetails requestDetails, String status) {
    final request = requestDetails.request;
    final donation = requestDetails.donation;
    final restaurant = requestDetails.restaurant;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Restaurant Info
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF2E7D32).withAlpha(20),
                  child: const Icon(
                    Icons.restaurant,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        restaurant.businessName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${restaurant.city} • ${restaurant.cuisineTypes.isNotEmpty ? restaurant.cuisineTypes.first : 'Restaurant'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      color: _getStatusColor(status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Donation Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha(10),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withAlpha(50),
                ),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: donation.imageUrls.isNotEmpty
                        ? Image.network(
                            donation.imageUrls.first,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 50,
                                height: 50,
                                color: Colors.grey[300],
                                child: const Icon(Icons.fastfood, size: 20),
                              );
                            },
                          )
                        : Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey[300],
                            child: const Icon(Icons.fastfood, size: 20),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          donation.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${donation.quantity} ${donation.unit}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Expires: ${donation.expiryDate.toDate().day}/${donation.expiryDate.toDate().month}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
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
            
            const SizedBox(height: 16),
            
            // Request Message
            Text(
              'Your Message:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              request.message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(180),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Time Info
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
                ),
                const SizedBox(width: 4),
                Text(
                  'Requested ${_formatDate(request.createdAt.toDate())}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
                  ),
                ),
                if (request.respondedAt != null) ...[
                  const SizedBox(width: 16),
                  Icon(
                    _getResponseIcon(status),
                    size: 14,
                    color: _getStatusColor(status),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_getResponseText(status)} ${_formatDate(request.respondedAt!.toDate())}',
                    style: TextStyle(
                      fontSize: 12,
                      color: _getStatusColor(status),
                    ),
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              children: [
                if (status == 'pending') ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _cancelRequest(request),
                      icon: const Icon(Icons.cancel, size: 18),
                      label: const Text('Cancel Request'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(donation: donation),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat, size: 18),
                    label: const Text('Chat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'approved':
        return Icons.check_circle;
      case 'declined':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  IconData _getResponseIcon(String status) {
    switch (status) {
      case 'approved':
        return Icons.check_circle;
      case 'declined':
        return Icons.cancel;
      default:
        return Icons.schedule;
    }
  }

  String _getResponseText(String status) {
    switch (status) {
      case 'approved':
        return 'Approved';
      case 'declined':
        return 'Declined';
      default:
        return 'Pending';
    }
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case 'pending':
        return 'Your pending requests will appear here';
      case 'approved':
        return 'Approved requests will appear here';
      case 'declined':
        return 'Declined requests will appear here';
      default:
        return '';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'declined':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}

class RequestWithDetails {
  final DonationRequest request;
  final Donation donation;
  final Restaurant restaurant;

  RequestWithDetails({
    required this.request,
    required this.donation,
    required this.restaurant,
  });
}