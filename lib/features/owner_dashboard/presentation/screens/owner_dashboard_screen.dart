import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Owner dashboard screen with tabs
class OwnerDashboardScreen extends ConsumerStatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  ConsumerState<OwnerDashboardScreen> createState() =>
      _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends ConsumerState<OwnerDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vlasnik Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Moji Objekti', icon: Icon(Icons.home_outlined)),
            Tab(text: 'Kalendar', icon: Icon(Icons.calendar_month)),
            Tab(text: 'Rezervacije', icon: Icon(Icons.book_online)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _PropertiesListTab(),
          _MasterCalendarTab(),
          _BookingsListTab(),
        ],
      ),
    );
  }
}

/// Properties list tab
class _PropertiesListTab extends ConsumerWidget {
  const _PropertiesListTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.villa, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Moji Objekti',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Lista vaših smještaja će biti prikazana ovdje',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              // TODO: Navigate to add property
            },
            icon: const Icon(Icons.add),
            label: const Text('Dodaj Novi Objekt'),
          ),
        ],
      ),
    );
  }
}

/// Master calendar tab
class _MasterCalendarTab extends ConsumerWidget {
  const _MasterCalendarTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_month, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Glavni Kalendar',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Pregled svih rezervacija za sve objekte',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

/// Bookings list tab
class _BookingsListTab extends ConsumerWidget {
  const _BookingsListTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.book_online, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Rezervacije',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Upravljajte svojim rezervacijama',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
