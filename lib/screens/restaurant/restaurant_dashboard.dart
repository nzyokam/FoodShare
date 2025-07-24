// screens/restaurant/restaurant_dashboard.dart
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:foodshare/screens/shelter/profile_screen.dart';
import 'package:foodshare/screens/shelter/settings_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../models/donation_model.dart';
import '../../models/restaurant_model.dart';


import '../shared/chats_list_screen.dart';
import 'add_donation_screen.dart';
import 'my_donations_screen.dart';
import 'donation_requests_screen.dart';
import 'package:foodshare/models/user_model.dart';

class RestaurantDashboard extends StatefulWidget {
  const RestaurantDashboard({super.key});

  @override
  State<RestaurantDashboard> createState() => _RestaurantDashboardState();
}

class _RestaurantDashboardState extends State<RestaurantDashboard> {
  final AuthService _authService = AuthService();
  int _selectedIndex = 0;
  Restaurant? _restaurant;

  // Analytics data
  int _totalDonations = 0;
  int _activeDonations = 0;
  int _completedDonations = 0;
  int _pendingRequests = 0;

  @override
  void initState() {
    super.initState();
    _loadRestaurantData();
    _loadAnalytics();
  }

  Future<void> _loadRestaurantData() async {
    try {
      final user = _authService.currentUser!;
      final doc = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        setState(() {
          _restaurant = Restaurant.fromJson(doc.data()!);
        });
      }
    } catch (e) {
      print('Error loading restaurant data: $e');
    }
  }

  Future<void> _loadAnalytics() async {
    try {
      final user = _authService.currentUser!;

      // Get all donations
      final donationsSnapshot = await FirebaseFirestore.instance
          .collection('donations')
          .where('donorId', isEqualTo: user.uid)
          .get();

      // Get pending requests
      final requestsSnapshot = await FirebaseFirestore.instance
          .collection('requests')
          .where('status', isEqualTo: 'pending')
          .get();

      // Count pending requests for this restaurant's donations
      int pendingCount = 0;
      for (var request in requestsSnapshot.docs) {
        final donationId = request.data()['donationId'];
        final donationExists = donationsSnapshot.docs.any(
          (donation) => donation.id == donationId,
        );
        if (donationExists) pendingCount++;
      }

      final donations = donationsSnapshot.docs
          .map((doc) => Donation.fromJson(doc.data(), docId: doc.id))
          .toList();

      setState(() {
        _totalDonations = donations.length;
        _activeDonations = donations
            .where((d) => d.status == DonationStatus.available)
            .length;
        _completedDonations = donations
            .where((d) => d.status == DonationStatus.completed)
            .length;
        _pendingRequests = pendingCount;
      });
    } catch (e) {
      print('Error loading analytics: $e');
    }
  }

  void _onDrawerItemSelected(int index) {
    setState(() => _selectedIndex = index);
  }

  Widget _getSelectedScreen() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardHome();
      case 1:
        return ProfileScreen(
          userType: UserType.restaurant,
          onDrawerItemSelected: _onDrawerItemSelected,
        );
      case 2:
        return SettingsScreen(onDrawerItemSelected: _onDrawerItemSelected);
      case 3:
        return ChatsListScreen(
          userType: UserType.restaurant,
          onDrawerItemSelected: _onDrawerItemSelected,
        );
      default:
        return _buildDashboardHome();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _selectedIndex == 0
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: Padding(
                padding: const EdgeInsets.only(left: 15.0),
                child: Image.asset(
                  'lib/assets/4.png',
                  width: 150,
                  height: 150,
                  fit: BoxFit.contain,
                ),
              ),
              title: Text(
                'Dashboard',
                style: GoogleFonts.poppins(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              actions: [
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddDonationScreen(),
                      ),
                    ).then((_) => _loadAnalytics()); //refresh analytics
                  },
                  icon: const Icon(Icons.add_circle),
                  tooltip: 'Add Donation',
                ),
              ],
            )
          : null,

      body: _getSelectedScreen(),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color.fromARGB(122, 19, 30, 20),
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF2E7D32),
        unselectedItemColor: const Color.fromARGB(255, 255, 255, 255),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chats'),
        ],
      ),
    );
  }

  Widget _buildDashboardHome() {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadAnalytics();
        await _loadRestaurantData();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(38),
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF2E7D32).withAlpha(63),
                        const Color(0xFF81C784).withAlpha(63),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withAlpha(63),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(20),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back!',
                        style: TextStyle(
                          color: Colors.white.withAlpha(213),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _restaurant?.businessName ?? 'Restaurant',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Your donations are making a difference! 🌟',
                        style: TextStyle(
                          color: Colors.white.withAlpha(188),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Analytics Cards
            Text(
              'Your Impact',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildAnalyticsCard(
                    'Total Donations',
                    _totalDonations.toString(),
                    Icons.fastfood,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAnalyticsCard(
                    'Active',
                    _activeDonations.toString(),
                    Icons.access_time,
                    Colors.orange,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildAnalyticsCard(
                    'Completed',
                    _completedDonations.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAnalyticsCard(
                    'Pending Requests',
                    _pendingRequests.toString(),
                    Icons.notifications,
                    Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Quick Actions
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    'Add Donation',
                    'Share surplus food',
                    Icons.add_circle,
                    const Color(0xFF2E7D32),
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddDonationScreen(),
                      ),
                    ).then((_) => _loadAnalytics()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionCard(
                    'My Donations',
                    'Manage listings',
                    Icons.list_alt,
                    Colors.blue,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MyDonationsScreen(),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    'Requests',
                    'Review requests',
                    Icons.inbox,
                    Colors.purple,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DonationRequestsScreen(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionCard(
                    'Chats',
                    'View conversations',
                    Icons.chat,
                    Colors.cyan,
                    () => setState(() => _selectedIndex = 3),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Recent Activity (placeholder for now)
            Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),

            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withAlpha(50),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.timeline,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Activity Feed Coming Soon',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Track your donation history and shelter interactions',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha(160),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(100)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
