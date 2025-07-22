// screens/shelter/browse_donations_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/donation_model.dart';
import '../shelter/chat_screen.dart';

class BrowseDonationsScreen extends StatefulWidget {
  const BrowseDonationsScreen({super.key});

  @override
  State<BrowseDonationsScreen> createState() => _BrowseDonationsScreenState();
}

class _BrowseDonationsScreenState extends State<BrowseDonationsScreen> {
  final AuthService _authService = AuthService();
  String _selectedCity = '';
  DonationCategory? _selectedCategory;
  String _searchQuery = '';
  String _shelterCity = '';

  @override
  void initState() {
    super.initState();
    _loadShelterCity();
  }

  Future<void> _loadShelterCity() async {
    try {
      final user = _authService.currentUser!;
      final doc = await FirebaseFirestore.instance
          .collection('shelters')
          .doc(user.uid)
          .get();
      
      if (doc.exists) {
        setState(() {
          _shelterCity = doc.data()?['city'] ?? '';
          
        });
      }
    } catch (e) {
      print('Error loading shelter city: $e');
    }
  }

Stream<List<Donation>> _getDonationsStream() {
  Query query;
  
  // Prioritize city filter as it's likely to reduce results significantly
  if (_selectedCity.isNotEmpty && _selectedCategory != null) {
    // Both city and category - needs index: status + city + category + createdAt
    query = FirebaseFirestore.instance
        .collection('donations')
        .where('status', isEqualTo: 'available')
        .where('city', isEqualTo: _selectedCity)
        .where('category', isEqualTo: _selectedCategory.toString().split('.').last)
        .orderBy('createdAt', descending: true);
  } else if (_selectedCity.isNotEmpty) {
    // Only city - needs index: status + city + createdAt
    query = FirebaseFirestore.instance
        .collection('donations')
        .where('status', isEqualTo: 'available')
        .where('city', isEqualTo: _selectedCity)
        .orderBy('createdAt', descending: true);
  } else if (_selectedCategory != null) {
    // Only category - needs index: status + category + createdAt
    query = FirebaseFirestore.instance
        .collection('donations')
        .where('status', isEqualTo: 'available')
        .where('category', isEqualTo: _selectedCategory.toString().split('.').last)
        .orderBy('createdAt', descending: true);
  } else {
    // No filters - simple query
    query = FirebaseFirestore.instance
        .collection('donations')
        .where('status', isEqualTo: 'available')
        .orderBy('createdAt', descending: true);
  }

  return query.snapshots().map((snapshot) {
    List<Donation> donations = snapshot.docs
        .map((doc) => Donation.fromJson(doc.data() as Map<String, dynamic>, docId: doc.id))
        .toList();

    // Apply search filter in memory (since text search needs special handling)
    if (_searchQuery.isNotEmpty) {
      donations = donations.where((donation) =>
          donation.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          donation.description.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    return donations;
  });
}

  Future<void> _requestDonation(Donation donation) async {
    final messageController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Donation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Requesting: ${donation.title}'),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Message to restaurant',
                hintText: 'Explain why you need this donation and how it will help...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _submitRequest(donation, messageController.text);
              Navigator.pop(context);
            },
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitRequest(Donation donation, String message) async {
    if (message.trim().isEmpty) {
      _showError('Please add a message with your request');
      return;
    }

    try {
      final user = _authService.currentUser!;
      
      // Check if request already exists
      final existingRequest = await FirebaseFirestore.instance
          .collection('requests')
          .where('shelterId', isEqualTo: user.uid)
          .where('donationId', isEqualTo: donation.id)
          .get();

      if (existingRequest.docs.isNotEmpty) {
        _showError('You have already requested this donation');
        return;
      }

      await FirebaseFirestore.instance.collection('requests').add({
        'shelterId': user.uid,
        'donationId': donation.id,
        'message': message.trim(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request sent successfully!')),
      );
    } catch (e) {
      _showError('Error sending request: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Browse Donations'),
      ),
      body: Column(
        children: [
          // Search and Filters
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search donations...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.primary.withAlpha(20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
                
                const SizedBox(height: 16),
                
                // Filters
                Row(
                  children: [
                    // City Filter
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCity.isEmpty ? null : _selectedCity,
                        decoration: InputDecoration(
                          labelText: 'City',
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.primary.withAlpha(20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: ['', 'Nairobi', 'Mombasa', 'Nakuru', 'Eldoret', 'Kisumu', 'Other']
                            .map((city) => DropdownMenuItem(
                                  value: city,
                                  child: Text(city.isEmpty ? 'All Cities' : city),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() => _selectedCity = value ?? ''),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Category Filter
                    Expanded(
                      child: DropdownButtonFormField<DonationCategory>(
                        value: _selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.primary.withAlpha(20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem<DonationCategory>(
                            value: null,
                            child: Text('All Categories'),
                          ),
                          ...DonationCategory.values.map((category) => DropdownMenuItem(
                                value: category,
                                child: Text(_getCategoryName(category)),
                              )),
                        ],
                        onChanged: (value) => setState(() => _selectedCategory = value),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Donations List
          Expanded(
            child: StreamBuilder<List<Donation>>(
              stream: _getDonationsStream(),
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
                          'Try adjusting your filters or check back later',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: donations.length,
                  itemBuilder: (context, index) {
                    final donation = donations[index];
                    return _buildDonationCard(donation);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonationCard(Donation donation) {
    final now = DateTime.now();
    final expiryDate = donation.expiryDate.toDate();
    final isExpiringSoon = expiryDate.difference(now).inHours < 24;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          if (donation.imageUrls.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                donation.imageUrls.first,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.image_not_supported, size: 50),
                    ),
                  );
                },
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Category
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
                        color: const Color(0xFF2E7D32).withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getCategoryName(donation.category),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Quantity
                Text(
                  '${donation.quantity} ${donation.unit}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Description
                Text(
                  donation.description,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(180),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 12),
                
                // Time Info
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: isExpiringSoon ? Colors.red : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Expires: ${expiryDate.day}/${expiryDate.month} ${expiryDate.hour.toString().padLeft(2, '0')}:${expiryDate.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isExpiringSoon ? Colors.red : Colors.grey[600],
                        fontWeight: isExpiringSoon ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    if (isExpiringSoon) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'URGENT',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                
                const SizedBox(height: 4),
                
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Pickup: ${donation.pickupTime.toDate().day}/${donation.pickupTime.toDate().month} ${donation.pickupTime.toDate().hour.toString().padLeft(2, '0')}:${donation.pickupTime.toDate().minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _requestDonation(donation),
                        icon: const Icon(Icons.send, size: 18),
                        label: const Text('Request'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
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
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
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
}