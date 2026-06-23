import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import 'auth_page.dart';
import 'user_type_selection.dart';
import 'profile_setup/restaurant_profile_setup.dart';
import 'profile_setup/shelter_profile_setup.dart';
import '../screens/restaurant/restaurant_dashboard.dart';
import '../screens/shared/shelter_dashboard.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Not logged in → login screen (which shows the welcome sheet on every visit)
    if (!auth.isLoggedIn) return const AuthPage();

    final user = auth.user!;

    if (user.userType == null) return const UserTypeSelection();

    if (!user.profileComplete) {
      return user.userType == UserType.restaurant
          ? const RestaurantProfileSetup()
          : const ShelterProfileSetup();
    }

    return user.userType == UserType.restaurant
        ? const RestaurantDashboard()
        : const ShelterDashboard();
  }
}
