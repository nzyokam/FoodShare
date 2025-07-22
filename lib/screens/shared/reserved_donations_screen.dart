// screens/shelter/reserved_donations_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/donation_model.dart';
import '../../models/restaurant_model.dart';
import '../shelter/chat_screen.dart';

class ReservedDonationsScreen extends StatefulWidget {
  const ReservedDonationsScreen({super.key});

  @override
  State<ReservedDonationsScreen> createState() => _ReservedDonationsScreenState();
}

class _ReservedDonationsScreenState extends State<ReservedDonationsScreen> {
  final AuthService _authService = AuthService();

  Stream<List<DonationWithRestaurant>> _getReservedDonationsStream() {
    final user = _authService.currentUser!;
    
    return FirebaseFirestore.instance
        .collection('donations')
        .where('reservedBy', isEqualTo: user.uid)
        .where('status', whereIn: ['reserved', 'completed'])
        .orderBy('reservedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      List<DonationWithRestaurant> donations = [];
      
      for (var doc in snapshot.docs) {
        final donation = Donation.fromJson(doc.data(), docId: doc.id);
        
        // Get restaurant details
        final restaurantDoc = await FirebaseFirestore.instance
            .collection('restaurants')
            .doc(donation.donorId)
            .get();
        
        if (!restaurantDoc.exists) continue;
        
        final restaurant = Restaurant.fromJson(restaurantDoc.data()!);
        
        donations.add(DonationWithRestaurant(
          donation: donation,
          restaurant: restaurant,
        ));
      }
      
      return donations;
    });
  }

  Future<void> _markAsCompleted(Donation donation) async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Mark as Completed'),
          content: const Text('Have you successfully picked up this donation?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Yes, Completed'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      await FirebaseFirestore.instance
          .collection('donations')
          .doc(donation.id)
          .update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Donation marked as completed! Thank you for helping fight hunger.'),
          backgroundColor: Colors.green,
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
        title: const Text('Reserved Donations'),
      ),
      body: StreamBuilder<List<DonationWithRestaurant>>(
        stream: _getReservedDonationsStream(),
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
                    Icons.bookmark_border,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary.withAlpha(100),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No reserved donations',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Donations reserved for you will appear here',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Separate active and completed donations
          final activeDonations = donations.where((d) => d.donation.status == DonationStatus.reserved).toList();
          final completedDonations = donations.where((d) => d.donation.status == DonationStatus.completed).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (activeDonations.isNotEmpty) ...[
                  Text(
                    'Ready for Pickup (${activeDonations.length})',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...activeDonations.map((donationWithRestaurant) => 
                    _buildDonationCard(donationWithRestaurant, isActive: true)
                  ),
                  
                  if (completedDonations.isNotEmpty) const SizedBox(height: 32),
                ],
                
                if (completedDonations.isNotEmpty) ...[
                  Text(
                    'Completed (${completedDonations.length})',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...completedDonations.map((donationWithRestaurant) => 
                    _buildDonationCard(donationWithRestaurant, isActive: false)
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDonationCard(DonationWithRestaurant donationWithRestaurant, {required bool isActive}) {
    final donation = donationWithRestaurant.donation;
    final restaurant = donationWithRestaurant.restaurant;
    final now = DateTime.now();
    final expiryDate = donation.expiryDate.toDate();
    final isExpiringSoon = expiryDate.difference(now).inHours < 12;
    final pickupTime = donation.pickupTime.toDate();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isActive && isExpiringSoon 
            ? const BorderSide(color: Colors.red, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Restaurant Info and Status
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
                        '${restaurant.address}, ${restaurant.city}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.orange.withAlpha(20) : Colors.green.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isActive ? 'RESERVED' : 'COMPLETED',
                    style: TextStyle(
                      fontSize: 10,
                      color: isActive ? Colors.orange : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
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
                        donation.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${donation.quantity} ${donation.unit}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
                        ),
                      ),
                      const SizedBox(height: 8),
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
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Description
            if (donation.description.isNotEmpty) ...[
              Text(
                donation.description,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(180),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
            ],
            
            // Time Information
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isExpiringSoon && isActive
                    ? Colors.red.withAlpha(20)
                    : Theme.of(context).colorScheme.primary.withAlpha(10),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isExpiringSoon && isActive
                      ? Colors.red.withAlpha(100)
                      : Theme.of(context).colorScheme.primary.withAlpha(50),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color: isActive ? Colors.blue : Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Pickup Time: ${pickupTime.day}/${pickupTime.month} at ${pickupTime.hour.toString().padLeft(2, '0')}:${pickupTime.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isActive ? Colors.blue : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: isExpiringSoon && isActive ? Colors.red : Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Expires: ${expiryDate.day}/${expiryDate.month} at ${expiryDate.hour.toString().padLeft(2, '0')}:${expiryDate.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 14,
                          color: isExpiringSoon && isActive ? Colors.red : Colors.grey[600],
                          fontWeight: isExpiringSoon && isActive ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      if (isExpiringSoon && isActive) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
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
                  if (!isActive && donation.reservedAt != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Colors.green[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Reserved: ${_formatDate(donation.reservedAt!.toDate())}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.green[600],
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
                if (isActive) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _markAsCompleted(donation),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Mark as Picked Up'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(donation: donation),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat, size: 18),
                    label: const Text('Chat with Restaurant'),
                    style: OutlinedButton.styleFrom(
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

class DonationWithRestaurant {
  final Donation donation;
  final Restaurant restaurant;

  DonationWithRestaurant({
    required this.donation,
    required this.restaurant,
  });
}