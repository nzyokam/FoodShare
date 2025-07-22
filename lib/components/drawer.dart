import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:foodsharing/components/my_drawer_tile.dart';

class MyDrawer extends StatelessWidget {
  final Function(int) onItemSelected;

  const MyDrawer({super.key, required this.onItemSelected});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          const SizedBox(height: 100),
          Icon(
            Icons.restaurant_menu,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Divider(
              color: Theme.of(context).colorScheme.inversePrimary,
              thickness: 1,
            ),
          ),
          MyDrawerTile(
            text: 'H O M E',
            icon: Icons.home,
            onTap: () {
              Navigator.pop(context);
              onItemSelected(0);
            },
          ),
          MyDrawerTile(
            text: 'P R O F I L E',
            icon: Icons.person,
            onTap: () {
              Navigator.pop(context);
              onItemSelected(1); // You’ll handle this in your parent screen
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
