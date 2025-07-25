import 'package:cloud_firestore/cloud_firestore.dart';

class Food {
  final String name; 
  final String description; 

  final String location;
  final Timestamp availableAt;

  final String userId;
  final FoodCategory category;
  final String city;

  Food({
    required this.name,
    required this.description,
  
    required this.location,
    required this.availableAt,

    required this.userId,
    required this.category,
    required this.city,
  });

  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
   
      location: json['location'] ?? '',
      availableAt: json['availableAt'] ?? Timestamp.now(),

      userId: json['userId'] ?? '',
      city: json['city'] ?? '',
      category: FoodCategory.values.firstWhere(
        (c) => c.toString().split('.').last == json['category'],
        orElse: () => FoodCategory.others,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
     
      'location': location,
      'availableAt': availableAt,

      'userId': userId,
      'city': city,
      'category': category.name,
    };
  }
}

enum FoodCategory {
  fruits,
  vegetables,
  dairy,
  meat,
  grains,
  snacks,
  beverages,
  cookedFood,
  others,
}
