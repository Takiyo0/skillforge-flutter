import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skillforgeapp/models/admin/admin_models.dart';
import 'package:skillforgeapp/models/shared/paginated_response.dart';
import 'package:skillforgeapp/providers/infrastructure_providers.dart';

class AdminUsersActions extends AutoDisposeNotifier<void> {
  @override
  void build() {}

  Future<PaginatedResponse<AdminUser>> listUsers({
    String? search,
    String? role,
    String? status,
    int? page,
    int? limit,
  }) {
    return ref
        .read(skillForgeApiProvider)
        .listUsers(
          search: search,
          role: role,
          status: status,
          page: page,
          limit: limit,
        );
  }

  Future<AdminUserStats> getUserStats() {
    return ref.read(skillForgeApiProvider).getUserStats();
  }

  Future<void> updateUserRoles(String userId, List<String> roles) {
    return ref.read(skillForgeApiProvider).updateUserRoles(userId, roles);
  }

  Future<void> activateUser(String userId) {
    return ref.read(skillForgeApiProvider).activateUser(userId);
  }

  Future<void> deactivateUser(String userId) {
    return ref.read(skillForgeApiProvider).deactivateUser(userId);
  }

  Future<void> deleteUser(String userId) {
    return ref.read(skillForgeApiProvider).deleteUser(userId);
  }
}

final adminUsersActionsProvider =
    AutoDisposeNotifierProvider<AdminUsersActions, void>(AdminUsersActions.new);
