import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/owner_app_drawer.dart';
import '../widgets/price_list_calendar_widget.dart';

/// Price List Screen - displays year-grid calendar for price management
class PriceListScreen extends ConsumerWidget {
  const PriceListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cjenovnik'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      drawer: const OwnerAppDrawer(currentRoute: 'price-list'),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: PriceListCalendarWidget(),
      ),
    );
  }
}
