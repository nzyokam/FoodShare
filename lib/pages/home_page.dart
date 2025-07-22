// screens/home_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../components/current_location.dart';
import '../components/description_box.dart';
import '../components/filter_bar.dart';
import '../components/sliver_app_bar.dart';
import '../components/tab_bar.dart';
import '../models/donation_model.dart';
import '../screens/shelter/chat_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final user = FirebaseAuth.instance.currentUser;
  String userName = '';
  late TabController _tabController;
  String selectedCity = '';
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    fetchUserName();
    _tabController = TabController(
      length: DonationCategory.values.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchUserName() async {
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();

        if (doc.exists) {
          setState(() {
            userName = doc.data()?['displayName'] ?? doc.data()?['name'] ?? 'No name';
          });
        } else {
          setState(() {
            userName = 'User not found';
          });
        }
      } catch (e) {
        setState(() {
          userName = 'Error fetching name';
        });
      }
    }
  }

  Stream<List<Donation>> fetchAllDonations() {
    return FirebaseFirestore.instance
        .collection('donations')
        .where('status', isEqualTo: 'available')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Donation.fromJson(doc.data(), docId: doc.id))
          .toList();
    });
  }

  List<Donation> _filterByCategory(DonationCategory category, List<Donation> items) {
    return items.where((donation) {
      final matchesCategory = donation.category == category;
      final matchesCity = selectedCity.isEmpty || donation.city == selectedCity;
      final matchesDate = selectedDate == null ||
          (donation.pickupTime.toDate().year == selectedDate!.year &&
              donation.pickupTime.toDate().month == selectedDate!.month &&
              donation.pickupTime.toDate().day == selectedDate!.day);
      return matchesCategory && matchesCity && matchesDate;
    }).toList();
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
                hintText: 'Explain why you need this donation...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a message with your request'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser!;
      
      // Check if request already exists
      final existingRequest = await FirebaseFirestore.instance
          .collection('requests')
          .where('shelterId', isEqualTo: user.uid)
          .where('donationId', isEqualTo: donation.id)
          .get();

      if (existingRequest.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have already requested this donation'),
            backgroundColor: Colors.orange,
          ),
        );
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
        const SnackBar(
          content: Text('Request sent successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Widget> _buildTabs(List<Donation> allDonations) {
    return DonationCategory.values.map((category) {
      final filtered = _filterByCategory(category, allDonations);

      if (filtered.isEmpty) {
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
                'No donations in this category yet',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final donation = filtered[index];
          final expiryDate = donation.expiryDate.toDate();
          final isExpiringSoon = expiryDate.difference(DateTime.now()).inHours < 24;
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: isExpiringSoon 
                  ? const BorderSide(color: Colors.orange, width: 2)
                  : BorderSide.none,
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Image
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
                      
                      const SizedBox(width: 12),
                      
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              donation.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${donation.quantity} ${donation.unit}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
                                fontWeight: FontWeight.w500,
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
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
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
                    const SizedBox(height: 12),
                  ],
                  
                  // Time info
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: isExpiringSoon ? Colors.orange : Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Expires: ${expiryDate.day}/${expiryDate.month} ${expiryDate.hour.toString().padLeft(2, '0')}:${expiryDate.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isExpiringSoon ? Colors.orange : Colors.grey[600],
                          fontWeight: isExpiringSoon ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      if (isExpiringSoon) ...[
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
                  
                  const SizedBox(height: 4),
                  
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        donation.city,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
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
                      const SizedBox(width: 8),
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
          );
        },
      );
    }).toList();
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
      case DonationCategory.dairy:
        return 'Dairy';
      case DonationCategory.meat:
        return 'Meat & Fish';
      case DonationCategory.grains:
        return 'Grains';
      case DonationCategory.snacks:
        return 'Snacks';
      case DonationCategory.beverages:
        return 'Beverages';
      case DonationCategory.preparedMeals:
        return 'Prepared Meals';
      case DonationCategory.other:
        return 'Other';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          MySliverAppBar(
            title: MyTabBar(tabController: _tabController),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Text(
                  'Welcome, $userName!',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const CurrentLocation(),
                const Divider(indent: 25, endIndent: 25),
                const DescriptionBox(),
                FilterBar(
                  selectedCity: selectedCity,
                  selectedDate: selectedDate,
                  onCityChanged: (city) {
                    setState(() => selectedCity = city);
                  },
                  onDateChanged: (date) {
                    setState(() => selectedDate = date);
                  },
                ),
              ],
            ),
          ),
        ],
        body: StreamBuilder<List<Donation>>(
          stream: fetchAllDonations(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return const Center(child: Text('Failed to load donations.'));
            }

            return TabBarView(
              controller: _tabController,
              children: _buildTabs(snapshot.data!),
            );
          },
        ),
      ),
    );
  }
}