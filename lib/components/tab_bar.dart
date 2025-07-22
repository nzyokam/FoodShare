import 'package:flutter/material.dart';
import '../models/food.dart'; // Make sure this imports your enum FoodCategory

class MyTabBar extends StatelessWidget {
  final TabController tabController;

  const MyTabBar({super.key, required this.tabController});

  @override
Widget build(BuildContext context) {
  return MediaQuery.removePadding(
    context: context,
    removeLeft: true,
    child: TabBar(
      isScrollable: true,
      controller: tabController,
      labelColor: Theme.of(context).colorScheme.surface,
      unselectedLabelColor:
          Theme.of(context).colorScheme.onSurface.withAlpha(150),
      tabs: FoodCategory.values.map((category) {
        return Tab(text: _getCategoryName(category));
      }).toList(),
    ),
  );
}


  String _getCategoryName(FoodCategory category) {
    // This function returns the name of the category based on the FoodCategory enum
    switch (category) {
      case FoodCategory.fruits:
        return 'Fruits';
      case FoodCategory.vegetables:
        return 'Vegetables';
      case FoodCategory.dairy:
        return 'Dairy';
      case FoodCategory.meat:
        return 'Meat';
      case FoodCategory.grains:
        return 'Grains';
      case FoodCategory.snacks:
        return 'Snacks';
      case FoodCategory.beverages:
        return 'Beverages';
      case FoodCategory.cookedFood:
        return 'Cooked';
      case FoodCategory.others:
        return 'Others';
    }
  }
}
