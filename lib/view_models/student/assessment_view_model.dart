import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skillforgeapp/providers/infrastructure_providers.dart';

final assessmentViewModelProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, ({String courseId, String unitId})>((
      ref,
      input,
    ) async {
      final api = ref.read(skillForgeApiProvider);
      final unit = await api.getUnitDetail(input.unitId);
      final progress = await api.getCourseProgress(input.courseId);
      final unitProgress = ((progress['unitProgress'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .where((p) => (p['unitId'] ?? '').toString() == input.unitId)
          .toList();
      final status = unitProgress.isNotEmpty
          ? (unitProgress.first['status'] ?? '').toString()
          : 'locked';
      if (status == 'completed') {
        return {
          'unit': unit,
          'questions': const <dynamic>[],
          'blockedCompleted': true,
        };
      }
      final type = (unit['type'] ?? '').toString();

      if (type == 'final_exam') {
        final finalExam =
            (unit['finalExam'] ??
                    unit['final_exam'] ??
                    const <String, dynamic>{})
                as Map;
        final finalExamId = (finalExam['unitId'] ?? finalExam['id'] ?? '')
            .toString();
        final attempt = await api.startFinalExamAttempt(
          unitId: input.unitId,
          finalExamId: finalExamId,
        );
        return {
          'unit': unit,
          'questions': (attempt['questions'] as List?) ?? const <dynamic>[],
          'finalExamId': finalExamId,
        };
      }

      final quiz = (unit['quiz'] is Map<String, dynamic>)
          ? unit['quiz'] as Map<String, dynamic>
          : const <String, dynamic>{};
      return {
        'unit': unit,
        'questions': (quiz['questions'] as List?) ?? const <dynamic>[],
        'quizId': (quiz['id'] ?? '').toString(),
      };
    });

class AssessmentActions extends AutoDisposeNotifier<void> {
  @override
  void build() {}

  Future<Map<String, dynamic>> submit({
    required String unitType,
    required String unitId,
    required String quizId,
    required String finalExamId,
    required List<Map<String, dynamic>> answers,
  }) async {
    final api = ref.read(skillForgeApiProvider);
    if (unitType == 'final_exam') {
      return api.submitFinalExam(
        unitId: unitId,
        finalExamId: finalExamId,
        answers: answers,
      );
    }
    return api.submitQuiz(unitId: unitId, quizId: quizId, answers: answers);
  }
}

final assessmentActionsProvider =
    AutoDisposeNotifierProvider<AssessmentActions, void>(AssessmentActions.new);
