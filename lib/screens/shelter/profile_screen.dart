import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_notifier.dart';
import '../../services/profile_service.dart';

import '../../models/restaurant_model.dart';
import '../../models/shelter_model.dart';
import '../../models/user_model.dart';
import '../shared/edit_profile_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final UserType userType;
  final Function(int)? onDrawerItemSelected;
  const ProfileScreen({super.key, required this.userType, required this.onDrawerItemSelected});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Restaurant? _restaurant;
  Shelter? _shelter;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = ref.read(authNotifierProvider).asData?.value.user?.id;
    if (userId == null) return;
    try {
      if (widget.userType == UserType.restaurant) {
        final r = await ProfileService.getRestaurant(userId);
        if (mounted) setState(() => _restaurant = r);
      } else {
        final s = await ProfileService.getShelter(userId);
        if (mounted) setState(() => _shelter = s);
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _editProfile() async {
    final result = await Navigator.push(context, MaterialPageRoute(
        builder: (_) => EditProfileScreen(userType: widget.userType, restaurant: _restaurant, shelter: _shelter)));
    if (result == true) _loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final user = ref.watch(authNotifierProvider).asData?.value.user;
    final photoUrl = user?.photoUrl;
    final displayName = user?.displayName ??
        (widget.userType == UserType.restaurant ? _restaurant?.businessName : _shelter?.organizationName) ?? 'User';

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(padding: const EdgeInsets.only(left: 15), child: Image.asset('lib/assets/transparent.png', width: 150, height: 150)),
        title: const Text('Profile'),
        actions: [IconButton(onPressed: _editProfile, icon: const Icon(Icons.edit))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 30),
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(30, 80, 30, 30),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface.withAlpha(230),
                          border: Border.all(color: Colors.grey.withAlpha(100), width: 1.5),
                        ),
                        child: Column(
                          children: [
                            Text(
                              widget.userType == UserType.restaurant ? (_restaurant?.businessName ?? 'Restaurant') : (_shelter?.organizationName ?? 'Organization'),
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 24, fontWeight: FontWeight.w700),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(color: const Color(0xFF2E7D32).withAlpha(51), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF2E7D32).withAlpha(100))),
                              child: Text(
                                widget.userType == UserType.restaurant ? 'Restaurant Account' : 'Shelter Account',
                                style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(user?.email ?? '', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha(180), fontSize: 14), textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  child: _avatar(photoUrl, displayName),
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (widget.userType == UserType.restaurant && _restaurant != null) _restaurantDetails(_restaurant!),
            if (widget.userType == UserType.shelter && _shelter != null) _shelterDetails(_shelter!),
            const SizedBox(height: 32),
            _actionBtn('Edit Profile', Icons.edit, Theme.of(context).colorScheme.primary, _editProfile),
            const SizedBox(height: 16),
            _actionBtn('Sign Out', Icons.logout, Colors.red, () async {
              await ref.read(authNotifierProvider.notifier).signOut();
            }),
          ],
        ),
      ),
    );
  }

  Widget _avatar(String? photoUrl, String displayName) {
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 60,
        backgroundColor: const Color.fromARGB(255, 16, 47, 18),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: photoUrl,
            width: 116, height: 116, fit: BoxFit.cover,
            placeholder: (_, __) => const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
            errorWidget: (_, __, ___) => _initials(displayName),
          ),
        ),
      );
    }
    return _initials(displayName);
  }

  Widget _initials(String name) {
    String initials = 'U';
    if (name.isNotEmpty) {
      final parts = name.split(' ');
      initials = parts.length >= 2 ? '${parts[0][0]}${parts[1][0]}'.toUpperCase() : name.substring(0, name.length.clamp(1, 2)).toUpperCase();
    }
    return CircleAvatar(
      radius: 60,
      backgroundColor: const Color.fromARGB(255, 16, 47, 18),
      child: Text(initials, style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  Widget _restaurantDetails(Restaurant r) => Column(children: [
    _detailCard('Business Information', [
      _detailItem('License', r.businessLicense ?? ''),
      _detailItem('Address', r.address ?? ''),
      _detailItem('City', r.city ?? ''),
      _detailItem('Phone', r.phone ?? ''),
    ]),
    const SizedBox(height: 16),
    if (r.cuisineTypes.isNotEmpty) _detailCard('Cuisine Types', [Wrap(spacing: 8, runSpacing: 8,
      children: r.cuisineTypes.map((c) => Chip(label: Text(c), backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(20))).toList())]),
    const SizedBox(height: 16),
    _detailCard('Description', [Text(r.description ?? '', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, height: 1.5))]),
  ]);

  Widget _shelterDetails(Shelter s) => Column(children: [
    _detailCard('Organization Information', [
      _detailItem('Registration', s.registrationNumber ?? ''),
      _detailItem('Address', s.address ?? ''),
      _detailItem('City', s.city ?? ''),
      _detailItem('Phone', s.phone ?? ''),
      _detailItem('Capacity', '${s.capacity ?? 0} people'),
      _detailItem('Demographic', s.targetDemographic ?? ''),
    ]),
    const SizedBox(height: 16),
    _detailCard('Description', [Text(s.description ?? '', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, height: 1.5))]),
  ]);

  Widget _detailCard(String title, List<Widget> children) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withAlpha(10), borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).colorScheme.primary.withAlpha(50))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
      const SizedBox(height: 16),
      ...children,
    ]),
  );

  Widget _detailItem(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 120, child: Text('$label:', style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface.withAlpha(180)))),
      Expanded(child: Text(value, style: TextStyle(color: Theme.of(context).colorScheme.onSurface))),
    ]),
  );

  Widget _actionBtn(String title, IconData icon, Color color, VoidCallback onTap) => SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: onTap, icon: Icon(icon), label: Text(title),
      style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    ),
  );
}
