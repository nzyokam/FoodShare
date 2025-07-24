import 'package:flutter/material.dart';
import 'package:foodshare/models/user_model.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'profile_setup/restaurant_profile_setup.dart';
import 'profile_setup/shelter_profile_setup.dart';

class UserTypeSelection extends StatefulWidget {
  const UserTypeSelection({super.key});

  @override
  State<UserTypeSelection> createState() => _UserTypeSelectionState();
}

class _UserTypeSelectionState extends State<UserTypeSelection> {
  final AuthService _authService = AuthService();
  UserType? _selectedType;
  bool _isLoading = false;

  Future<void> _continueWithSelectedType() async {
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an account type')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.setUserType(_selectedType!);

      if (mounted) {
        // Navigate to appropriate profile setup
        Widget nextScreen = _selectedType == UserType.restaurant
            ? const RestaurantProfileSetup()
            : const ShelterProfileSetup();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => nextScreen),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 40),

                    // App logo and title
                    Image.asset(
                      'lib/assets/2.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 10),

                    Text(
                      'FoodShare',
                      style: GoogleFonts.bebasNeue(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      'Fighting hunger together 🤝',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(180),
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 50),

                    Text(
                      'What describes you best?',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 30),

                    // Restaurant option
                    _buildTypeCard(
                      type: UserType.restaurant,
                      title: 'Restaurant / Food Business',
                      subtitle: 'I have surplus food to donate',
                      icon: Icons.restaurant,
                      features: [
                        '• Share surplus food',
                        '• Connect with local shelters',
                        '• Track your impact',
                        '• Build community relationships',
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Shelter option
                    _buildTypeCard(
                      type: UserType.shelter,
                      title: 'Shelter / NGO / Community',
                      subtitle: 'I need food donations for people in need',
                      icon: Icons.home,
                      features: [
                        '• Access fresh food donations',
                        '• Connect with local restaurants',
                        '• Serve more people in need',
                        '• Build sustainable partnerships',
                      ],
                    ),

                    const Expanded(child: SizedBox(height: 20)),

                    // Continue button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : _continueWithSelectedType,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Continue',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeCard({
    required UserType type,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<String> features,
  }) {
    final isSelected = _selectedType == type;

    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2E7D32).withAlpha(30)
              : Theme.of(context).colorScheme.primary.withAlpha(20),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF2E7D32) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 30,
                  color: isSelected
                      ? const Color(0xFF2E7D32)
                      : Theme.of(context).colorScheme.onSurface,
                ),
                const SizedBox(width: 12),
                Expanded(
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
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha(180),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF2E7D32),
                    size: 24,
                  ),
              ],
            ),

            const SizedBox(height: 12),

            ...features.map(
              (feature) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  feature,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(160),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
