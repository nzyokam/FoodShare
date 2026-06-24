import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_client.dart';
import '../../providers/auth_notifier.dart';
import '../../providers/theme_notifier.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/app_snackbar.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  final Function(int)? onDrawerItemSelected;
  const SettingsScreen({super.key, required this.onDrawerItemSelected});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _loadingPrefs = true;
  bool _chatMessages = true;
  bool _requestUpdates = true;
  bool _newDonations = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    try {
      final res = await ApiClient.get('/auth/notification-prefs');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _chatMessages = data['chat_messages'] ?? true;
            _requestUpdates = data['request_updates'] ?? true;
            _newDonations = data['new_donations'] ?? true;
            _loadingPrefs = false;
          });
        }
      } else {
        if (mounted) setState(() => _loadingPrefs = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingPrefs = false);
    }
  }

  Future<void> _updatePref(String key, bool value) async {
    try {
      final res = await ApiClient.patch('/auth/notification-prefs', body: {key: value});
      if (res.statusCode != 200 && mounted) {
        AppSnackBar.showError(context, 'Failed to save preference');
        // Revert
        await _loadPrefs();
      }
    } catch (_) {
      if (mounted) {
        AppSnackBar.showError(context, 'Failed to save preference');
        await _loadPrefs();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Image.asset('lib/assets/transparent.png', width: 42, height: 42),
        ),
        title: Text('Settings', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
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
                value: ref.watch(themeNotifierProvider.notifier).isCurrentlyDark(
                  MediaQuery.platformBrightnessOf(context),
                ),
                onChanged: (val) => ref.read(themeNotifierProvider.notifier).setThemeMode(
                  val ? ThemeMode.dark : ThemeMode.system,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 24),
          _sectionHeader('Notifications', context),
          _card([
            if (_loadingPrefs)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              _tile(
                'Chat Messages',
                'New messages from restaurants or shelters',
                Icons.chat_bubble_outline_rounded,
                trailing: Switch(
                  value: _chatMessages,
                  onChanged: (val) {
                    setState(() => _chatMessages = val);
                    _updatePref('chat_messages', val);
                  },
                ),
              ),
              _tile(
                'Request Updates',
                'When your request is approved or declined',
                Icons.assignment_turned_in_outlined,
                trailing: Switch(
                  value: _requestUpdates,
                  onChanged: (val) {
                    setState(() => _requestUpdates = val);
                    _updatePref('request_updates', val);
                  },
                ),
              ),
              _tile(
                'New Donations',
                'When restaurants post new available donations',
                Icons.volunteer_activism_outlined,
                trailing: Switch(
                  value: _newDonations,
                  onChanged: (val) {
                    setState(() => _newDonations = val);
                    _updatePref('new_donations', val);
                  },
                ),
              ),
            ],
          ]),
          const SizedBox(height: 24),
          _sectionHeader('Account', context),
          _card([
            _tile('Privacy Policy', 'Read our privacy policy', Icons.privacy_tip,
                onTap: () => AppSnackBar.showInfo(context, 'Privacy Policy coming soon!')),
            _tile('Terms of Service', 'Read our terms of service', Icons.description,
                onTap: () => AppSnackBar.showInfo(context, 'Terms of Service coming soon!')),
          ]),
          const SizedBox(height: 24),
          _sectionHeader('Support', context),
          _card([
            _tile('Help & FAQ', 'Get help and find answers', Icons.help,
                onTap: () => AppSnackBar.showInfo(context, 'Help & FAQ coming soon!')),
            _tile('Contact Support', 'Get in touch with our support team', Icons.support,
                onTap: () => AppSnackBar.showInfo(context, 'Contact Support coming soon!')),
            _tile('Rate App', 'Rate FoodShare on the app store', Icons.star,
                onTap: () => AppSnackBar.showInfo(context, 'App Rating coming soon!')),
          ]),
          const SizedBox(height: 24),
          _sectionHeader('About', context),
          _card([
            _tile('About FoodShare', 'Learn more about our mission', Icons.info,
                onTap: () => _showAbout(context)),
            _tile('Version', 'App version and build info', Icons.info_outline,
                trailing: const Text('1.0.0')),
          ]),
          const SizedBox(height: 32),
          _sectionHeader('Danger Zone', context, color: Colors.red),
          _card([
            _tile('Sign Out', 'Sign out of your account', Icons.logout,
                color: Colors.red, onTap: () => _showSignOutDialog(context)),
            _tile('Delete Account', 'Permanently delete your account', Icons.delete_forever,
                color: Colors.red,
                onTap: () => AppSnackBar.showInfo(context, 'Account deletion coming soon!')),
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authNotifierProvider.notifier).signOut();
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

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
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
  );

  Widget _tile(
    String title,
    String subtitle,
    IconData icon, {
    Widget? trailing,
    VoidCallback? onTap,
    Color? color,
  }) =>
      ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
        subtitle: Text(subtitle),
        trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right_rounded, size: 20) : null),
        onTap: onTap,
      );
}
