import 'package:flutter/material.dart';
import '../widgets/owner_app_drawer.dart';
import 'dashboard_overview_tab.dart';

/// Overview screen (Pregled)
class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pregled'),
      ),
      drawer: const OwnerAppDrawer(currentRoute: 'overview'),
      body: const SingleChildScrollView(
        child: DashboardOverviewTab(),
      ),
    );
  }
}
