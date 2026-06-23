enum UserType { restaurant, shelter }

class AppUser {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final UserType? userType;
  final bool profileComplete;

  const AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.userType,
    required this.profileComplete,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final typeStr = json['user_type'] as String?;
    return AppUser(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      displayName: json['display_name'],
      photoUrl: json['photo_url'],
      userType: typeStr == 'restaurant'
          ? UserType.restaurant
          : typeStr == 'shelter'
              ? UserType.shelter
              : null,
      profileComplete: json['profile_complete'] ?? false,
    );
  }
}
