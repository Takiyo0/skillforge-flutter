import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skillforgeapp/models/admin/admin_models.dart';
import 'package:skillforgeapp/providers/infrastructure_providers.dart';

class AdminBadgesActions extends AutoDisposeNotifier<void> {
  @override
  void build() {}

  Future<List<AdminBadge>> getAllBadges() {
    return ref.read(skillForgeApiProvider).getAllBadges();
  }

  Future<List<BadgeCriteriaMetadata>> getBadgeCriteriaMetadata() {
    return ref.read(skillForgeApiProvider).getBadgeCriteriaMetadata();
  }

  Future<void> deleteBadge(String badgeId) {
    return ref.read(skillForgeApiProvider).deleteBadge(badgeId);
  }

  Future<AdminBadge> createBadge({
    required String code,
    required String name,
    required String description,
    required String criteriaType,
    String? language,
    int? xp,
  }) {
    return ref
        .read(skillForgeApiProvider)
        .createBadge(
          code: code,
          name: name,
          description: description,
          criteriaType: criteriaType,
          language: language,
          xp: xp,
        );
  }

  Future<AdminBadge> updateBadge({
    required String badgeId,
    required String code,
    required String name,
    required String description,
    String? iconS3Key,
    required String criteriaType,
    String? language,
    int? xp,
  }) {
    return ref
        .read(skillForgeApiProvider)
        .updateBadge(
          badgeId: badgeId,
          code: code,
          name: name,
          description: description,
          iconS3Key: iconS3Key,
          criteriaType: criteriaType,
          language: language,
          xp: xp,
        );
  }

  Future<AdminBadge> uploadBadgeIcon({
    required String badgeId,
    required String fileName,
    required List<int> bytes,
    String? contentType,
  }) {
    return ref
        .read(skillForgeApiProvider)
        .uploadBadgeIcon(
          badgeId: badgeId,
          fileName: fileName,
          bytes: bytes,
          contentType: contentType,
        );
  }
}

final adminBadgesActionsProvider =
    AutoDisposeNotifierProvider<AdminBadgesActions, void>(
      AdminBadgesActions.new,
    );
