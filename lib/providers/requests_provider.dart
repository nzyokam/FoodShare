import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/request_model.dart';
import '../services/request_service.dart';

/// Shelter's own requests (with enriched donation + restaurant data)
final myRequestsProvider = FutureProvider.autoDispose<List<DonationRequest>>((ref) async {
  return RequestService.myRequests();
});

/// Requests received by a restaurant (with enriched donation + shelter data)
final receivedRequestsProvider = FutureProvider.autoDispose<List<DonationRequest>>((ref) async {
  return RequestService.receivedRequests();
});
