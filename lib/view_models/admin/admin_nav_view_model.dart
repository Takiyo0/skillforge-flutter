class AdminSection {
  const AdminSection({required this.route, required this.label});

  final String route;
  final String label;
}

class AdminNavViewModel {
  const AdminNavViewModel();

  static const String homeRoute = '/admin';

  static const List<AdminSection> sections = [
    AdminSection(route: '/student/dashboard', label: '<'),
    AdminSection(route: '/admin/courses', label: 'Courses'),
    AdminSection(route: '/admin/learning-paths', label: 'Paths'),
    AdminSection(route: '/admin/badges', label: 'Badges'),
    AdminSection(route: '/admin/users', label: 'Users'),
  ];

  int selectedIndexForPath(String path) {
    final index = sections.indexWhere(
      (section) => path.startsWith(section.route),
    );
    if (index >= 0) return index;
    return 0;
  }
}
