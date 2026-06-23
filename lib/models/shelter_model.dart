class Shelter {
  final String id;
  final String? organizationName;
  final String? registrationNumber;
  final String? address;
  final String? city;
  final String? phone;
  final int? capacity;
  final String? targetDemographic;
  final String? description;
  final bool isVerified;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;

  const Shelter({
    required this.id,
    this.organizationName,
    this.registrationNumber,
    this.address,
    this.city,
    this.phone,
    this.capacity,
    this.targetDemographic,
    this.description,
    this.isVerified = false,
    this.latitude,
    this.longitude,
    required this.createdAt,
  });

  factory Shelter.fromJson(Map<String, dynamic> json) {
    return Shelter(
      id: json['id'] ?? '',
      organizationName: json['organization_name'],
      registrationNumber: json['registration_number'],
      address: json['address'],
      city: json['city'],
      phone: json['phone'],
      capacity: json['capacity'],
      targetDemographic: json['target_demographic'],
      description: json['description'],
      isVerified: json['is_verified'] ?? false,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
