import 'dart:convert';
import 'api_client.dart';
import '../models/request_model.dart';

class RequestService {
  static Future<DonationRequest> createRequest({
    required String donationId,
    String? message,
  }) async {
    final res = await ApiClient.post('/requests', body: {
      'donation_id': donationId,
      if (message != null) 'message': message,
    });
    if (res.statusCode != 201) throw Exception(ApiClient.errorMessage(res));
    return DonationRequest.fromJson(jsonDecode(res.body));
  }

  static Future<List<DonationRequest>> myRequests() async {
    final res = await ApiClient.get('/requests/mine');
    if (res.statusCode != 200) throw Exception(ApiClient.errorMessage(res));
    return (jsonDecode(res.body) as List).map((j) => DonationRequest.fromJson(j)).toList();
  }

  static Future<List<DonationRequest>> receivedRequests() async {
    final res = await ApiClient.get('/requests/received');
    if (res.statusCode != 200) throw Exception(ApiClient.errorMessage(res));
    return (jsonDecode(res.body) as List).map((j) => DonationRequest.fromJson(j)).toList();
  }

  static Future<DonationRequest> approveRequest(String id) async {
    final res = await ApiClient.patch('/requests/$id/approve');
    if (res.statusCode != 200) throw Exception(ApiClient.errorMessage(res));
    return DonationRequest.fromJson(jsonDecode(res.body));
  }

  static Future<DonationRequest> declineRequest(String id) async {
    final res = await ApiClient.patch('/requests/$id/decline');
    if (res.statusCode != 200) throw Exception(ApiClient.errorMessage(res));
    return DonationRequest.fromJson(jsonDecode(res.body));
  }

  static Future<void> cancelRequest(String id) async {
    final res = await ApiClient.delete('/requests/$id');
    if (res.statusCode != 204) throw Exception(ApiClient.errorMessage(res));
  }
}
