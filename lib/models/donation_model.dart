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
  final String id;
  final String donorId;
  final String title;
  final String? description;
  final DonationCategory? category;
  final int? quantity;
  final String? unit;
  final DateTime? expiryDate;
  final DateTime? pickupTime;
  final List<String> imageUrls;
  final DonationStatus status;
  final String? city;
  final double? latitude;
  final double? longitude;
  final String? reservedBy;
  final DateTime? reservedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Donation({
    required this.id,
    required this.donorId,
    required this.title,
    this.description,
    this.category,
    this.quantity,
    this.unit,
    this.expiryDate,
    this.pickupTime,
    this.imageUrls = const [],
    this.status = DonationStatus.available,
    this.city,
    this.latitude,
    this.longitude,
    this.reservedBy,
    this.reservedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Donation.fromJson(Map<String, dynamic> json) {
    return Donation(
      id: json['id'] ?? '',
      donorId: json['donor_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      category: _categoryFromString(json['category']),
      quantity: json['quantity'],
      unit: json['unit'],
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'])
          : null,
      pickupTime: json['pickup_time'] != null
          ? DateTime.parse(json['pickup_time'])
          : null,
      imageUrls: List<String>.from(json['image_urls'] ?? []),
      status: _statusFromString(json['status']),
      city: json['city'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      reservedBy: json['reserved_by'],
      reservedAt: json['reserved_at'] != null
          ? DateTime.parse(json['reserved_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  static DonationCategory? _categoryFromString(String? s) {
    if (s == null) return null;
    return DonationCategory.values.firstWhere(
      (c) => c.name == s,
      orElse: () => DonationCategory.other,
    );
  }

  static DonationStatus _statusFromString(String? s) {
    return DonationStatus.values.firstWhere(
      (st) => st.name == s,
      orElse: () => DonationStatus.available,
    );
  }
}
