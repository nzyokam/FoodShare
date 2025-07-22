import 'package:cloud_firestore/cloud_firestore.dart';

class Restaurant {
  final String uid;
  final String businessName;
  final String businessLicense;
  final String address;
  final String city;
  final String phone;
  final String description;
  final List<String> cuisineTypes;
  final Map<String, String> operatingHours;
  final bool isVerified;
  final GeoPoint? coordinates;
  final Timestamp createdAt;

  Restaurant({
    required this.uid,
    required this.businessName,
    required this.businessLicense,
    required this.address,
    required this.city,
    required this.phone,
    required this.description,
    this.cuisineTypes = const [],
    this.operatingHours = const {},
    this.isVerified = false,
    this.coordinates,
    required this.createdAt,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      uid: json['uid'] ?? '',
      businessName: json['businessName'] ?? '',
      businessLicense: json['businessLicense'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      phone: json['phone'] ?? '',
      description: json['description'] ?? '',
      cuisineTypes: List<String>.from(json['cuisineTypes'] ?? []),
      operatingHours: Map<String, String>.from(json['operatingHours'] ?? {}),
      isVerified: json['isVerified'] ?? false,
      coordinates: json['coordinates'],
      createdAt: json['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'businessName': businessName,
      'businessLicense': businessLicense,
      'address': address,
      'city': city,
      'phone': phone,
      'description': description,
      'cuisineTypes': cuisineTypes,
      'operatingHours': operatingHours,
      'isVerified': isVerified,
      'coordinates': coordinates,
      'createdAt': createdAt,
    };
  }
}