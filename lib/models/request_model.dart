import 'package:cloud_firestore/cloud_firestore.dart';

enum RequestStatus { pending, approved, declined }

class DonationRequest {
  final String? id;
  final String shelterId;
  final String donationId;
  final String message;
  final RequestStatus status;
  final Timestamp createdAt;
  final Timestamp? respondedAt;

  DonationRequest({
    this.id,
    required this.shelterId,
    required this.donationId,
    required this.message,
    this.status = RequestStatus.pending,
    required this.createdAt,
    this.respondedAt,
  });

  factory DonationRequest.fromJson(Map<String, dynamic> json, {String? docId}) {
    return DonationRequest(
      id: docId ?? json['id'],
      shelterId: json['shelterId'] ?? '',
      donationId: json['donationId'] ?? '',
      message: json['message'] ?? '',
      status: _statusFromString(json['status']),
      createdAt: json['createdAt'] ?? Timestamp.now(),
      respondedAt: json['respondedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shelterId': shelterId,
      'donationId': donationId,
      'message': message,
      'status': status.toString().split('.').last,
      'createdAt': createdAt,
      'respondedAt': respondedAt,
    };
  }

  static RequestStatus _statusFromString(String? statusString) {
    return RequestStatus.values.firstWhere(
      (s) => s.toString().split('.').last == statusString,
      orElse: () => RequestStatus.pending,
    );
  }
}