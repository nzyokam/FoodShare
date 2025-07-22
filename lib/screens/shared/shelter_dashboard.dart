// screens/shelter/shelter_dashboard.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
// import 'package:foodsharing/pages/settings_page.dart';
// import 'package:foodsharing/screens/profile_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../models/donation_model.dart';
import '../../models/shelter_model.dart';
import '../../components/drawer.dart';
import 'browse_donations_screen.dart';
import 'my_requests_screen.dart';
import 'reserved_donations_screen.dart';
import '../shelter/profile_screen.dart';
import '../shelter/settings_screen.dart';

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
  int _availableDonations = 0;
  int _myRequests = 0;
  int _reservedDonations = 0;
  int _completedRequests = 0;

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
      
      // Get available donations in the same city
      final availableSnapshot = await FirebaseFirestore.instance
          .collection('donations')
          .where('status', isEqualTo: 'available')
          .where('city', isEqualTo: _shelter?.city ?? '')
          .get();
      
      // Get my requests
      final requestsSnapshot = await FirebaseFirestore.instance
          .collection('requests')
          .where('shelterId', isEqualTo: user.uid)
          .get();
      
      // Get reserved donations
      final reservedSnapshot = await FirebaseFirestore.instance
          .collection('donations')
          .where('reservedBy', isEqualTo: user.uid)
          .where('status', isEqualTo: 'reserved')
          .get();

      final requests = requestsSnapshot.docs;
      final completedCount = requests
          .where((doc) => doc.data()['status'] == 'approved')
          .length;

      setState(() {
        _availableDonations = availableSnapshot.docs.length;
        _myRequests = requests.length;
        _reservedDonations = reservedSnapshot.docs.length;
        _completedRequests = completedCount;
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
        return ProfileScreen(userType: UserType.shelter);
      case 2:
        return const SettingsScreen();
      default:
        return _buildDashboardHome();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _selectedIndex == 0 ? AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                MaterialPageRoute(builder: (_) => const BrowseDonationsScreen()),
              ).then((_) => _loadAnalytics()); // Refresh analytics
            },
            icon: const Icon(Icons.search),
            tooltip: 'Browse Donations',
          ),
        ],
      ) : null,
      drawer: MyDrawer(onItemSelected: _onDrawerItemSelected),
      body: _getSelectedScreen(),
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back!',
                    style: TextStyle(
                      color: Colors.white.withAlpha(200),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _shelter?.organizationName ?? 'Organization',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Helping feed ${_shelter?.capacity ?? 0} people in your community 🙏',
                    style: TextStyle(
                      color: Colors.white.withAlpha(180),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Analytics Cards
            Text(
              'Your Activity',
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
                    'Available Now',
                    _availableDonations.toString(),
                    Icons.restaurant,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAnalyticsCard(
                    'My Requests',
                    _myRequests.toString(),
                    Icons.send,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildAnalyticsCard(
                    'Reserved',
                    _reservedDonations.toString(),
                    Icons.bookmark,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAnalyticsCard(
                    'Completed',
                    _completedRequests.toString(),
                    Icons.check_circle,
                    Colors.purple,
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
                    'Browse Donations',
                    'Find available food',
                    Icons.search,
                    const Color(0xFF2E7D32),
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BrowseDonationsScreen()),
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
                      MaterialPageRoute(builder: (_) => const MyRequestsScreen()),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            SizedBox(
              width: double.infinity,
              child: _buildActionCard(
                'Reserved Donations',
                'View donations reserved for you',
                Icons.bookmark_border,
                Colors.orange,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReservedDonationsScreen()),
                ),
                isWide: true,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Recent Donations Preview
            Text(
              'Recent Donations Nearby',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            
            const SizedBox(height: 16),
            
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('donations')
                  .where('status', isEqualTo: 'available')
                  .where('city', isEqualTo: _shelter?.city ?? '')
                  .orderBy('createdAt', descending: true)
                  .limit(3)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final donations = snapshot.data!.docs
                    .map((doc) => Donation.fromJson(doc.data() as Map<String, dynamic>, docId: doc.id))
                    .toList();

                if (donations.isEmpty) {
                  return Container(
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
                          Icons.restaurant_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No donations available yet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Check back later for new donations in ${_shelter?.city}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: donations.map((donation) => 
                    _buildDonationPreviewCard(donation)
                  ).toList(),
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // View All Button
            Center(
              child: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BrowseDonationsScreen()),
                ),
                child: const Text('View All Donations →'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, String value, IconData icon, Color color) {
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
    VoidCallback onTap, {
    bool isWide = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(100)),
        ),
        child: isWide
            ? Row(
                children: [
                  Icon(icon, color: color, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: color, size: 16),
                ],
              )
            : Column(
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

  Widget _buildDonationPreviewCard(Donation donation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withAlpha(50),
        ),
      ),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: donation.imageUrls.isNotEmpty
                ? Image.network(
                    donation.imageUrls.first,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported),
                      );
                    },
                  )
                : Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[300],
                    child: const Icon(Icons.fastfood),
                  ),
          ),
          
          const SizedBox(width: 16),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  donation.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${donation.quantity} ${donation.unit}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
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
          
          // Action
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }
}