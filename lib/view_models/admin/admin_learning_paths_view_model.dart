import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skillforgeapp/models/admin/admin_models.dart';
import 'package:skillforgeapp/providers/infrastructure_providers.dart';

class AdminLearningPathsActions extends AutoDisposeNotifier<void> {
  @override
  void build() {}

  Future<List<AdminLearningPath>> getAllLearningPathsAdmin() {
    return ref.read(skillForgeApiProvider).getAllLearningPathsAdmin();
  }

  Future<List<AdminCourseSummary>> getInstructorCourses() {
    return ref.read(skillForgeApiProvider).getInstructorCourses();
  }

  Future<AdminLearningPath> getLearningPathAdmin(String pathId) {
    return ref.read(skillForgeApiProvider).getLearningPathAdmin(pathId);
  }

  Future<AdminLearningPath> createLearningPath({
    required String slug,
    required String title,
    required String description,
    required bool isPublic,
    required List<String> wantToLearn,
    required List<String> languages,
    required List<String> alreadyKnow,
  }) {
    return ref
        .read(skillForgeApiProvider)
        .createLearningPath(
          slug: slug,
          title: title,
          description: description,
          isPublic: isPublic,
          wantToLearn: wantToLearn,
          languages: languages,
          alreadyKnow: alreadyKnow,
        );
  }

  Future<Map<String, dynamic>> updateLearningPathPatch({
    required String pathId,
    required String title,
    required String description,
    required List<String> wantToLearn,
    required List<String> languages,
    required List<String> alreadyKnow,
    required bool isPublic,
  }) {
    return ref
        .read(skillForgeApiProvider)
        .updateLearningPathPatch(
          pathId: pathId,
          title: title,
          description: description,
          wantToLearn: wantToLearn,
          languages: languages,
          alreadyKnow: alreadyKnow,
          isPublic: isPublic,
        );
  }

  Future<void> deleteLearningPath(String pathId) {
    return ref.read(skillForgeApiProvider).deleteLearningPath(pathId);
  }

  Future<void> addCoursesToPath(String pathId, List<String> courseIds) {
    return ref.read(skillForgeApiProvider).addCoursesToPath(pathId, courseIds);
  }

  Future<void> removeCourseFromPath(String pathId, String courseId) {
    return ref
        .read(skillForgeApiProvider)
        .removeCourseFromPath(pathId, courseId);
  }

  Future<void> reorderCoursesInPath(
    String pathId,
    List<String> orderedCourseIds,
  ) {
    return ref
        .read(skillForgeApiProvider)
        .reorderCoursesInPath(pathId, orderedCourseIds);
  }
}

final adminLearningPathsActionsProvider =
    AutoDisposeNotifierProvider<AdminLearningPathsActions, void>(
      AdminLearningPathsActions.new,
    );
