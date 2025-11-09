import 'package:flutter/material.dart';
import '../widgets/owner_app_drawer.dart';
import 'dashboard_overview_tab.dart';

/// Overview screen (Pregled)
class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      drawer: OwnerAppDrawer(currentRoute: 'overview'),
      body: DashboardOverviewTab(),
    );
  }
}
