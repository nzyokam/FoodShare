import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_notifier.dart';
import '../models/user_model.dart';
import 'auth_page.dart';
import 'user_type_selection.dart';
import 'profile_setup/restaurant_profile_setup.dart';
import 'profile_setup/shelter_profile_setup.dart';
import '../screens/restaurant/restaurant_dashboard.dart';
import '../screens/shared/shelter_dashboard.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authNotifierProvider);

    return authAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const AuthPage(),
      data: (state) {
        if (!state.isLoggedIn) return const AuthPage();

        final user = state.user!;
        if (user.userType == null) return const UserTypeSelection();
        if (!user.profileComplete) {
          return user.userType == UserType.restaurant
              ? const RestaurantProfileSetup()
              : const ShelterProfileSetup();
        }

        return user.userType == UserType.restaurant
            ? const RestaurantDashboard()
            : const ShelterDashboard();
      },
    );
  }
}
