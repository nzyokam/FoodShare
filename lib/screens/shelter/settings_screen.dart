import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../themes/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/app_snackbar.dart';

class SettingsScreen extends StatelessWidget {
  final Function(int)? onDrawerItemSelected;
  const SettingsScreen({super.key, required this.onDrawerItemSelected});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Image.asset(
            'lib/assets/transparent.png',
            width: 42,
            height: 42,
          ),
        ),
        title: Text(
          'Settings',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _sectionHeader('App Settings', context),
          _card([
            _tile(
              'Dark Mode',
              'Switch between light and dark themes',
              Icons.dark_mode,
              trailing: Switch(
                value: context.watch<ThemeProvider>().isCurrentlyDark(
                  MediaQuery.platformBrightnessOf(context),
                ),
                onChanged: (val) => context.read<ThemeProvider>().setThemeMode(
                  val ? ThemeMode.dark : ThemeMode.system,
                ),
              ),
            ),
            _tile(
              'Notifications',
              'Manage notification preferences',
              Icons.notifications,
              onTap: () =>
                  _snack(context, 'Notifications settings coming soon!'),
            ),
            _tile(
              'Language',
              'Change app language',
              Icons.language,
              trailing: const Text('English'),
              onTap: () => _snack(context, 'Language settings coming soon!'),
            ),
          ]),
          const SizedBox(height: 24),
          _sectionHeader('Account', context),
          _card([
            _tile(
              'Privacy Policy',
              'Read our privacy policy',
              Icons.privacy_tip,
              onTap: () => _snack(context, 'Privacy Policy coming soon!'),
            ),
            _tile(
              'Terms of Service',
              'Read our terms of service',
              Icons.description,
              onTap: () => _snack(context, 'Terms of Service coming soon!'),
            ),
          ]),
          const SizedBox(height: 24),
          _sectionHeader('Support', context),
          _card([
            _tile(
              'Help & FAQ',
              'Get help and find answers',
              Icons.help,
              onTap: () => _snack(context, 'Help & FAQ coming soon!'),
            ),
            _tile(
              'Contact Support',
              'Get in touch with our support team',
              Icons.support,
              onTap: () => _snack(context, 'Contact Support coming soon!'),
            ),
            _tile(
              'Rate App',
              'Rate FoodShare on the app store',
              Icons.star,
              onTap: () => _snack(context, 'App Rating coming soon!'),
            ),
          ]),
          const SizedBox(height: 24),
          _sectionHeader('About', context),
          _card([
            _tile(
              'About FoodShare',
              'Learn more about our mission',
              Icons.info,
              onTap: () => _showAbout(context),
            ),
            _tile(
              'Version',
              'App version and build info',
              Icons.info_outline,
              trailing: const Text('1.0.0'),
            ),
          ]),
          const SizedBox(height: 32),
          _sectionHeader('Danger Zone', context, color: Colors.red),
          _card([
            _tile(
              'Sign Out',
              'Sign out of your account',
              Icons.logout,
              color: Colors.red,
              onTap: () => _showSignOutDialog(context),
            ),
            _tile(
              'Delete Account',
              'Permanently delete your account',
              Icons.delete_forever,
              color: Colors.red,
              onTap: () => _snack(context, 'Account deletion coming soon!'),
            ),
          ]),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AuthProvider>().signOut();
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('About FoodShare'),
        icon: const AppLogo(width: 60, height: 60),
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
              'Together, we\'re working towards UN SDG 2: Zero Hunger.',
              style: TextStyle(fontWeight: FontWeight.w600, height: 1.5),
            ),
            SizedBox(height: 16),
            Text('Version 1.0.0', style: TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _snack(BuildContext context, String msg) => AppSnackBar.showInfo(context, msg);

  Widget _sectionHeader(String title, BuildContext context, {Color? color}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color ?? Theme.of(context).colorScheme.onSurface,
          ),
        ),
      );

  Widget _card(List<Widget> children) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white.withAlpha(10),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.withAlpha(50)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );

  Widget _tile(
    String title,
    String subtitle,
    IconData icon, {
    Widget? trailing,
    VoidCallback? onTap,
    Color? color,
  }) => ListTile(
    leading: Icon(icon, color: color),
    title: Text(
      title,
      style: TextStyle(fontWeight: FontWeight.w600, color: color),
    ),
    subtitle: Text(subtitle),
    trailing:
        trailing ??
        (onTap != null
            ? const Icon(Icons.chevron_right_rounded, size: 20)
            : null),
    onTap: onTap,
  );
}
