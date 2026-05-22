import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skillforgeapp/widgets/admin/admin_section_tile.dart';
import 'package:skillforgeapp/ui/design_system.dart';
import 'package:skillforgeapp/view_models/admin/admin_home_view_model.dart';

class AdminHomeView extends ConsumerWidget {
  const AdminHomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(adminHomeItemsViewModelProvider);
    return AppPage(
      title: 'Admin Command Center',
      subtitle: 'Manage the SkillForge ecosystem',
      child: ListView(
        children: items
            .asMap()
            .entries
            .expand(
              (entry) => [
                if (entry.key != 0) const SizedBox(height: 10),
                AdminSectionTile(
                  icon: entry.value.icon,
                  title: entry.value.title,
                  subtitle: entry.value.subtitle,
                  route: entry.value.route,
                ),
              ],
            )
            .toList(),
      ),
    );
  }
}
