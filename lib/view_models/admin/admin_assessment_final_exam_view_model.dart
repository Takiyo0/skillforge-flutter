import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skillforgeapp/providers/infrastructure_providers.dart';

class AdminAssessmentFinalExamActions extends AutoDisposeNotifier<void> {
  @override
  void build() {}

  Future<void> createQuiz({
    required String unitId,
    required String title,
    required String instructions,
    required int passingScore,
    required int timeLimitSeconds,
    required bool randomizeQuestions,
    required bool randomizeOptions,
  }) {
    return ref
        .read(skillForgeApiProvider)
        .createAdminQuiz(
          unitId: unitId,
          title: title,
          instructions: instructions,
          passingScore: passingScore,
          timeLimitSeconds: timeLimitSeconds,
          randomizeQuestions: randomizeQuestions,
          randomizeOptions: randomizeOptions,
        );
  }

  Future<void> updateQuiz({
    required String quizId,
    required String title,
    required String instructions,
    required int passingScore,
    required int timeLimitSeconds,
    required bool randomizeQuestions,
    required bool randomizeOptions,
  }) {
    return ref
        .read(skillForgeApiProvider)
        .updateAdminQuiz(
          quizId: quizId,
          title: title,
          instructions: instructions,
          passingScore: passingScore,
          timeLimitSeconds: timeLimitSeconds,
          randomizeQuestions: randomizeQuestions,
          randomizeOptions: randomizeOptions,
        );
  }

  Future<void> deleteQuiz(String quizId) {
    return ref.read(skillForgeApiProvider).deleteAdminQuiz(quizId);
  }

  Future<void> addQuizQuestion({
    required String quizId,
    required String prompt,
    required int points,
    required String explanation,
    required List<Map<String, dynamic>> options,
  }) {
    return ref
        .read(skillForgeApiProvider)
        .addAdminQuizQuestion(
          quizId: quizId,
          prompt: prompt,
          points: points,
          explanation: explanation,
          options: options,
        );
  }

  Future<void> updateQuizQuestion({
    required String questionId,
    required String prompt,
    required int points,
    required String explanation,
  }) {
    return ref
        .read(skillForgeApiProvider)
        .updateAdminQuizQuestion(
          questionId: questionId,
          prompt: prompt,
          points: points,
          explanation: explanation,
        );
  }

  Future<void> deleteQuizQuestion(String questionId) {
    return ref.read(skillForgeApiProvider).deleteAdminQuizQuestion(questionId);
  }

  Future<void> createQuizOption({
    required String questionId,
    required String label,
    required bool isCorrect,
  }) {
    return ref
        .read(skillForgeApiProvider)
        .createAdminQuizOption(
          questionId: questionId,
          label: label,
          isCorrect: isCorrect,
        );
  }

  Future<void> updateQuizOption({
    required String optionId,
    required String label,
    required bool isCorrect,
  }) {
    return ref
        .read(skillForgeApiProvider)
        .updateAdminQuizOption(
          optionId: optionId,
          label: label,
          isCorrect: isCorrect,
        );
  }

  Future<void> deleteQuizOption(String optionId) {
    return ref.read(skillForgeApiProvider).deleteAdminQuizOption(optionId);
  }

  Future<void> addFinalExamQuestion({
    required String unitId,
    required String prompt,
    required int points,
    required String explanation,
    required List<Map<String, dynamic>> options,
  }) {
    return ref
        .read(skillForgeApiProvider)
        .createAdminFinalExamQuestion(
          unitId: unitId,
          prompt: prompt,
          points: points,
          explanation: explanation,
          options: options,
        );
  }

  Future<void> updateFinalExamQuestion({
    required String unitId,
    required String questionId,
    required String prompt,
    required int points,
    required String explanation,
  }) {
    return ref
        .read(skillForgeApiProvider)
        .updateAdminFinalExamQuestion(
          unitId: unitId,
          questionId: questionId,
          prompt: prompt,
          points: points,
          explanation: explanation,
        );
  }

  Future<void> deleteFinalExamQuestion({
    required String unitId,
    required String questionId,
  }) {
    return ref
        .read(skillForgeApiProvider)
        .deleteAdminFinalExamQuestion(unitId: unitId, questionId: questionId);
  }

  Future<void> createFinalExamOption({
    required String unitId,
    required String questionId,
    required String label,
    required bool isCorrect,
  }) {
    return ref
        .read(skillForgeApiProvider)
        .createAdminFinalExamOption(
          unitId: unitId,
          questionId: questionId,
          label: label,
          isCorrect: isCorrect,
        );
  }

  Future<void> updateFinalExamOption({
    required String unitId,
    required String questionId,
    required String optionId,
    required String label,
    required bool isCorrect,
  }) {
    return ref
        .read(skillForgeApiProvider)
        .updateAdminFinalExamOption(
          unitId: unitId,
          questionId: questionId,
          optionId: optionId,
          label: label,
          isCorrect: isCorrect,
        );
  }

