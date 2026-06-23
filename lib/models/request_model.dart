enum RequestStatus { pending, approved, declined, completed }

class DonationRequest {
  final String id;
  final String shelterId;
  final String donationId;
  final String? message;
  final RequestStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  const DonationRequest({
    required this.id,
    required this.shelterId,
    required this.donationId,
    this.message,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  factory DonationRequest.fromJson(Map<String, dynamic> json) {
    return DonationRequest(
      id: json['id'] ?? '',
      shelterId: json['shelter_id'] ?? '',
      donationId: json['donation_id'] ?? '',
      message: json['message'],
      status: _statusFromString(json['status']),
      createdAt: DateTime.parse(json['created_at']),
      respondedAt: json['responded_at'] != null
          ? DateTime.parse(json['responded_at'])
          : null,
    );
  }

  static RequestStatus _statusFromString(String? s) {
    return RequestStatus.values.firstWhere(
      (st) => st.name == s,
      orElse: () => RequestStatus.pending,
    );
  }
}
