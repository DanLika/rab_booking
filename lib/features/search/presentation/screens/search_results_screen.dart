import 'package:flutter/material.dart';
import '../../../../shared/presentation/screens/placeholder_screen.dart';

class SearchResultsScreen extends StatelessWidget {
  const SearchResultsScreen({
    this.query,
    this.location,
    this.maxGuests,
    this.checkIn,
    this.checkOut,
    super.key,
  });

  final String? query;
  final String? location;
  final int? maxGuests;
  final String? checkIn;
  final String? checkOut;

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: 'Rezultati pretrage',
      description: query != null ? 'Pretraga: "$query"' : 'Pretraži properties',
      icon: Icons.search,
    );
  }
}
