import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skillforgeapp/providers/infrastructure_providers.dart';

typedef UnitKey = ({String courseId, String unitId});

final unitBundleProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, UnitKey>((ref, input) async {
      final api = ref.read(skillForgeApiProvider);
      final unit = await api.getUnitDetail(input.unitId);
      var progress = await api.getCourseProgress(input.courseId);

      final unitProgressItems =
          (progress['unitProgress'] as List?)
              ?.whereType<Map>()
              .map((e) => e.cast<String, dynamic>())
              .toList() ??
          const <Map<String, dynamic>>[];
      final selfProgress = unitProgressItems.where(
        (p) => (p['unitId'] ?? '').toString() == input.unitId,
      );
      final status = selfProgress.isNotEmpty
          ? (selfProgress.first['status'] ?? '').toString()
          : 'locked';

      if (status == 'available') {
        await api.startUnit(input.unitId);
        progress = await api.getCourseProgress(input.courseId);
      }

      final unitType = (unit['type'] ?? '').toString();
      final submissions = unitType == 'exercise'
          ? await api.getUserUnitSubmissions(input.unitId)
          : const <dynamic>[];

      return {'unit': unit, 'progress': progress, 'submissions': submissions};
    });

class UnitViewActions extends AutoDisposeFamilyNotifier<void, UnitKey> {
  @override
  void build(UnitKey arg) {}

  Future<void> refreshBundle() async {
    ref.invalidate(unitBundleProvider(arg));
  }

  Future<void> completeUnit() async {
    await ref.read(skillForgeApiProvider).completeUnit(arg.unitId);
    await refreshBundle();
  }

  Future<Map<String, dynamic>> submitExerciseCode({
    required String exerciseId,
    required String sourceCode,
    required String language,
    required String difficulty,
  }) async {
    final api = ref.read(skillForgeApiProvider);
    final result = difficulty == 'advanced'
        ? await api.submitAdvancedExerciseCode(
            unitId: arg.unitId,
            exerciseId: exerciseId,
            sourceCode: sourceCode,
            language: language,
          )
        : await api.submitExerciseCode(
            unitId: arg.unitId,
            exerciseId: exerciseId,
            sourceCode: sourceCode,
            language: language,
          );
    return result;
  }

  Future<Map<String, dynamic>> getSubmissionStatus(String submissionId) {
    return ref.read(skillForgeApiProvider).getSubmissionStatus(submissionId);
  }

  Future<Map<String, dynamic>> askAiSubmissionExplanation(String submissionId) {
    return ref
        .read(skillForgeApiProvider)
        .askAiSubmissionExplanation(submissionId);
  }
}

final unitViewActionsProvider =
    AutoDisposeNotifierProviderFamily<UnitViewActions, void, UnitKey>(
      UnitViewActions.new,
    );