  Future<void> deleteFinalExamOption({
    required String unitId,
    required String questionId,
    required String optionId,
  }) {
    return ref
        .read(skillForgeApiProvider)
        .deleteAdminFinalExamOption(
          unitId: unitId,
          questionId: questionId,
          optionId: optionId,
        );
  }

  Future<void> createAdminQuiz({
    required String unitId,
    required String title,
    required String instructions,
    required int passingScore,
    required int timeLimitSeconds,
    required bool randomizeQuestions,
    required bool randomizeOptions,
  }) => createQuiz(
    unitId: unitId,
    title: title,
    instructions: instructions,
    passingScore: passingScore,
    timeLimitSeconds: timeLimitSeconds,
    randomizeQuestions: randomizeQuestions,
    randomizeOptions: randomizeOptions,
  );

  Future<void> updateAdminQuiz({
    required String quizId,
    required String title,
    required String instructions,
    required int passingScore,
    required int timeLimitSeconds,
    required bool randomizeQuestions,
    required bool randomizeOptions,
  }) => updateQuiz(
    quizId: quizId,
    title: title,
    instructions: instructions,
    passingScore: passingScore,
    timeLimitSeconds: timeLimitSeconds,
    randomizeQuestions: randomizeQuestions,
    randomizeOptions: randomizeOptions,
  );

  Future<void> deleteAdminQuiz(String quizId) => deleteQuiz(quizId);

  Future<void> addAdminQuizQuestion({
    required String quizId,
    required String prompt,
    required int points,
    required String explanation,
    required List<Map<String, dynamic>> options,
  }) => addQuizQuestion(
    quizId: quizId,
    prompt: prompt,
    points: points,
    explanation: explanation,
    options: options,
  );

  Future<void> updateAdminQuizQuestion({
    required String questionId,
    required String prompt,
    required int points,
    required String explanation,
  }) => updateQuizQuestion(
    questionId: questionId,
    prompt: prompt,
    points: points,
    explanation: explanation,
  );

  Future<void> deleteAdminQuizQuestion(String questionId) =>
      deleteQuizQuestion(questionId);

  Future<void> createAdminQuizOption({
    required String questionId,
    required String label,
    required bool isCorrect,
  }) => createQuizOption(
    questionId: questionId,
    label: label,
    isCorrect: isCorrect,
  );

  Future<void> updateAdminQuizOption({
    required String optionId,
    required String label,
    required bool isCorrect,
  }) =>
      updateQuizOption(optionId: optionId, label: label, isCorrect: isCorrect);

  Future<void> deleteAdminQuizOption(String optionId) =>
      deleteQuizOption(optionId);

  Future<void> addAdminFinalExamQuestion({
    required String unitId,
    required String prompt,
    required int points,
    required String explanation,
    required List<Map<String, dynamic>> options,
  }) => addFinalExamQuestion(
    unitId: unitId,
    prompt: prompt,
    points: points,
    explanation: explanation,
    options: options,
  );

  Future<void> createAdminFinalExamQuestion({
    required String unitId,
    required String prompt,
    required int points,
    required String explanation,
    required List<Map<String, dynamic>> options,
  }) => addFinalExamQuestion(
    unitId: unitId,
    prompt: prompt,
    points: points,
    explanation: explanation,
    options: options,
  );

  Future<void> updateAdminFinalExamQuestion({
    required String unitId,
    required String questionId,
    required String prompt,
    required int points,
    required String explanation,
  }) => updateFinalExamQuestion(
    unitId: unitId,
    questionId: questionId,
    prompt: prompt,
    points: points,
    explanation: explanation,
  );

  Future<void> deleteAdminFinalExamQuestion({
    required String unitId,
    required String questionId,
  }) => deleteFinalExamQuestion(unitId: unitId, questionId: questionId);

  Future<void> createAdminFinalExamOption({
    required String unitId,
    required String questionId,
    required String label,
    required bool isCorrect,
  }) => createFinalExamOption(
    unitId: unitId,
    questionId: questionId,
    label: label,
    isCorrect: isCorrect,
  );

  Future<void> updateAdminFinalExamOption({
    required String unitId,
    required String questionId,
    required String optionId,
    required String label,
    required bool isCorrect,
  }) => updateFinalExamOption(
    unitId: unitId,
    questionId: questionId,
    optionId: optionId,
    label: label,
    isCorrect: isCorrect,
  );

  Future<void> deleteAdminFinalExamOption({
    required String unitId,
    required String questionId,
    required String optionId,
  }) => deleteFinalExamOption(
    unitId: unitId,
    questionId: questionId,
    optionId: optionId,
  );
}

final adminAssessmentFinalExamActionsProvider =
    AutoDisposeNotifierProvider<AdminAssessmentFinalExamActions, void>(
      AdminAssessmentFinalExamActions.new,
    );
