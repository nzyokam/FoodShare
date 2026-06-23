import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'api_client.dart';
import '../models/donation_model.dart';

class DonationService {
  static Future<List<Donation>> listDonations({
    String? city,
    String? category,
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    final res = await ApiClient.get('/donations', query: {
      'city': city,
      'category': category,
      'status': status,
      'limit': limit.toString(),
      'offset': offset.toString(),
    });
    if (res.statusCode != 200) throw Exception(ApiClient.errorMessage(res));
    return (jsonDecode(res.body) as List).map((j) => Donation.fromJson(j)).toList();
  }

  static Future<List<Donation>> myDonations() async {
    final res = await ApiClient.get('/donations/mine');
    if (res.statusCode != 200) throw Exception(ApiClient.errorMessage(res));
    return (jsonDecode(res.body) as List).map((j) => Donation.fromJson(j)).toList();
  }

  static Future<Donation> getDonation(String id) async {
    final res = await ApiClient.get('/donations/$id');
    if (res.statusCode != 200) throw Exception(ApiClient.errorMessage(res));
    return Donation.fromJson(jsonDecode(res.body));
  }

  static Future<Donation> createDonation({
    required String title,
    String? description,
    String? category,
    int? quantity,
    String? unit,
    DateTime? expiryDate,
    DateTime? pickupTime,
    List<String> imageUrls = const [],
    String? city,
    double? latitude,
    double? longitude,
  }) async {
    final res = await ApiClient.post('/donations', body: {
      'title': title,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (quantity != null) 'quantity': quantity,
      if (unit != null) 'unit': unit,
      if (expiryDate != null) 'expiry_date': expiryDate.toIso8601String(),
      if (pickupTime != null) 'pickup_time': pickupTime.toIso8601String(),
      'image_urls': imageUrls,
      if (city != null) 'city': city,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    });
    if (res.statusCode != 201) throw Exception(ApiClient.errorMessage(res));
    return Donation.fromJson(jsonDecode(res.body));
  }

  static Future<Donation> updateDonation(
    String id, {
    String? title,
    String? description,
    String? category,
    int? quantity,
    String? unit,
    DateTime? expiryDate,
    DateTime? pickupTime,
    List<String>? imageUrls,
    String? city,
    String? status,
  }) async {
    final body = <String, dynamic>{
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (quantity != null) 'quantity': quantity,
      if (unit != null) 'unit': unit,
      if (expiryDate != null) 'expiry_date': expiryDate.toIso8601String(),
      if (pickupTime != null) 'pickup_time': pickupTime.toIso8601String(),
      if (imageUrls != null) 'image_urls': imageUrls,
      if (city != null) 'city': city,
      if (status != null) 'status': status,
    };
    final res = await ApiClient.put('/donations/$id', body: body);
    if (res.statusCode != 200) throw Exception(ApiClient.errorMessage(res));
    return Donation.fromJson(jsonDecode(res.body));
  }

  static Future<void> deleteDonation(String id) async {
    final res = await ApiClient.delete('/donations/$id');
    if (res.statusCode != 204) throw Exception(ApiClient.errorMessage(res));
  }

  /// Uploads an image file to the backend and returns the public URL.
  /// Throws an [Exception] with a user-readable message on failure.
  static Future<String> uploadImage(Uint8List imageBytes, String filename) async {
    final uri = Uri.parse('${ApiClient.baseUrl}/upload');
    final token = await ApiClient.getAccessToken();

    final ext = filename.split('.').last.toLowerCase();
    final mimeType = switch (ext) {
      'png'  => 'image/png',
      'heic' => 'image/heic',
      'heif' => 'image/heif',
      'webp' => 'image/webp',
      _      => 'image/jpeg',
    };

    final request = http.MultipartRequest('POST', uri);
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      imageBytes,
      filename: filename,
      contentType: MediaType.parse(mimeType),
    ));

    try {
      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final url = body['url'] as String?;
        if (url != null) return url;
        throw Exception('Server returned no URL');
      }

      // Extract the backend's detail message for specific errors
      String detail = 'Upload failed (${response.statusCode})';
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['detail'] != null) detail = body['detail'].toString();
      } catch (_) {}

      throw Exception(detail);
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Could not reach server: $e');
    }
  }
}
