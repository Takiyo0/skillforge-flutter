import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skillforgeapp/providers/infrastructure_providers.dart';

final courseDetailViewModelProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, courseId) async {
      final api = ref.read(skillForgeApiProvider);
      final detail = await api.getCourseDetail(courseId);
      final units = await api.getCourseUnits(courseId);
      Map<String, dynamic>? progress;
      try {
        progress = await api.getCourseProgress(courseId);
      } catch (_) {
        progress = null;
      }
      return {'detail': detail, 'units': units, 'progress': progress};
    });

class CourseDetailActions extends AutoDisposeNotifier<void> {
  @override
  void build() {}

  Future<void> enroll(String courseId) async {
    await ref.read(skillForgeApiProvider).enrollCourse(courseId);
  }
}

final courseDetailActionsProvider =
    AutoDisposeNotifierProvider<CourseDetailActions, void>(
      CourseDetailActions.new,
    );
