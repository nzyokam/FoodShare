import 'package:cloud_firestore/cloud_firestore.dart';

enum DonationStatus { available, reserved, completed, cancelled }

enum DonationCategory {
  fruits,
  vegetables,
  grains,
  dairy,
  meat,
  preparedMeals,
  snacks,
  beverages,
  other,
}

class Donation {
  final String? id;
  final String donorId;
  final String title;
  final String description;
  final DonationCategory category;
  final int quantity;
  final String unit;
  final Timestamp expiryDate;
  final Timestamp pickupTime;
  final List<String> imageUrls;
  final DonationStatus status;
  final GeoPoint? location;
  final String city;
  final Timestamp createdAt;
  final String? reservedBy;
  final Timestamp? reservedAt;

  Donation({
    this.id,
    required this.donorId,
    required this.title,
    required this.description,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.expiryDate,
    required this.pickupTime,
    this.imageUrls = const [],
    this.status = DonationStatus.available,
    this.location,
    required this.city,
    required this.createdAt,
    this.reservedBy,
    this.reservedAt,
  });

  factory Donation.fromJson(Map<String, dynamic> json, {String? docId}) {
    return Donation(
      id: docId ?? json['id'],
      donorId: json['donorId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: _categoryFromString(json['category']),
      quantity: json['quantity'] ?? 0,
      unit: json['unit'] ?? '',
      expiryDate: json['expiryDate'] ?? Timestamp.now(),
      pickupTime: json['pickupTime'] ?? Timestamp.now(),
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      status: _statusFromString(json['status']),
      location: json['location'],
      city: json['city'] ?? '',
      createdAt: json['createdAt'] ?? Timestamp.now(),
      reservedBy: json['reservedBy'],
      reservedAt: json['reservedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'donorId': donorId,
      'title': title,
      'description': description,
      'category': category.toString().split('.').last,
      'quantity': quantity,
      'unit': unit,
      'expiryDate': expiryDate,
      'pickupTime': pickupTime,
      'imageUrls': imageUrls,
      'status': status.toString().split('.').last,
      'location': location,
      'city': city,
      'createdAt': createdAt,
      'reservedBy': reservedBy,
      'reservedAt': reservedAt,
    };
  }

  static DonationCategory _categoryFromString(String? categoryString) {
    return DonationCategory.values.firstWhere(
      (c) => c.toString().split('.').last == categoryString,
      orElse: () => DonationCategory.other,
    );
  }

  static DonationStatus _statusFromString(String? statusString) {
    return DonationStatus.values.firstWhere(
      (s) => s.toString().split('.').last == statusString,
      orElse: () => DonationStatus.available,
    );
  }
}