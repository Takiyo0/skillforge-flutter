import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skillforgeapp/models/admin/admin_models.dart';
import 'package:skillforgeapp/providers/infrastructure_providers.dart';

class AdminUnitPlaceholderActions extends AutoDisposeNotifier<void> {
  @override
  void build() {}

  Future<AdminUnitDetail> getAdminUnitById(String unitId) {
    return ref.read(skillForgeApiProvider).getAdminUnitById(unitId);
  }

  Future<AdminCourse> getAdminCourse(String courseId) {
    return ref.read(skillForgeApiProvider).getAdminCourse(courseId);
  }

  Future<List<SandboxLanguageSummary>> getSandboxLanguageCatalog({
    bool includeBaseCode = false,
  }) {
    return ref
        .read(skillForgeApiProvider)
        .getSandboxLanguageCatalog(includeBaseCode: includeBaseCode);
  }

  Future<Map<String, dynamic>> updateAdminUnitPatch({
    required String unitId,
    String? title,
    String? type,
    String? summary,
    int? estimatedMinutes,
    int? position,
    bool? isPublished,
  }) {
    return ref
        .read(skillForgeApiProvider)
        .updateAdminUnitPatch(
          unitId: unitId,
          title: title,
          type: type,
          summary: summary,
          estimatedMinutes: estimatedMinutes,
          position: position,
          isPublished: isPublished,
        );
  }

  Future<void> deleteAdminUnit(String unitId) {
    return ref.read(skillForgeApiProvider).deleteAdminUnit(unitId);
  }

  Future<AdminModuleContent?> getAdminModuleContent(String unitId) {
    return ref.read(skillForgeApiProvider).getAdminModuleContent(unitId);
  }

  Future<List<AdminModuleResource>> listAdminModuleResources(String unitId) {
    return ref.read(skillForgeApiProvider).listAdminModuleResources(unitId);
  }

  Future<void> updateAdminModuleContent({
    required String unitId,
    required String contentKind,
    String? videoUrl,
    String? articleMarkdown,
    required List<double> playbackSpeeds,
    required bool supportsPip,
  }) {
    return ref
        .read(skillForgeApiProvider)
        .updateAdminModuleContent(
          unitId: unitId,
          contentKind: contentKind,
          videoUrl: videoUrl,
          articleMarkdown: articleMarkdown,
          playbackSpeeds: playbackSpeeds,
          supportsPip: supportsPip,
        );
  }

  Future<void> createAdminModuleContent({
    required String unitId,
    required String contentKind,
    String? videoUrl,
    String? articleMarkdown,
    required List<double> playbackSpeeds,
    required bool supportsPip,
  }) {
    return ref
        .read(skillForgeApiProvider)
        .createAdminModuleContent(
          unitId: unitId,
          contentKind: contentKind,
          videoUrl: videoUrl,
          articleMarkdown: articleMarkdown,
          playbackSpeeds: playbackSpeeds,
          supportsPip: supportsPip,
        );
  }

  Future<Map<String, dynamic>> uploadAdminModuleVideo({
    required String unitId,
    required String fileName,
    required Uint8List bytes,
    String? contentType,
  }) {
    return ref
        .read(skillForgeApiProvider)
        .uploadAdminModuleVideo(
          unitId: unitId,
          fileName: fileName,
          bytes: bytes,
          contentType: contentType,
        );
  }

  Future<Map<String, dynamic>> uploadAdminModuleResource({
    required String unitId,
    required String fileName,
    required Uint8List bytes,
    required String label,
    required String resourceType,
    String? contentType,
  }) {
    return ref
        .read(skillForgeApiProvider)
        .uploadAdminModuleResource(
          unitId: unitId,
          fileName: fileName,
          bytes: bytes,
          label: label,
          resourceType: resourceType,
          contentType: contentType,
        );
  }

  Future<void> deleteAdminModuleResource(String resourceId) {
    return ref
        .read(skillForgeApiProvider)
        .deleteAdminModuleResource(resourceId);
  }

  Future<void> createAdminExercise({
    required String unitId,
    required String title,
    required String promptMarkdown,
    required String difficulty,
    required String language,
    required String starterCode,
    required int maxCpuMs,
    required int maxMemoryKb,
  }) {
    return ref
        .read(skillForgeApiProvider)
        .createAdminExercise(
          unitId: unitId,
          title: title,
          promptMarkdown: promptMarkdown,
          difficulty: difficulty,
          language: language,
          starterCode: starterCode,
          maxCpuMs: maxCpuMs,
          maxMemoryKb: maxMemoryKb,
        );
  }

  Future<void> updateAdminExercise({
    required String exerciseId,
    required String title,
    required String promptMarkdown,
    required String difficulty,
    required String language,
    required String starterCode,
    required int maxCpuMs,
    required int maxMemoryKb,
  }) {
    return ref
        .read(skillForgeApiProvider)
        .updateAdminExercise(
          exerciseId: exerciseId,
          title: title,
          promptMarkdown: promptMarkdown,
          difficulty: difficulty,
          language: language,
          starterCode: starterCode,
          maxCpuMs: maxCpuMs,
          maxMemoryKb: maxMemoryKb,
        );
  }

  Future<void> deleteAdminExercise(String exerciseId) {
    return ref.read(skillForgeApiProvider).deleteAdminExercise(exerciseId);
  }

  Future<void> addAdminExerciseTestCase({
    required String exerciseId,
    required String inputText,
    required String expectedOutput,
    required bool isHidden,
  }) {
    return ref
        .read(skillForgeApiProvider)
        .addAdminExerciseTestCase(
          exerciseId: exerciseId,
          inputText: inputText,
          expectedOutput: expectedOutput,
          isHidden: isHidden,
        );
  }

  Future<void> updateAdminExerciseTestCase({
    required String testCaseId,
    required String inputText,
    required String expectedOutput,
    required bool isHidden,
  }) {
    return ref
        .read(skillForgeApiProvider)
        .updateAdminExerciseTestCase(
          testCaseId: testCaseId,
          inputText: inputText,
          expectedOutput: expectedOutput,
          isHidden: isHidden,
        );
  }

  Future<void> deleteAdminExerciseTestCase(String testCaseId) {
    return ref
        .read(skillForgeApiProvider)
        .deleteAdminExerciseTestCase(testCaseId);
  }

  Future<void> addAdminExerciseHint({
    required String exerciseId,
    required String content,
    required int requiredFailedAttempts,
  }) {
    return ref
        .read(skillForgeApiProvider)
        .addAdminExerciseHint(
          exerciseId: exerciseId,
          content: content,
          requiredFailedAttempts: requiredFailedAttempts,
        );
  }

  Future<void> updateAdminExerciseHint({
    required String hintId,
    required String content,
    required int requiredFailedAttempts,
  }) {
    return ref
        .read(skillForgeApiProvider)
        .updateAdminExerciseHint(
          hintId: hintId,
          content: content,
          requiredFailedAttempts: requiredFailedAttempts,
        );
  }

  Future<void> deleteAdminExerciseHint(String hintId) {
    return ref.read(skillForgeApiProvider).deleteAdminExerciseHint(hintId);
  }
}

final adminUnitPlaceholderActionsProvider =
    AutoDisposeNotifierProvider<AdminUnitPlaceholderActions, void>(
      AdminUnitPlaceholderActions.new,
    );
