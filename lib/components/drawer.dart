// components/drawer.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:foodshare/components/my_drawer_tile.dart';
import 'package:foodshare/models/user_model.dart';
import 'package:foodshare/screens/restaurant/restaurant_dashboard.dart';
import 'package:foodshare/screens/shared/shelter_dashboard.dart';

class MyDrawer extends StatelessWidget {
  final Function(int) onItemSelected;

  const MyDrawer({super.key, required this.onItemSelected});

  Future<UserType?> _getUserType() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) return null;

      final userTypeString = doc.data()?['userType'] as String?;
      return userTypeString == 'restaurant'
          ? UserType.restaurant
          : UserType.shelter;
    } catch (e) {
      print('Error getting user type: $e');
      return null;
    }
  }

  Future<void> _navigateToDashboard(BuildContext context) async {
    Navigator.pop(context); // Close drawer first

    final userType = await _getUserType();
    if (userType == null) return;

    // Get current route to avoid stacking
    final currentRoute = ModalRoute.of(context)?.settings.name;

    Widget targetDashboard;
    String targetRoute;

    if (userType == UserType.restaurant) {
      targetDashboard = const RestaurantDashboard();
      targetRoute = '/restaurant_dashboard';
    } else {
      targetDashboard = const ShelterDashboard();
      targetRoute = '/shelter_dashboard';
    }

    // Only navigate if we're not already on the target dashboard
    if (currentRoute != targetRoute) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => targetDashboard,
          settings: RouteSettings(name: targetRoute),
        ),
        (route) => false, // Remove all previous routes
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          const SizedBox(height: 100),
          Image.asset(
            'lib/assets/2.png',
            width: 120,
            height: 120,
            fit: BoxFit.contain,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Divider(
              color: Theme.of(context).colorScheme.inversePrimary,
              thickness: 1,
            ),
          ),
          MyDrawerTile(
            text: 'D A S H B O A R D',
            icon: Icons.home,
            onTap: () => _navigateToDashboard(context),
          ),
          MyDrawerTile(
            text: 'P R O F I L E',
            icon: Icons.person,
            onTap: () {
              Navigator.pop(context);
              onItemSelected(1);
            },
          ),
          MyDrawerTile(
            text: 'S E T T I N G S',
            icon: Icons.settings,
            onTap: () {
              Navigator.pop(context);
              onItemSelected(2);
            },
          ),

          const Spacer(),
          MyDrawerTile(
            text: 'S I G N  O U T',
            icon: Icons.logout,
            onTap: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
            },
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }
}
