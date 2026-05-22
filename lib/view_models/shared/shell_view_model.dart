import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skillforgeapp/ui/shell_header_state.dart';

import '../../ui/design_system.dart';

typedef ShellTab = ({String label, IconData icon, String route});

const shellTabs = <ShellTab>[
  (label: 'Home', icon: Icons.home_outlined, route: '/student/dashboard'),
  (
    label: 'Courses',
    icon: Icons.menu_book_outlined,
    route: '/student/browse-courses',
  ),
  (label: 'Forums', icon: Icons.forum_outlined, route: '/student/forum'),
  (label: 'More', icon: Icons.more_horiz, route: '/student/more'),
  (label: 'Profile', icon: Icons.person_outline, route: '/student/profile/me'),
];

class ShellComputedState {
  const ShellComputedState({
    required this.selectedIndex,
    required this.showBack,
    required this.title,
    required this.subtitle,
  });

  final int selectedIndex;
  final bool showBack;
  final String title;
  final String subtitle;
}

final shellComputedViewModelProvider =
    Provider.family<ShellComputedState, String>((ref, path) {
      final header = ref.watch(shellHeaderProvider);
      var selectedIndex = shellTabs.indexWhere((t) => path.startsWith(t.route));
      if (selectedIndex < 0 && path.contains('/forums')) {
        selectedIndex = shellTabs.indexWhere(
          (t) => t.route == '/student/forum',
        );
      }
      if (selectedIndex < 0 && path.startsWith('/student/courses/')) {
        selectedIndex = shellTabs.indexWhere(
          (t) => t.route == '/student/browse-courses',
        );
      }
      if (selectedIndex < 0 &&
          (path.startsWith('/student/learning-paths') ||
              path.startsWith('/student/learning-path') ||
              path.startsWith('/student/certificates') ||
              path.startsWith('/student/code-sandbox') ||
              path.startsWith('/student/playground') ||
              path.startsWith('/student/settings'))) {
        selectedIndex = shellTabs.indexWhere((t) => t.route == '/student/more');
      }
      if (selectedIndex < 0 && path.startsWith('/student/profile/')) {
        selectedIndex = shellTabs.indexWhere(
          (t) => t.route == '/student/profile/me',
        );
      }
      if (selectedIndex < 0 && path.startsWith('/admin')) {
        selectedIndex = shellTabs.indexWhere((t) => t.route == '/student/more');
      }
      if (selectedIndex < 0) selectedIndex = 0;
      final mainTabRoutes = shellTabs.map((t) => t.route).toSet();
      final showBack = !mainTabRoutes.contains(path);
      final title = header.title.isEmpty
          ? shellTabs[selectedIndex].label
          : header.title;
      final subtitle = (header.subtitle ?? '').trim();

      return ShellComputedState(
        selectedIndex: selectedIndex,
        showBack: showBack,
        title: title,
        subtitle: subtitle,
      );
    });
