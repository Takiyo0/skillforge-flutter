import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminHomeItem {
  const AdminHomeItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
}

final adminHomeItemsViewModelProvider = Provider<List<AdminHomeItem>>((ref) {
  return const [
    AdminHomeItem(
      icon: Icons.map_outlined,
      title: 'Learning Paths',
      subtitle: 'Create paths and manage course order',
      route: '/admin/learning-paths',
    ),
    AdminHomeItem(
      icon: Icons.workspace_premium_outlined,
      title: 'Badges',
      subtitle: 'Create milestones and upload badge icons',
      route: '/admin/badges',
    ),
    AdminHomeItem(
      icon: Icons.group_outlined,
      title: 'Users',
      subtitle: 'Manage roles and account status',
      route: '/admin/users',
    ),
    AdminHomeItem(
      icon: Icons.menu_book_outlined,
      title: 'Courses',
      subtitle: 'Manage courses, units, and course metadata',
      route: '/admin/courses',
    ),
  ];
});
