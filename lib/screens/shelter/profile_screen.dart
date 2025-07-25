import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:foodshare/screens/shared/edit_profile_screen.dart';
import '../../services/auth_service.dart';
import '../../models/restaurant_model.dart';
import '../../models/shelter_model.dart';
import 'dart:ui';
import 'package:foodshare/models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  final UserType userType;
  final Function(int)? onDrawerItemSelected;
  const ProfileScreen({
    super.key,
    required this.userType,
    required this.onDrawerItemSelected,
  });

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
      appBar: AppBar(
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
           
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                // Main profile card 
                Container(
                  
                  margin: const EdgeInsets.only(top: 30), 
                  width: double.infinity,
                  
                  padding: const EdgeInsets.only(
                    top: 60, 
                    bottom: 24,
                    left: 24,
                    right: 24,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        padding: const EdgeInsets.all(30), 
                        decoration: BoxDecoration(
                          
                          color: Theme.of(context).colorScheme.surface.withAlpha(230),
                         
                          border: Border.all(
                            color: Colors.grey.withAlpha(100),
                            width: 1.5,
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
                          children: [
                            // Organization/Restaurant Name
                            Text(
                              widget.userType == UserType.restaurant
                                  ? (_restaurant?.businessName ?? 'Restaurant')
                                  : (_shelter?.organizationName ?? 'Organization'),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Account Type Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E7D32).withAlpha(51),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF2E7D32).withAlpha(100),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                widget.userType == UserType.restaurant
                                    ? 'Restaurant Account'
                                    : 'Shelter Account',
                                style:  TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Email
                            Text(
                              _authService.currentUser?.email ?? '',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withAlpha(180),
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Overlapping Circle Avatar
                Positioned(
                  top: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(51), 
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: const Color.fromARGB(255, 16, 47, 18), 
                      child: Icon(
                        widget.userType == UserType.restaurant
                            ? Icons.restaurant
                            : Icons.home,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
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