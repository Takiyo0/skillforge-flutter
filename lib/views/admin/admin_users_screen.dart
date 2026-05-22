import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skillforgeapp/models/admin/admin_models.dart';
import 'package:skillforgeapp/ui/design_system.dart';
import 'package:skillforgeapp/view_models/admin/admin_users_view_model.dart';
import 'package:skillforgeapp/widgets/shared/app_confirm_dialog.dart';
import 'package:skillforgeapp/widgets/shared/app_stat_card.dart';

class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({super.key});

  @override
  ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage> {
  static const _roles = ['learner', 'instructor', 'admin'];

  final _searchController = TextEditingController();

  List<AdminUser> _users = const [];
  AdminUserStats? _stats;
  bool _loading = true;
  bool _busyAction = false;
  String? _error;

  String _roleFilter = '';
  String _statusFilter = '';
  int _page = 1;
  int _total = 0;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(adminUsersActionsProvider.notifier);
      final usersResult = await repo.listUsers(
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        role: _roleFilter.isEmpty ? null : _roleFilter,
        status: _statusFilter.isEmpty ? null : _statusFilter,
        page: _page,
        limit: 20,
      );
      final stats = await repo.getUserStats();

      final pagination = usersResult.pagination ?? const <String, dynamic>{};
      final total = _toInt(pagination['total']) ?? usersResult.data.length;
      final totalPages =
          _toInt(pagination['totalPages']) ?? _guessPages(total, 20);
      setState(() {
        _users = usersResult.data;
        _stats = stats;
        _total = total;
        _totalPages = totalPages < 1 ? 1 : totalPages;
      });
    } catch (e) {
      setState(
        () => _error = 'Failed to load users: ${AppToast.errorMessage(e)}',
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _runAction(
    Future<void> Function() action, {
    required String successMessage,
    required String errorPrefix,
  }) async {
    setState(() => _busyAction = true);
    try {
      await action();
      _showSnack(successMessage);
      await _load();
    } catch (e) {
      _showSnack('$errorPrefix: ${AppToast.errorMessage(e)}');
    } finally {
      if (mounted) setState(() => _busyAction = false);
    }
  }

  void _showSnack(String message) {
    AppToast.show(context, message);
  }

  Future<void> _openRolesDialog(AdminUser user) async {
    final selected = user.roles.toSet();
    final roles = await showAppDialog<Set<String>>(
      context: context,
      useRootNavigator: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Roles'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: _roles.map((role) {
                  return CheckboxListTile(
                    value: selected.contains(role),
                    title: Text(role),
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (checked) {
                      setDialogState(() {
                        if (checked == true) {
                          selected.add(role);
                        } else {
                          selected.remove(role);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (selected.isEmpty) {
                      _showSnack('At least one role is required');
                      return;
                    }
                    Navigator.of(context).pop(selected);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (roles == null) return;
    await _runAction(
      () => ref
          .read(adminUsersActionsProvider.notifier)
          .updateUserRoles(user.id, roles.toList()),
      successMessage: 'Roles updated',
      errorPrefix: 'Failed to update roles',
    );
  }

  Future<void> _confirmAndRun({
    required String title,
    required String message,
    required Future<void> Function() action,
    required String successMessage,
    required String errorPrefix,
    bool destructive = false,
  }) async {
    final confirm = await showAppConfirmDialog(
      context,
      title: title,
      message: message,
      destructive: destructive,
    );
    if (!confirm) return;
    await _runAction(
      action,
      successMessage: successMessage,
      errorPrefix: errorPrefix,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Users',
      subtitle: 'Roles and account access',
      child: ListView(
        children: [
          if (_stats != null) _StatsGrid(stats: _stats!),
          const SizedBox(height: 10),
          GlassPanel(
            radius: 18,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Search by name or email',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onSubmitted: (_) {
                    setState(() => _page = 1);
                    _load();
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _roleFilter,
                        decoration: const InputDecoration(labelText: 'Role'),
                        items: const [
                          DropdownMenuItem(value: '', child: Text('All Roles')),
                          DropdownMenuItem(
                            value: 'learner',
                            child: Text('Learner'),
                          ),
                          DropdownMenuItem(
                            value: 'instructor',
                            child: Text('Instructor'),
                          ),
                          DropdownMenuItem(
                            value: 'admin',
                            child: Text('Admin'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => _roleFilter = value ?? '');
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _statusFilter,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: const [
                          DropdownMenuItem(
                            value: '',
                            child: Text('All Status'),
                          ),
                          DropdownMenuItem(
                            value: 'active',
                            child: Text('Active'),
                          ),
                          DropdownMenuItem(
                            value: 'inactive',
                            child: Text('Inactive'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => _statusFilter = value ?? '');
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _loading
                            ? null
                            : () {
                                _searchController.clear();
                                setState(() {
                                  _roleFilter = '';
                                  _statusFilter = '';
                                  _page = 1;
                                });
                                _load();
                              },
                        child: const Text('Reset'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: _loading
                            ? null
                            : () {
                                setState(() => _page = 1);
                                _load();
                              },
                        child: const Text('Apply'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (_error != null)
            GlassPanel(
              radius: 18,
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            )
          else if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_users.isEmpty)
            const GlassPanel(
              radius: 18,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(child: Text('No users found')),
              ),
            )
          else
            ..._users.map(
              (user) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _UserCard(
                  user: user,
                  disabled: _busyAction,
                  onViewProfile: () =>
                      context.push('/student/profile/${user.id}'),
                  onEditRoles: () => _openRolesDialog(user),
                  onActivate: () => _confirmAndRun(
                    title: 'Activate User',
                    message: 'Activate ${user.displayName}?',
                    action: () => ref
                        .read(adminUsersActionsProvider.notifier)
                        .activateUser(user.id),
                    successMessage: 'User activated',
                    errorPrefix: 'Failed to activate user',
                  ),
                  onDeactivate: () => _confirmAndRun(
                    title: 'Deactivate User',
                    message:
                        'Deactivate ${user.displayName}? They will lose access.',
                    action: () => ref
                        .read(adminUsersActionsProvider.notifier)
                        .deactivateUser(user.id),
                    successMessage: 'User deactivated',
                    errorPrefix: 'Failed to deactivate user',
                  ),
                  onDelete: () => _confirmAndRun(
                    title: 'Delete User',
                    message:
                        'Delete ${user.displayName}? This cannot be undone.',
                    action: () => ref
                        .read(adminUsersActionsProvider.notifier)
                        .deleteUser(user.id),
                    successMessage: 'User deleted',
                    errorPrefix: 'Failed to delete user',
                    destructive: true,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 10),
          GlassPanel(
            radius: 18,
            child: Row(
              children: [
                Expanded(
                  child: Text('Showing ${_users.length} of $_total users'),
                ),
                IconButton(
                  onPressed: _page <= 1 || _loading
                      ? null
                      : () {
                          setState(() => _page -= 1);
                          _load();
                        },
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('$_page / $_totalPages'),
                IconButton(
                  onPressed: _page >= _totalPages || _loading
                      ? null
                      : () {
                          setState(() => _page += 1);
                          _load();
                        },
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final AdminUserStats stats;

  @override
  Widget build(BuildContext context) {
    final adminCount = stats.byRole['admin'] ?? 0;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        AppStatCard(
          label: 'Total Users',
          value: '${stats.totalUsers}',
          width: _statWidth(context),
        ),
        AppStatCard(
          label: 'Active Users',
          value: '${stats.activeUsers}',
          width: _statWidth(context),
        ),
        AppStatCard(
          label: 'Inactive Users',
          value: '${stats.inactiveUsers}',
          width: _statWidth(context),
        ),
        AppStatCard(
          label: 'Admins',
          value: '$adminCount',
          width: _statWidth(context),
        ),
      ],
    );
  }

  double _statWidth(BuildContext context) {
    return MediaQuery.sizeOf(context).width > 560
        ? (MediaQuery.sizeOf(context).width - 52) / 2
        : double.infinity;
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.disabled,
    required this.onViewProfile,
    required this.onEditRoles,
    required this.onActivate,
    required this.onDeactivate,
    required this.onDelete,
  });

  final AdminUser user;
  final bool disabled;
  final VoidCallback onViewProfile;
  final VoidCallback onEditRoles;
  final VoidCallback onActivate;
  final VoidCallback onDeactivate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final joined = _fmtDate(user.createdAt);
    return GlassPanel(
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(user.email),
                  ],
                ),
              ),
              PopupMenuButton<_UserAction>(
                enabled: !disabled,
                useRootNavigator: true,
                onSelected: (action) {
                  switch (action) {
                    case _UserAction.viewProfile:
                      onViewProfile();
                      return;
                    case _UserAction.roles:
                      onEditRoles();
                      return;
                    case _UserAction.activate:
                      onActivate();
                      return;
                    case _UserAction.deactivate:
                      onDeactivate();
                      return;
                    case _UserAction.delete:
                      onDelete();
                      return;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: _UserAction.viewProfile,
                    child: Text('View profile'),
                  ),
                  const PopupMenuItem(
                    value: _UserAction.roles,
                    child: Text('Edit roles'),
                  ),
                  PopupMenuItem(
                    value: user.isActive
                        ? _UserAction.deactivate
                        : _UserAction.activate,
                    child: Text(user.isActive ? 'Deactivate' : 'Activate'),
                  ),
                  const PopupMenuItem(
                    value: _UserAction.delete,
                    child: Text('Delete user'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ...user.roles.map((role) => Chip(label: Text(role))),
              Chip(
                backgroundColor: user.isActive
                    ? Colors.green.withValues(alpha: 0.2)
                    : Colors.red.withValues(alpha: 0.2),
                label: Text(user.isActive ? 'Active' : 'Inactive'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Joined: $joined', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

enum _UserAction { viewProfile, roles, activate, deactivate, delete }

int? _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

int _guessPages(int total, int limit) {
  if (limit <= 0) return 1;
  final pages = (total / limit).ceil();
  return pages == 0 ? 1 : pages;
}

String _fmtDate(DateTime value) {
  if (value.millisecondsSinceEpoch == 0) return '-';
  final local = value.toLocal();
  final yyyy = local.year.toString().padLeft(4, '0');
  final mm = local.month.toString().padLeft(2, '0');
  final dd = local.day.toString().padLeft(2, '0');
  return '$yyyy-$mm-$dd';
}
