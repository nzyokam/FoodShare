// screens/shared/shelter_dashboard.dart
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:foodshare/screens/shared/browse_donations_screen.dart';
import 'package:foodshare/screens/shared/my_requests_screen.dart';
import 'package:foodshare/screens/shelter/profile_screen.dart';
import 'package:foodshare/screens/shelter/settings_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:foodshare/screens/shared/chats_list_screen.dart';
import '../../services/auth_service.dart';
//import '../../models/donation_model.dart';
import '../../models/shelter_model.dart';

import 'package:foodshare/models/user_model.dart';

class ShelterDashboard extends StatefulWidget {
  const ShelterDashboard({super.key});

  @override
  State<ShelterDashboard> createState() => _ShelterDashboardState();
}

class _ShelterDashboardState extends State<ShelterDashboard> {
  final AuthService _authService = AuthService();
  int _selectedIndex = 0;
  Shelter? _shelter;

  // Analytics data
  int _totalRequests = 0;
  int _approvedRequests = 0;
  int _completedRequests = 0;
  int _availableDonations = 0;

  @override
  void initState() {
    super.initState();
    _loadShelterData();
    _loadAnalytics();
  }

  Future<void> _loadShelterData() async {
    try {
      final user = _authService.currentUser!;
      final doc = await FirebaseFirestore.instance
          .collection('shelters')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        setState(() {
          _shelter = Shelter.fromJson(doc.data()!);
        });
      }
    } catch (e) {
      print('Error loading shelter data: $e');
    }
  }

  Future<void> _loadAnalytics() async {
    try {
      final user = _authService.currentUser!;

      // Get shelter's requests
      final requestsSnapshot = await FirebaseFirestore.instance
          .collection('requests')
          .where('shelterId', isEqualTo: user.uid)
          .get();

      final requests = requestsSnapshot.docs;
      final approvedCount = requests
          .where((doc) => doc.data()['status'] == 'approved')
          .length;
      final completedCount = requests
          .where((doc) => doc.data()['status'] == 'completed')
          .length;

      // Get available donations in shelter's city
      final availableDonationsSnapshot = await FirebaseFirestore.instance
          .collection('donations')
          .where('status', isEqualTo: 'available')
          .where('city', isEqualTo: _shelter?.city ?? '')
          .get();

      setState(() {
        _totalRequests = requests.length;
        _approvedRequests = approvedCount;
        _completedRequests = completedCount;
        _availableDonations = availableDonationsSnapshot.docs.length;
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
          userType: UserType.shelter,
          onDrawerItemSelected: _onDrawerItemSelected,
        );
      case 2:
        return SettingsScreen(onDrawerItemSelected: _onDrawerItemSelected);
      case 3:
        return ChatsListScreen(
          userType: UserType.shelter,
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
                        builder: (_) => const BrowseDonationsScreen(),
                      ),
                    ).then((_) => _loadAnalytics());
                  },
                  icon: const Icon(Icons.search),
                  tooltip: 'Find Donations',
                ),
              ],
            )
          : null,

      body: _getSelectedScreen(),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color.fromARGB(144, 19, 30, 20),
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
        await _loadShelterData();
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
                      color: Colors.white.withAlpha(5),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(20),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
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
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _shelter?.organizationName ?? 'Organization',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Helping our community through food recovery! 🤝',
                        style: TextStyle(
                          color: Colors.white.withAlpha(188),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
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
                    'Total Requests',
                    _totalRequests.toString(),
                    Icons.inbox,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAnalyticsCard(
                    'Approved',
                    _approvedRequests.toString(),
                    Icons.check_circle,
                    Colors.green,
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
                    _completedRequests.toString(),
                    Icons.done_all,
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAnalyticsCard(
                    'Available Now',
                    _availableDonations.toString(),
                    Icons.fastfood,
                    Colors.orange,
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
                    'Find Food',
                    'Browse donations',
                    Icons.search,
                    const Color(0xFF2E7D32),
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BrowseDonationsScreen(),
                      ),
                    ).then((_) => _loadAnalytics()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionCard(
                    'My Requests',
                    'Track your requests',
                    Icons.list_alt,
                    Colors.blue,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MyRequestsScreen(),
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
                    'Chats',
                    'View conversations',
                    Icons.chat,
                    Colors.cyan,
                    () => setState(() => _selectedIndex = 3),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionCard(
                    'Profile',
                    'Update info',
                    Icons.person,
                    Colors.indigo,
                    () => setState(() => _selectedIndex = 1),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

           

            // Community Impact Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withAlpha(20),
                    Colors.green.withAlpha(20),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF2E7D32).withAlpha(50),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.favorite, color: Colors.red[400], size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Community Impact',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your organization is helping reduce food waste and fight hunger in ${_shelter?.city ?? 'your city'}.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha(180),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_completedRequests > 0)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.eco, color: Colors.green[600], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'You\'ve successfully collected $_completedRequests donations! 🌟',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.green[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
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
