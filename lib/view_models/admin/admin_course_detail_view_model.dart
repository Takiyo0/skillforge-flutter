import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skillforgeapp/models/admin/admin_models.dart';
import 'package:skillforgeapp/providers/infrastructure_providers.dart';

class AdminCourseDetailState {
  const AdminCourseDetailState({
    this.course,
    this.languages = const [],
    this.loading = true,
    this.busy = false,
    this.error,
  });

  final AdminCourse? course;
  final List<SandboxLanguageSummary> languages;
  final bool loading;
  final bool busy;
  final String? error;

  AdminCourseDetailState copyWith({
    AdminCourse? course,
    List<SandboxLanguageSummary>? languages,
    bool? loading,
    bool? busy,
    String? error,
    bool clearError = false,
  }) {
    return AdminCourseDetailState(
      course: course ?? this.course,
      languages: languages ?? this.languages,
      loading: loading ?? this.loading,
      busy: busy ?? this.busy,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AdminCourseDetailViewModel
    extends AutoDisposeFamilyNotifier<AdminCourseDetailState, String> {
  @override
  AdminCourseDetailState build(String arg) {
    Future.microtask(_load);
    return const AdminCourseDetailState();
  }

  Future<void> _load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final repo = ref.read(skillForgeApiProvider);
      final course = await repo.getAdminCourse(arg);
      final languages = await repo.getSandboxLanguageCatalog();
      state = state.copyWith(
        loading: false,
        course: course.copyWith(
          units: course.units,
          unitCount: course.units.length,
        ),
        languages: languages,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: 'Failed to load course: ${e.toString()}',
      );
    }
  }

  Future<void> reload() => _load();

  Future<void> refreshUnitsOnly() async {
    final current = state.course;
    if (current == null) return;
    final course = await ref.read(skillForgeApiProvider).getAdminCourse(arg);
    state = state.copyWith(
      course: current.copyWith(
        units: course.units,
        unitCount: course.units.length,
      ),
    );
  }

  Future<void> updateCourse({
    required AdminCourse baseCourse,
    required String title,
    required String subtitle,
    required String description,
    required String level,
    required String language,
    required int priceCents,
    required String currencyCode,
    required String trailerUrl,
    Uint8List? thumbnailBytes,
    String? thumbnailName,
    required String Function(String fileName) imageMimeType,
  }) async {
    state = state.copyWith(busy: true);
    try {
      final repo = ref.read(skillForgeApiProvider);
      var updated = baseCourse.applyPatch(
        await repo.updateAdminCoursePatch(
          courseId: baseCourse.id,
          title: title,
          subtitle: subtitle,
          description: description,
          level: level,
          language: language,
          priceCents: priceCents,
          currencyCode: currencyCode,
          trailerUrl: trailerUrl,
        ),
      );
      if (thumbnailBytes != null && thumbnailName != null) {
        updated = await repo.uploadAdminCourseThumbnail(
          courseId: baseCourse.id,
          fileName: thumbnailName,
          bytes: thumbnailBytes,
          contentType: imageMimeType(thumbnailName),
        );
      }
      state = state.copyWith(course: updated, busy: false);
      await refreshUnitsOnly();
    } catch (e) {
      state = state.copyWith(busy: false);
      rethrow;
    }
  }

  Future<void> toggleCoursePublish(AdminCourse course) async {
    state = state.copyWith(busy: true);
    try {
      final repo = ref.read(skillForgeApiProvider);
      if (course.isPublished) {
        await repo.unpublishAdminCourse(course.id);
      } else {
        await repo.publishAdminCourse(course.id);
      }
      state = state.copyWith(
        course: course.copyWith(isPublished: !course.isPublished),
        busy: false,
      );
    } catch (_) {
      state = state.copyWith(busy: false);
      rethrow;
    }
  }

  Future<void> deleteCourse(String courseId) async {
    state = state.copyWith(busy: true);
    try {
      await ref.read(skillForgeApiProvider).deleteAdminCourse(courseId);
      state = state.copyWith(busy: false);
    } catch (_) {
      state = state.copyWith(busy: false);
      rethrow;
    }
  }

  Future<void> createUnit({
    required String title,
    required String type,
    required String summary,
    required int estimatedMinutes,
  }) async {
    state = state.copyWith(busy: true);
    try {
      await ref
          .read(skillForgeApiProvider)
          .createAdminUnit(
            courseId: arg,
            title: title,
            type: type,
            summary: summary,
            estimatedMinutes: estimatedMinutes,
          );
      await _load();
      state = state.copyWith(busy: false);
    } catch (_) {
      state = state.copyWith(busy: false);
      rethrow;
    }
  }

  Future<void> updateUnit({
    required AdminUnitPreview unit,
    required String title,
    required String type,
    required String summary,
    required int estimatedMinutes,
  }) async {
    state = state.copyWith(busy: true);
    try {
      final patch = await ref
          .read(skillForgeApiProvider)
          .updateAdminUnitPatch(
            unitId: unit.id,
            title: title,
            type: type,
            summary: summary,
            estimatedMinutes: estimatedMinutes,
          );
      final current = state.course;
      if (current != null) {
        final updatedUnits = current.units
            .map((item) => item.id == unit.id ? item.applyPatch(patch) : item)
            .toList();
        state = state.copyWith(
          course: current.copyWith(
            units: updatedUnits,
            unitCount: updatedUnits.length,
          ),
        );
      }
      state = state.copyWith(busy: false);
    } catch (_) {
      state = state.copyWith(busy: false);
      rethrow;
    }
  }

  Future<void> deleteUnit(String unitId) async {
    state = state.copyWith(busy: true);
    try {
      await ref.read(skillForgeApiProvider).deleteAdminUnit(unitId);
      await _load();
      state = state.copyWith(busy: false);
    } catch (_) {
      state = state.copyWith(busy: false);
      rethrow;
    }
  }

  Future<void> toggleUnitPublish(AdminUnitPreview unit) async {
    state = state.copyWith(busy: true);
    try {
      final patch = await ref
          .read(skillForgeApiProvider)
          .updateAdminUnitPatch(
            unitId: unit.id,
            isPublished: !unit.isPublished,
          );
      final current = state.course;
      if (current != null) {
        final updatedUnits = current.units
            .map((item) => item.id == unit.id ? item.applyPatch(patch) : item)
            .toList();
        state = state.copyWith(course: current.copyWith(units: updatedUnits));
      }
      state = state.copyWith(busy: false);
    } catch (_) {
      state = state.copyWith(busy: false);
      rethrow;
    }
  }

  Future<void> reorderUnits({
    required List<AdminUnitPreview> originalUnits,
    required int oldIndex,
    required int newIndex,
  }) async {
    final adjustedNewIndex = oldIndex < newIndex ? newIndex - 1 : newIndex;
    final reordered = [...originalUnits];
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(adjustedNewIndex, moved);
    final normalized = [
      for (var i = 0; i < reordered.length; i++)
        reordered[i].copyWith(position: i + 1),
    ];
    final course = state.course;
    if (course != null) {
      state = state.copyWith(
        busy: true,
        course: course.copyWith(units: normalized),
      );
    } else {
      state = state.copyWith(busy: true);
    }
    try {
      for (final unit in normalized) {
        final original = originalUnits.firstWhere((item) => item.id == unit.id);
        if (original.position != unit.position) {
          await ref
              .read(skillForgeApiProvider)
              .updateAdminUnitPatch(unitId: unit.id, position: unit.position);
        }
      }
      await refreshUnitsOnly();
      state = state.copyWith(busy: false);
    } catch (_) {
      if (course != null) {
        state = state.copyWith(
          course: course.copyWith(units: originalUnits),
          busy: false,
        );
      } else {
        state = state.copyWith(busy: false);
      }
      rethrow;
    }
  }

  Future<void> addPrerequisite({
    required String unitId,
    required String prerequisiteUnitId,
  }) async {
    await ref
        .read(skillForgeApiProvider)
        .addAdminUnitPrerequisite(
          unitId: unitId,
          prerequisiteUnitId: prerequisiteUnitId,
        );
    await _load();
  }

  Future<void> removePrerequisite({
    required String unitId,
    required String prerequisiteUnitId,
  }) async {
    await ref
        .read(skillForgeApiProvider)
        .removeAdminUnitPrerequisite(
          unitId: unitId,
          prerequisiteUnitId: prerequisiteUnitId,
        );
    await _load();
  }
}

final adminCourseDetailViewModelProvider =
    AutoDisposeNotifierProviderFamily<
      AdminCourseDetailViewModel,
      AdminCourseDetailState,
      String
    >(AdminCourseDetailViewModel.new);
