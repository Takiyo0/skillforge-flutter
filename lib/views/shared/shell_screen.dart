import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:skillforgeapp/providers/app_state.dart';
import 'package:skillforgeapp/config/asset_urls.dart';
import 'package:skillforgeapp/ui/design_system.dart';
import 'package:skillforgeapp/view_models/shared/shell_view_model.dart';

class ShellPage extends ConsumerWidget {
  const ShellPage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = GoRouterState.of(context).uri.path;
    final vm = ref.watch(shellComputedViewModelProvider(path));

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
                    if (vm.showBack)
                      IconButton(
                        onPressed: () {
                          if (GoRouter.of(context).canPop()) {
                            context.pop();
                            return;
                          }
                          if (path.startsWith('/student/courses/')) {
                            context.go('/student/browse-courses');
                            return;
                          }
                          context.go('/student/dashboard');
                        },
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
                            vm.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (vm.subtitle.isNotEmpty)
                            Text(
                              vm.subtitle,
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
                  children: shellTabs.indexed
                      .map(
                        (entry) => Expanded(
                          child: _SideNavItem(
                            route: entry.$2.route,
                            icon: entry.$2.icon,
                            active: entry.$1 == vm.selectedIndex,
                            onTap: () => context.go(entry.$2.route),
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

class _SideNavItem extends ConsumerWidget {
  const _SideNavItem({
    required this.route,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String route;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider).user;
    final avatarUrl = route == '/student/profile/me'
        ? (AssetUrls.avatarUrl(user?.avatarS3Key) ??
              AssetUrls.dicebearAvatarUrl(user?.id ?? 'me'))
        : null;
    return Material(
      color: active
          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(48),
      child: InkWell(
        borderRadius: BorderRadius.circular(48),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Center(
            child: avatarUrl == null
                ? Icon(icon, size: 28)
                : _ProfileAvatar(imageUrl: avatarUrl, active: active),
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.imageUrl, required this.active});

  final String imageUrl;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final borderColor = active
        ? Theme.of(context).colorScheme.primary
        : Colors.transparent;
    return Container(
      width: 28,
      height: 28,
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 1.4),
      ),
      child: ClipOval(
        child: AssetUrls.isSvgUrl(imageUrl)
            ? SvgPicture.network(imageUrl, fit: BoxFit.cover)
            : Image.network(imageUrl, fit: BoxFit.cover),
      ),
    );
  }
}
