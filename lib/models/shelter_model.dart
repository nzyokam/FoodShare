import 'package:cloud_firestore/cloud_firestore.dart';

class Shelter {
  final String uid;
  final String organizationName;
  final String registrationNumber;
  final String address;
  final String city;
  final String phone;
  final int capacity;
  final String targetDemographic;
  final String description;
  final GeoPoint? coordinates;
  final bool isVerified;
  final Timestamp createdAt;

  Shelter({
    required this.uid,
    required this.organizationName,
    required this.registrationNumber,
    required this.address,
    required this.city,
    required this.phone,
    required this.capacity,
    required this.targetDemographic,
    required this.description,
    this.coordinates,
    this.isVerified = false,
    required this.createdAt,
  });

  factory Shelter.fromJson(Map<String, dynamic> json) {
    return Shelter(
      uid: json['uid'] ?? '',
      organizationName: json['organizationName'] ?? '',
      registrationNumber: json['registrationNumber'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      phone: json['phone'] ?? '',
      capacity: json['capacity'] ?? 0,
      targetDemographic: json['targetDemographic'] ?? '',
      description: json['description'] ?? '',
      coordinates: json['coordinates'],
      isVerified: json['isVerified'] ?? false,
      createdAt: json['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'organizationName': organizationName,
      'registrationNumber': registrationNumber,
      'address': address,
      'city': city,
      'phone': phone,
      'capacity': capacity,
      'targetDemographic': targetDemographic,
      'description': description,
      'coordinates': coordinates,
      'isVerified': isVerified,
      'createdAt': createdAt,
    };
  }
}
