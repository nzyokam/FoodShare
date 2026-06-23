class Restaurant {
  final String id;
  final String? businessName;
  final String? businessLicense;
  final String? address;
  final String? city;
  final String? phone;
  final String? description;
  final List<String> cuisineTypes;
  final bool isVerified;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;

  const Restaurant({
    required this.id,
    this.businessName,
    this.businessLicense,
    this.address,
    this.city,
    this.phone,
    this.description,
    this.cuisineTypes = const [],
    this.isVerified = false,
    this.latitude,
    this.longitude,
    required this.createdAt,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'] ?? '',
      businessName: json['business_name'],
      businessLicense: json['business_license'],
      address: json['address'],
      city: json['city'],
      phone: json['phone'],
      description: json['description'],
      cuisineTypes: List<String>.from(json['cuisine_types'] ?? []),
      isVerified: json['is_verified'] ?? false,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
