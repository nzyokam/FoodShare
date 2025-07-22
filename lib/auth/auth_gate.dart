// auth/auth_gate.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:foodsharing/auth/auth_page.dart';
import 'package:foodsharing/models/user_model.dart';
//import '../services/auth_service.dart';
import '../screens/restaurant/restaurant_dashboard.dart';
import '../screens/shared/shelter_dashboard.dart';

import 'user_type_selection.dart';
import 'profile_setup/restaurant_profile_setup.dart';
import 'profile_setup/shelter_profile_setup.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Not authenticated
        if (!snapshot.hasData || snapshot.data == null) {
          return const AuthPage(); 
        }

        // User is authenticated, check profile completion status
        return StreamBuilder<ProfileStatus>(
          stream: _getProfileStatusStream(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final status = profileSnapshot.data ?? ProfileStatus.incomplete;

            switch (status) {
              case ProfileStatus.noUserType:
                return const UserTypeSelection();
                
              case ProfileStatus.incompleteRestaurant:
                return const RestaurantProfileSetup();
                
              case ProfileStatus.incompleteShelter:
                return const ShelterProfileSetup();
                
              case ProfileStatus.completeRestaurant:
                return const RestaurantDashboard();
                
              case ProfileStatus.completeShelter:
                return const ShelterDashboard();
                
              default:
                return const UserTypeSelection();
            }
          },
        );
      },
    );
  }

  
  Stream<ProfileStatus> _getProfileStatusStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(ProfileStatus.incomplete);

    // Listen to real-time changes in user document
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .asyncMap((doc) async {
      if (!doc.exists) {
        return ProfileStatus.noUserType;
      }

      final userData = doc.data()!;
      final userTypeString = userData['userType'] as String?;
      final profileComplete = userData['profileComplete'] as bool? ?? false;

      if (userTypeString == null) {
        return ProfileStatus.noUserType;
      }

      final userType = userTypeString == 'restaurant' 
          ? UserType.restaurant 
          : UserType.shelter;

      if (profileComplete) {
        return userType == UserType.restaurant 
            ? ProfileStatus.completeRestaurant 
            : ProfileStatus.completeShelter;
      } else {
        return userType == UserType.restaurant 
            ? ProfileStatus.incompleteRestaurant 
            : ProfileStatus.incompleteShelter;
      }
    });
  }
}

enum ProfileStatus {
  noUserType,
  incompleteRestaurant,
  incompleteShelter,
  completeRestaurant,
  completeShelter,
  incomplete,
}

