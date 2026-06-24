import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/donation_model.dart';
import '../services/donation_service.dart';

final myDonationsProvider = FutureProvider.autoDispose<List<Donation>>((ref) async {
  return DonationService.myDonations();
});

class DonationFilter {
  final String? city;
  final String? category;
  final String? search;

  const DonationFilter({this.city, this.category, this.search});

  @override
  bool operator ==(Object other) =>
      other is DonationFilter &&
      other.city == city &&
      other.category == category &&
      other.search == search;

  @override
  int get hashCode => Object.hash(city, category, search);
}

final browseDonationsProvider = FutureProvider.autoDispose.family<List<Donation>, DonationFilter>(
  (ref, filter) async {
    return DonationService.listDonations(
      city: filter.city,
      category: filter.category,
      status: 'available',
      search: filter.search,
    );
  },
);
