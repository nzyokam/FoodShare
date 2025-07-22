// screens/shared/settings_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../themes/theme_provider.dart';
import '../../services/auth_service.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // App Settings Section
          _buildSectionHeader('App Settings'),
          
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
                  const SnackBar(content: Text('Notifications settings coming soon!')),
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
                  const SnackBar(content: Text('Language settings coming soon!')),
                );
              },
            ),
          ]),
          
          const SizedBox(height: 24),
          
          // Account Section
          _buildSectionHeader('Account'),
          
          _buildSettingsCard([
            _buildSettingsTile(
              'Edit Profile',
              'Update your profile information',
              Icons.person,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit profile coming soon!')),
                );
              },
            ),
            
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
          _buildSectionHeader('Support'),
          
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
          _buildSectionHeader('About'),
          
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
          _buildSectionHeader('Danger Zone', color: Colors.red),
          
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

  Widget _buildSectionHeader(String title, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withAlpha(50),
        ),
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
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: trailing ?? (onTap != null ? const Icon(Icons.arrow_forward_ios, size: 16) : null),
      onTap: onTap,
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature coming soon!')),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About FoodShare'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FoodShare is dedicated to fighting hunger and reducing food waste by connecting restaurants with local shelters and communities in need.',
              style: TextStyle(height: 1.5),
            ),
            SizedBox(height: 16),
            Text(
              'Together, we\'re working towards UN Sustainable Development Goal 2: Zero Hunger.',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Version 1.0.0',
              style: TextStyle(fontSize: 12),
            ),
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
              Navigator.pop(context);
              await authService.signOut();
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
              Navigator.pop(context);
              try {
                await authService.deleteAccount();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Account deleted successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting account: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
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