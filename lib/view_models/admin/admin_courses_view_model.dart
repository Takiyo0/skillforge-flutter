import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skillforgeapp/models/admin/admin_models.dart';
import 'package:skillforgeapp/providers/infrastructure_providers.dart';

class AdminCoursesActions extends AutoDisposeNotifier<void> {
  @override
  void build() {}

  Future<List<AdminCourse>> getAdminCourses() {
    return ref.read(skillForgeApiProvider).getAdminCourses();
  }

  Future<List<SandboxLanguageSummary>> getSandboxLanguageCatalog() {
    return ref.read(skillForgeApiProvider).getSandboxLanguageCatalog();
  }

  Future<AdminCourse> createAdminCourse({
    required String title,
    required String subtitle,
    required String description,
    required String level,
    required String language,
    required int priceCents,
    required String currencyCode,
    required String trailerUrl,
  }) {
    return ref
        .read(skillForgeApiProvider)
        .createAdminCourse(
          title: title,
          subtitle: subtitle,
          description: description,
          level: level,
          language: language,
          priceCents: priceCents,
          currencyCode: currencyCode,
          trailerUrl: trailerUrl,
        );
  }

  Future<AdminCourse> uploadAdminCourseThumbnail({
    required String courseId,
    required String fileName,
    required List<int> bytes,
    String? contentType,
  }) {
    return ref
        .read(skillForgeApiProvider)
        .uploadAdminCourseThumbnail(
          courseId: courseId,
          fileName: fileName,
          bytes: bytes,
          contentType: contentType,
        );
  }
}

final adminCoursesActionsProvider =
    AutoDisposeNotifierProvider<AdminCoursesActions, void>(
      AdminCoursesActions.new,
    );
