import 'package:flutter/material.dart';

class DescriptionBox extends StatelessWidget {
  const DescriptionBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(25.0),
      // decoration: BoxDecoration(
      //   color: Theme.of(context).colorScheme.tertiary,
      //   borderRadius: BorderRadius.circular(8.0),
      // ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome to FoodShare',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.0),
          Text(
            'We are committed to reducing food waste and helping those in need. Join us in our mission to create a hunger-free world.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(175),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}