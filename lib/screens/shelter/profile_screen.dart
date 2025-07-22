import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:foodsharing/screens/shared/edit_profile_screen.dart';
import '../../services/auth_service.dart';
import '../../models/restaurant_model.dart';
import '../../models/shelter_model.dart';
import '../../components/drawer.dart';
import 'package:foodsharing/models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  final UserType userType;
final Function(int)? onDrawerItemSelected;
  const ProfileScreen({super.key, required this.userType, required this.onDrawerItemSelected});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  Restaurant? _restaurant;
  Shelter? _shelter;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _authService.currentUser!;

      if (widget.userType == UserType.restaurant) {
        final doc = await FirebaseFirestore.instance
            .collection('restaurants')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          setState(() {
            _restaurant = Restaurant.fromJson(doc.data()!);
          });
        }
      } else {
        final doc = await FirebaseFirestore.instance
            .collection('shelters')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          setState(() {
            _shelter = Shelter.fromJson(doc.data()!);
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          userType: widget.userType,
          restaurant: _restaurant,
          shelter: _shelter,
        ),
      ),
    );

    // If profile was updated, refresh the data
    if (result == true) {
      _loadUserData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      drawer: MyDrawer(onItemSelected: (index) {
        // Handle drawer navigation - go back to dashboard
        Navigator.pop(context);
      }),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Profile'),
        actions: [
          IconButton(
            onPressed: _navigateToEditProfile,
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.userType == UserType.restaurant
                      ? [
                          const Color.fromARGB(255, 8, 28, 9),
                          const Color(0xFF66BB6A),
                        ]
                      : [
                          const Color.fromARGB(255, 19, 52, 20),
                          const Color(0xFF81C784),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child:
                  //profile header
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white.withAlpha(38),
                        child: Icon(
                          widget.userType == UserType.restaurant
                              ? Icons.restaurant
                              : Icons.home,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        widget.userType == UserType.restaurant
                            ? (_restaurant?.businessName ?? 'Restaurant')
                            : (_shelter?.organizationName ?? 'Organization'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _authService.currentUser?.email ?? '',
                        style: TextStyle(
                          color: Colors.white.withAlpha(213),
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(38),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          widget.userType == UserType.restaurant
                              ? 'Restaurant'
                              : 'Shelter',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
            ),
            const SizedBox(height: 32),

            // Profile Details
            if (widget.userType == UserType.restaurant && _restaurant != null)
              _buildRestaurantDetails(_restaurant!)
            else if (widget.userType == UserType.shelter && _shelter != null)
              _buildShelterDetails(_shelter!),

            const SizedBox(height: 32),

            // Action Buttons
            _buildActionButton(
              'Edit Profile',
              Icons.edit,
              Theme.of(context).colorScheme.primary,
              _navigateToEditProfile,
            ),

            const SizedBox(height: 16),

            _buildActionButton('Sign Out', Icons.logout, Colors.red, () async {
              await _authService.signOut();
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantDetails(Restaurant restaurant) {
    return Column(
      children: [
        _buildDetailCard('Business Information', [
          _buildDetailItem('License', restaurant.businessLicense),
          _buildDetailItem('Address', restaurant.address),
          _buildDetailItem('City', restaurant.city),
          _buildDetailItem('Phone', restaurant.phone),
        ]),

        const SizedBox(height: 16),

        if (restaurant.cuisineTypes.isNotEmpty)
          _buildDetailCard('Cuisine Types', [
            _buildChips(restaurant.cuisineTypes),
          ]),

        const SizedBox(height: 16),

        _buildDetailCard('Description', [
          _buildDetailText(restaurant.description),
        ]),
      ],
    );
  }

  Widget _buildShelterDetails(Shelter shelter) {
    return Column(
      children: [
        _buildDetailCard('Organization Information', [
          _buildDetailItem('Registration Number', shelter.registrationNumber),
          _buildDetailItem('Address', shelter.address),
          _buildDetailItem('City', shelter.city),
          _buildDetailItem('Phone', shelter.phone),
          _buildDetailItem('Capacity', '${shelter.capacity} people'),
          _buildDetailItem('Target Demographic', shelter.targetDemographic),
        ]),

        const SizedBox(height: 16),

        _buildDetailCard('Description', [
          _buildDetailText(shelter.description),
        ]),
      ],
    );
  }

  Widget _buildDetailCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withAlpha(50),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(180),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailText(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        height: 1.5,
      ),
    );
  }

  Widget _buildChips(List<String> items) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map(
            (item) => Chip(
              label: Text(item),
              backgroundColor: Theme.of(
                context,
              ).colorScheme.primary.withAlpha(20),
            ),
          )
          .toList(),
    );
  }

  Widget _buildActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(title),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}