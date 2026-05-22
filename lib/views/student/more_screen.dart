import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skillforgeapp/ui/design_system.dart';
import 'package:skillforgeapp/view_models/student/more_view_model.dart';

class MorePage extends ConsumerWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(moreMenuItemsViewModelProvider);

    return AppPage(
      title: 'More',
      subtitle: 'More options',
      child: ListView(
        children: items
            .asMap()
            .entries
            .expand(
              (entry) => [
                if (entry.key != 0) const SizedBox(height: 8),
                _MoreTile(
                  icon: entry.value.icon,
                  title: entry.value.title,
                  subtitle: entry.value.subtitle,
                  route: entry.value.route,
                  replace: entry.value.replace,
                ),
              ],
            )
            .toList(),
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
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

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: () {
          if (replace) {
            context.go(route);
            return;
          }
          context.push(route);
        },
      ),
    );
  }
}
