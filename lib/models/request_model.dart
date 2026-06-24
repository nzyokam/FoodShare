enum RequestStatus { pending, approved, declined, completed }

class DonationRequest {
  final String id;
  final String shelterId;
  final String donationId;
  final String? message;
  final RequestStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  // Enriched fields from backend JOIN (null when using plain RequestOut)
  final String? donationTitle;
  final List<String> donationImageUrls;
  final int? donationQuantity;
  final String? donationUnit;
  final DateTime? donationExpiryDate;
  final String? donationStatus;
  final String? otherPartyName;

  const DonationRequest({
    required this.id,
    required this.shelterId,
    required this.donationId,
    this.message,
    required this.status,
    required this.createdAt,
    this.respondedAt,
    this.donationTitle,
    this.donationImageUrls = const [],
    this.donationQuantity,
    this.donationUnit,
    this.donationExpiryDate,
    this.donationStatus,
    this.otherPartyName,
  });

  factory DonationRequest.fromJson(Map<String, dynamic> json) {
    final donationJson = json['donation'] as Map<String, dynamic>?;
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
      donationTitle: donationJson?['title'] as String?,
      donationImageUrls: donationJson != null
          ? List<String>.from(donationJson['image_urls'] ?? [])
          : const [],
      donationQuantity: donationJson?['quantity'] as int?,
      donationUnit: donationJson?['unit'] as String?,
      donationExpiryDate: donationJson?['expiry_date'] != null
          ? DateTime.parse(donationJson!['expiry_date'])
          : null,
      donationStatus: donationJson?['status'] as String?,
      otherPartyName: json['other_party_name'] as String?,
    );
  }

  static RequestStatus _statusFromString(String? s) {
    return RequestStatus.values.firstWhere(
      (st) => st.name == s,
      orElse: () => RequestStatus.pending,
    );
  }
}
