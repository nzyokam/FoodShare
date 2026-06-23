import 'dart:convert';
import 'api_client.dart';
import '../models/restaurant_model.dart';
import '../models/shelter_model.dart';

class ProfileService {
  static Future<Restaurant> saveRestaurant({
    String? businessName,
    String? businessLicense,
    String? address,
    String? city,
    String? phone,
    String? description,
    List<String>? cuisineTypes,
    double? latitude,
    double? longitude,
  }) async {
    final res = await ApiClient.post('/profiles/restaurant', body: {
      if (businessName != null) 'business_name': businessName,
      if (businessLicense != null) 'business_license': businessLicense,
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (phone != null) 'phone': phone,
      if (description != null) 'description': description,
      if (cuisineTypes != null) 'cuisine_types': cuisineTypes,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    });
    if (res.statusCode != 200) throw Exception(ApiClient.errorMessage(res));
    return Restaurant.fromJson(jsonDecode(res.body));
  }

  static Future<Restaurant?> getRestaurant(String id) async {
    final res = await ApiClient.get('/profiles/restaurant/$id');
    if (res.statusCode == 200) return Restaurant.fromJson(jsonDecode(res.body));
    if (res.statusCode == 404) return null;
    throw Exception(ApiClient.errorMessage(res));
  }

  static Future<Shelter> saveShelter({
    String? organizationName,
    String? registrationNumber,
    String? address,
    String? city,
    String? phone,
    int? capacity,
    String? targetDemographic,
    String? description,
    double? latitude,
    double? longitude,
  }) async {
    final res = await ApiClient.post('/profiles/shelter', body: {
      if (organizationName != null) 'organization_name': organizationName,
      if (registrationNumber != null) 'registration_number': registrationNumber,
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (phone != null) 'phone': phone,
      if (capacity != null) 'capacity': capacity,
      if (targetDemographic != null) 'target_demographic': targetDemographic,
      if (description != null) 'description': description,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    });
    if (res.statusCode != 200) throw Exception(ApiClient.errorMessage(res));
    return Shelter.fromJson(jsonDecode(res.body));
  }

  static Future<Shelter?> getShelter(String id) async {
    final res = await ApiClient.get('/profiles/shelter/$id');
    if (res.statusCode == 200) return Shelter.fromJson(jsonDecode(res.body));
    if (res.statusCode == 404) return null;
    throw Exception(ApiClient.errorMessage(res));
  }
}
