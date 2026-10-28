import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../routes/router_name.dart';

/// Shell with the bottom navigation bar: Dashboard, Visitors, Scan.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const int _scanIndex = 2;

  void _onTap(BuildContext context, int index) {
    if (index == _scanIndex) {
      context.push(RouteName.scan);
      return;
    }
    navigationShell.goBranch(
      index,
      // Tapping the active tab again returns it to its first page.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => _onTap(context, index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Visitors',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Scan',
          ),
        ],
      ),
    );
  }
}
