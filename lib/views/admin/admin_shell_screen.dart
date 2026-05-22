import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skillforgeapp/utils/permissions.dart';
import 'package:skillforgeapp/providers/app_state.dart';
import 'package:skillforgeapp/view_models/admin/admin_nav_view_model.dart';
import 'package:skillforgeapp/ui/design_system.dart';

class AdminShellPage extends ConsumerWidget {
  const AdminShellPage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = GoRouterState.of(context).uri.path;
    final navVm = const AdminNavViewModel();
    final selectedIndex = navVm.selectedIndexForPath(path);
    final sections = AdminNavViewModel.sections;
    final session = ref.watch(sessionProvider);
    final isAdminUser = isAdmin(session.user);
    final header = ref.watch(shellHeaderProvider);
    final title = header.title.isEmpty ? _titleForPath(path) : header.title;
    final subtitle = (header.subtitle ?? '').trim();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(child: AppRouteSurface(child: child)),
          Positioned(
            left: AppChromeMetrics.mobileOverlayMargin,
            right: AppChromeMetrics.mobileOverlayMargin,
            top: AppChromeMetrics.mobileOverlayMargin,
            child: SafeArea(
              bottom: false,
              child: GlassPanel(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                radius: 48,
                child: Row(
                  children: [
                    if (_showBack(path))
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        tooltip: 'Back',
                      )
                    else
                      const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (subtitle.isNotEmpty)
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: AppChromeMetrics.mobileOverlayMargin,
            right: AppChromeMetrics.mobileOverlayMargin,
            bottom: AppChromeMetrics.mobileOverlayMargin,
            child: SafeArea(
              top: false,
              child: GlassPanel(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                radius: 48,
                child: Row(
                  spacing: 8,
                  children: sections.indexed
                      .map(
                        (entry) => entry.$2.label.length < 2
                            ? IntrinsicWidth(
                                child: _NavigationItem(
                                  entry: entry,
                                  selectedIndex: selectedIndex,
                                  enabled: _isEnabledRoute(
                                    route: entry.$2.route,
                                    isAdminUser: isAdminUser,
                                  ),
                                ),
                              )
                            : Expanded(
                                child: _NavigationItem(
                                  entry: entry,
                                  selectedIndex: selectedIndex,
                                  enabled: _isEnabledRoute(
                                    route: entry.$2.route,
                                    isAdminUser: isAdminUser,
                                  ),
                                ),
                              ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  final (int, AdminSection) entry;
  final int selectedIndex;
  final bool enabled;

  const _NavigationItem({
    required this.entry,
    required this.selectedIndex,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final baseText = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700);
    return Material(
      color: entry.$1 == selectedIndex
          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(48),
      child: InkWell(
        borderRadius: BorderRadius.circular(48),
        onTap: enabled ? () => context.go(entry.$2.route) : null,
        child: Padding(
          padding: entry.$2.label.length < 2
              ? .symmetric(horizontal: 16, vertical: 10)
              : EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Center(
            child: Text(
              entry.$2.label,
              style: enabled
                  ? baseText
                  : baseText?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.42),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _AdminShellAction { more, dashboard }

bool _isEnabledRoute({required String route, required bool isAdminUser}) {
  if (route == '/admin/learning-paths' ||
      route == '/admin/badges' ||
      route == '/admin/users') {
    return isAdminUser;
  }
  return true;
}

bool _showBack(String path) {
  if (path == '/admin') return false;
  if (path == '/admin/learning-paths') return false;
  if (path == '/admin/badges') return false;
  if (path == '/admin/users') return false;
  if (path == '/admin/courses') return false;
  return true;
}

String _titleForPath(String path) {
  if (path == '/admin') return 'Admin Command Center';
  if (path.startsWith('/admin/learning-paths')) return 'Learning Paths';
  if (path.startsWith('/admin/badges')) return 'Badges';
  if (path.startsWith('/admin/users')) return 'Users';
  if (path.startsWith('/admin/courses')) return 'Courses';
  return 'Admin';
}
