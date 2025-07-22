import 'package:cloud_firestore/cloud_firestore.dart';

enum UserType { restaurant, shelter }

class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;
  final UserType? userType;
  final bool profileComplete;
  final Timestamp createdAt;
  final Timestamp? updatedAt;

  AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
    this.userType,
    this.profileComplete = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    UserType? userType;
    if (json['userType'] != null) {
      userType = json['userType'] == 'restaurant' 
          ? UserType.restaurant 
          : UserType.shelter;
    }

    return AppUser(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'] ?? '',
      photoURL: json['photoURL'],
      userType: userType,
      profileComplete: json['profileComplete'] ?? false,
      createdAt: json['createdAt'] ?? Timestamp.now(),
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'userType': userType?.toString().split('.').last,
      'profileComplete': profileComplete,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}