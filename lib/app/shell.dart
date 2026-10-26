import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/layout/responsive.dart';

/// Kerangka navigasi adaptif (§3.6, §6):
/// - mobile (<600 px): NavigationBar;
/// - web/lebar (>=600 px): NavigationRail.
///
/// Item navigasi utama tetap: Beranda · Layanan · Panduan (Minggu 3).
class AdaptiveShell extends StatelessWidget {
  final int selectedIndex;
  final Widget child;

  const AdaptiveShell({
    super.key,
    required this.selectedIndex,
    required this.child,
  });

  static const _destinations = [
    (path: '/', label: 'Beranda', icon: Icons.home_outlined, selected: Icons.home),
    (
      path: '/layanan',
      label: 'Layanan',
      icon: Icons.list_alt_outlined,
      selected: Icons.list_alt,
    ),
    (
      path: '/panduan',
      label: 'Panduan',
      icon: Icons.route_outlined,
      selected: Icons.route,
    ),
  ];

  void _go(BuildContext context, int index) =>
      context.go(_destinations[index].path);

  @override
  Widget build(BuildContext context) {
    final lebar = MediaQuery.sizeOf(context).width;

    if (lebar >= kResponsiveBreakpoint) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex.clamp(0, _destinations.length - 1),
              onDestinationSelected: (i) => _go(context, i),
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final d in _destinations)
                  NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selected),
                    label: Text(d.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex.clamp(0, _destinations.length - 1),
        onDestinationSelected: (i) => _go(context, i),
        destinations: [
          for (final d in _destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selected),
              label: d.label,
            ),
        ],
      ),
    );
  }
}
