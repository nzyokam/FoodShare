// screens/shared/settings_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../themes/theme_provider.dart';
import '../../services/auth_service.dart';

import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  final Function(int)? onDrawerItemSelected;
  const SettingsScreen({super.key, required this.onDrawerItemSelected});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

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
        title: Text(
          'Settings',
          style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // App Settings Section
          _buildSectionHeader('App Settings', context),

          _buildSettingsCard([
            _buildSettingsTile(
              'Dark Mode',
              'Switch between light and dark themes',
              Icons.dark_mode,
              trailing: CupertinoSwitch(
                value: context.watch<ThemeProvider>().isDarkMode,
                onChanged: (value) {
                  context.read<ThemeProvider>().toggleTheme();
                },
              ),
            ),

            _buildSettingsTile(
              'Notifications',
              'Manage notification preferences',
              Icons.notifications,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notifications settings coming soon!'),
                  ),
                );
              },
            ),

            _buildSettingsTile(
              'Language',
              'Change app language',
              Icons.language,
              trailing: const Text('English'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Language settings coming soon!'),
                  ),
                );
              },
            ),
          ]),

          const SizedBox(height: 24),

          // Account Section
          _buildSectionHeader('Account', context),

          _buildSettingsCard([
            _buildSettingsTile(
              'Privacy Policy',
              'Read our privacy policy',
              Icons.privacy_tip,
              onTap: () {
                _showComingSoon(context, 'Privacy Policy');
              },
            ),

            _buildSettingsTile(
              'Terms of Service',
              'Read our terms of service',
              Icons.description,
              onTap: () {
                _showComingSoon(context, 'Terms of Service');
              },
            ),
          ]),

          const SizedBox(height: 24),

          // Support Section
          _buildSectionHeader('Support', context),

          _buildSettingsCard([
            _buildSettingsTile(
              'Help & FAQ',
              'Get help and find answers',
              Icons.help,
              onTap: () {
                _showComingSoon(context, 'Help & FAQ');
              },
            ),

            _buildSettingsTile(
              'Contact Support',
              'Get in touch with our support team',
              Icons.support,
              onTap: () {
                _showComingSoon(context, 'Contact Support');
              },
            ),

            _buildSettingsTile(
              'Rate App',
              'Rate FoodShare on the app store',
              Icons.star,
              onTap: () {
                _showComingSoon(context, 'App Rating');
              },
            ),
          ]),

          const SizedBox(height: 24),

          // About Section
          _buildSectionHeader('About', context),

          _buildSettingsCard([
            _buildSettingsTile(
              'About FoodShare',
              'Learn more about our mission',
              Icons.info,
              onTap: () {
                _showAboutDialog(context);
              },
            ),

            _buildSettingsTile(
              'Version',
              'App version and build info',
              Icons.info_outline,
              trailing: const Text('1.0.0'),
            ),
          ]),

          const SizedBox(height: 32),

          // Danger Zone
          _buildSectionHeader('Danger Zone', color: Colors.red, context),

          _buildSettingsCard([
            _buildSettingsTile(
              'Sign Out',
              'Sign out of your account',
              Icons.logout,
              color: Colors.red,
              onTap: () {
                _showSignOutDialog(context, authService);
              },
            ),

            _buildSettingsTile(
              'Delete Account',
              'Permanently delete your account',
              Icons.delete_forever,
              color: Colors.red,
              onTap: () {
                _showDeleteAccountDialog(context, authService);
              },
            ),
          ]),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    BuildContext context, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: color ?? Theme.of(context).colorScheme.inversePrimary,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withAlpha(50)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile(
    String title,
    String subtitle,
    IconData icon, {
    Widget? trailing,
    VoidCallback? onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w600, color: color),
      ),
      subtitle: Text(subtitle),
      trailing:
          trailing ??
          (onTap != null
              ? const Icon(Icons.arrow_forward_ios, size: 16)
              : null),
      onTap: onTap,
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature coming soon!')));
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About FoodShare'),
        icon: Image.asset(
          'lib/assets/2.png',
          width: 60,
          height: 60,
          fit: BoxFit.contain,
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FoodShare is an initiative developed by Muusi Nguutu Nzyoka. It is dedicated to fighting hunger and reducing food waste by connecting restaurants with local shelters and communities in need.',
              style: TextStyle(height: 1.5),
            ),
            SizedBox(height: 16),
            Text(
              'Together, we\'re working towards UN Sustainable Development Goal 2: Zero Hunger.',
              style: TextStyle(fontWeight: FontWeight.w600, height: 1.5),
            ),
            SizedBox(height: 16),
            Text('Version 1.0.0', style: TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Close the dialog first
                Navigator.pop(context);

                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) =>
                      const Center(child: CircularProgressIndicator()),
                );

                // Perform sign out
                await authService.signOut();

                // Close loading dialog if still mounted
                if (context.mounted) {
                  Navigator.pop(context);
                }
              } catch (e) {
                // Close loading dialog if it's open
                if (context.mounted) {
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Sign-Out Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to permanently delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Close the dialog first
                Navigator.pop(context);

                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const AlertDialog(
                    content: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 16),
                        Text('Deleting account...'),
                      ],
                    ),
                  ),
                );

                // Perform account deletion
                await authService.deleteAccount();

                // Close loading dialog if still mounted
                if (context.mounted) {
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Account deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                // Close loading dialog if it's open
                if (context.mounted) {
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting account: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }
}
