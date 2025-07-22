// screens/restaurant/my_donations_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/donation_model.dart';
import 'add_donation_screen.dart';
import '../shelter/chat_screen.dart';

class MyDonationsScreen extends StatefulWidget {
  const MyDonationsScreen({super.key});

  @override
  State<MyDonationsScreen> createState() => _MyDonationsScreenState();
}

class _MyDonationsScreenState extends State<MyDonationsScreen> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

 Stream<List<Donation>> _getMyDonationsStream(DonationStatus? status) {
  final user = _authService.currentUser!;
  
  if (status == null) {
    // All donations - simple query
    return FirebaseFirestore.instance
        .collection('donations')
        .where('donorId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Donation.fromJson(doc.data(), docId: doc.id))
            .toList());
  } else {
    // Specific status - you'll need an index for donorId + status + createdAt
    return FirebaseFirestore.instance
        .collection('donations')
        .where('donorId', isEqualTo: user.uid)
        .where('status', isEqualTo: status.toString().split('.').last)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Donation.fromJson(doc.data(), docId: doc.id))
            .toList());
  }
}

  Future<void> _deleteDonation(Donation donation) async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Donation'),
          content: const Text(
            'Are you sure you want to delete this donation? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Delete associated requests first
      final requestsSnapshot = await FirebaseFirestore.instance
          .collection('requests')
          .where('donationId', isEqualTo: donation.id)
          .get();

      for (var requestDoc in requestsSnapshot.docs) {
        await requestDoc.reference.delete();
      }

      // Delete the donation
      await FirebaseFirestore.instance
          .collection('donations')
          .doc(donation.id)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Donation deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting donation: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleDonationStatus(Donation donation) async {
    try {
      final newStatus = donation.status == DonationStatus.available 
          ? 'cancelled' 
          : 'available';

      await FirebaseFirestore.instance
          .collection('donations')
          .doc(donation.id)
          .update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == 'cancelled' 
                ? 'Donation cancelled' 
                : 'Donation reactivated',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating donation: $e'),
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
        title: const Text('My Donations'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddDonationScreen()),
              );
            },
            icon: const Icon(Icons.add),
            tooltip: 'Add Donation',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Available'),
            Tab(text: 'Reserved'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDonationsList(null),
          _buildDonationsList(DonationStatus.available),
          _buildDonationsList(DonationStatus.reserved),
          _buildDonationsList(DonationStatus.completed),
        ],
      ),
    );
  }

  Widget _buildDonationsList(DonationStatus? status) {
    return StreamBuilder<List<Donation>>(
      stream: _getMyDonationsStream(status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading donations: ${snapshot.error}'),
          );
        }

        final donations = snapshot.data ?? [];

        if (donations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.restaurant_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary.withAlpha(100),
                ),
                const SizedBox(height: 16),
                Text(
                  'No donations found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  status == null 
                      ? 'Your donations will appear here'
                      : 'No ${status.toString().split('.').last} donations',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddDonationScreen()),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Your First Donation'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: donations.length,
          itemBuilder: (context, index) {
            final donation = donations[index];
            return _buildDonationCard(donation);
          },
        );
      },
    );
  }

  Widget _buildDonationCard(Donation donation) {
    final now = DateTime.now();
    final expiryDate = donation.expiryDate.toDate();
    final isExpired = expiryDate.isBefore(now);
    final isExpiringSoon = !isExpired && expiryDate.difference(now).inHours < 24;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isExpiringSoon && donation.status == DonationStatus.available
            ? const BorderSide(color: Colors.orange, width: 2)
            : isExpired
                ? const BorderSide(color: Colors.red, width: 2)
                : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Status
            Row(
              children: [
                Expanded(
                  child: Text(
                    donation.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(donation.status).withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    donation.status.toString().split('.').last.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      color: _getStatusColor(donation.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Donation Details
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: donation.imageUrls.isNotEmpty
                      ? Image.network(
                          donation.imageUrls.first,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[300],
                              child: const Icon(Icons.fastfood, size: 30),
                            );
                          },
                        )
                      : Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[300],
                          child: const Icon(Icons.fastfood, size: 30),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${donation.quantity} ${donation.unit}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(donation.category).withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getCategoryName(donation.category),
                          style: TextStyle(
                            fontSize: 12,
                            color: _getCategoryColor(donation.category),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (donation.description.isNotEmpty)
                        Text(
                          donation.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Time Information
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isExpired
                    ? Colors.red.withAlpha(20)
                    : isExpiringSoon
                        ? Colors.orange.withAlpha(20)
                        : Theme.of(context).colorScheme.primary.withAlpha(10),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isExpired
                      ? Colors.red.withAlpha(100)
                      : isExpiringSoon
                          ? Colors.orange.withAlpha(100)
                          : Theme.of(context).colorScheme.primary.withAlpha(50),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: isExpired || isExpiringSoon ? 
                            (isExpired ? Colors.red : Colors.orange) : 
                            const Color.fromARGB(255, 183, 160, 160),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Expires: ${expiryDate.day}/${expiryDate.month} at ${expiryDate.hour.toString().padLeft(2, '0')}:${expiryDate.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 14,
                          color: isExpired || isExpiringSoon ? 
                              (isExpired ? Colors.red : Colors.orange) : 
                              const Color.fromARGB(255, 199, 199, 199),
                          fontWeight: isExpired || isExpiringSoon ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      if (isExpired) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'EXPIRED',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ] else if (isExpiringSoon && donation.status == DonationStatus.available) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'URGENT',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color: const Color.fromARGB(255, 183, 160, 160),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Pickup: ${donation.pickupTime.toDate().day}/${donation.pickupTime.toDate().month} at ${donation.pickupTime.toDate().hour.toString().padLeft(2, '0')}:${donation.pickupTime.toDate().minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color.fromARGB(255, 199, 199, 199),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Created: ${_formatDate(donation.createdAt.toDate())}',
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color.fromARGB(255, 199, 199, 199),
                        ),
                      ),
                    ],
                  ),
                  if (donation.reservedAt != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.bookmark,
                          size: 16,
                          color: Colors.orange[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Reserved: ${_formatDate(donation.reservedAt!.toDate())}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              children: [
                // Edit Button (only for available donations)
                if (donation.status == DonationStatus.available) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddDonationScreen(donation: donation),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                
                // Chat Button (if reserved or completed)
                if (donation.status == DonationStatus.reserved || 
                    donation.status == DonationStatus.completed) ...[
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
                  const SizedBox(width: 8),
                ],
                
                // Status Toggle Button
                if (donation.status == DonationStatus.available || 
                    donation.status == DonationStatus.cancelled) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _toggleDonationStatus(donation),
                      icon: Icon(
                        donation.status == DonationStatus.available 
                            ? Icons.pause 
                            : Icons.play_arrow,
                        size: 18,
                      ),
                      label: Text(
                        donation.status == DonationStatus.available 
                            ? 'Pause' 
                            : 'Reactivate',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: donation.status == DonationStatus.available 
                            ? Colors.orange 
                            : Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                
                // Delete Button
                if (donation.status != DonationStatus.reserved && 
                    donation.status != DonationStatus.completed) ...[
                  OutlinedButton(
                    onPressed: () => _deleteDonation(donation),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(12),
                    ),
                    child: const Icon(Icons.delete, size: 18),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(DonationStatus status) {
    switch (status) {
      case DonationStatus.available:
        return Colors.green;
      case DonationStatus.reserved:
        return Colors.orange;
      case DonationStatus.completed:
        return Colors.blue;
      case DonationStatus.cancelled:
        return Colors.red;
    }
  }

  Color _getCategoryColor(DonationCategory category) {
    switch (category) {
      case DonationCategory.fruits:
        return Colors.orange;
      case DonationCategory.vegetables:
        return Colors.green;
      case DonationCategory.dairy:
        return Colors.blue;
      case DonationCategory.meat:
        return Colors.red;
      case DonationCategory.preparedMeals:
        return Colors.purple;
      case DonationCategory.grains:
        return Colors.brown;
      case DonationCategory.snacks:
        return Colors.amber;
      case DonationCategory.beverages:
        return Colors.cyan;
      case DonationCategory.other:
        return Colors.grey;
    }
  }

  String _getCategoryName(DonationCategory category) {
    switch (category) {
      case DonationCategory.fruits:
        return 'Fruits';
      case DonationCategory.vegetables:
        return 'Vegetables';
      case DonationCategory.grains:
        return 'Grains';
      case DonationCategory.dairy:
        return 'Dairy';
      case DonationCategory.meat:
        return 'Meat & Fish';
      case DonationCategory.preparedMeals:
        return 'Prepared Meals';
      case DonationCategory.snacks:
        return 'Snacks';
      case DonationCategory.beverages:
        return 'Beverages';
      case DonationCategory.other:
        return 'Other';
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