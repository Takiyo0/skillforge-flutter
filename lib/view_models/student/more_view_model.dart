import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skillforgeapp/providers/app_state.dart';
import 'package:skillforgeapp/utils/permissions.dart';

class MoreMenuItem {
  const MoreMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
    this.replace = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final bool replace;
}

final moreMenuItemsViewModelProvider = Provider<List<MoreMenuItem>>((ref) {
  final session = ref.watch(sessionProvider);
  final showAdmin = canAccessAdmin(session.user);
  return [
    const MoreMenuItem(
      icon: Icons.route_outlined,
      title: 'Paths',
      subtitle: 'Learning paths and guidance',
      route: '/student/learning-paths',
    ),
    const MoreMenuItem(
      icon: Icons.emoji_events_outlined,
      title: 'Trophies',
      subtitle: 'Certificates and achievements',
      route: '/student/certificates',
    ),
    const MoreMenuItem(
      icon: Icons.leaderboard_outlined,
      title: 'Leaderboard',
      subtitle: 'Weekly ranks and all-time legends',
      route: '/student/leaderboard',
    ),
    const MoreMenuItem(
      icon: Icons.science_outlined,
      title: 'Sandbox',
      subtitle: 'Code playground and experiments',
      route: '/student/code-sandbox',
    ),
    const MoreMenuItem(
      icon: Icons.settings_outlined,
      title: 'Settings',
      subtitle: 'Account and preferences',
      route: '/student/settings',
    ),
    if (showAdmin)
      const MoreMenuItem(
        icon: Icons.admin_panel_settings_outlined,
        title: 'Admin',
        subtitle: 'Manage users, paths, and badges',
        route: '/admin/courses',
        replace: true,
      ),
  ];
});
