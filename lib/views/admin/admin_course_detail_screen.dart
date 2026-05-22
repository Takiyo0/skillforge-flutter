import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skillforgeapp/config/asset_urls.dart';
import 'package:skillforgeapp/models/admin/admin_models.dart';
import 'package:skillforgeapp/ui/design_system.dart';
import 'package:skillforgeapp/view_models/admin/admin_course_detail_view_model.dart';
import 'package:skillforgeapp/widgets/shared/app_confirm_dialog.dart';
import 'package:skillforgeapp/widgets/shared/app_status_badge.dart';

class AdminCourseDetailPage extends ConsumerStatefulWidget {
  const AdminCourseDetailPage({super.key, required this.courseId});

  final String courseId;

  @override
  ConsumerState<AdminCourseDetailPage> createState() =>
      _AdminCourseDetailPageState();
}

class _AdminCourseDetailPageState extends ConsumerState<AdminCourseDetailPage> {
  @override
  void initState() {
    super.initState();
  }

  void _toast(String message) {
    AppToast.show(context, message);
  }

  Future<void> _openEditCourseDialog() async {
    final vmState = ref.read(
      adminCourseDetailViewModelProvider(widget.courseId),
    );
    final course = vmState.course;
    if (course == null) return;
    final result = await showAppDialog<_CourseEditResult>(
      context: context,
      useRootNavigator: true,
      builder: (context) =>
          _CourseEditDialog(course: course, languages: vmState.languages),
    );
    if (result == null) return;

    try {
      await ref
          .read(adminCourseDetailViewModelProvider(widget.courseId).notifier)
          .updateCourse(
            baseCourse: course,
            title: result.title,
            subtitle: result.subtitle,
            description: result.description,
            level: result.level,
            language: result.language,
            priceCents: result.priceCents,
            currencyCode: result.currencyCode,
            trailerUrl: result.trailerUrl,
            thumbnailBytes: result.thumbnailBytes,
            thumbnailName: result.thumbnailName,
            imageMimeType: _imageMimeType,
          );
      if (!mounted) return;
      _toast('Course updated');
    } catch (e) {
      _toast('Failed to update course: ${AppToast.errorMessage(e)}');
    }
  }

  Future<void> _toggleCoursePublish() async {
    final course = ref
        .read(adminCourseDetailViewModelProvider(widget.courseId))
        .course;
    if (course == null) return;
    try {
      await ref
          .read(adminCourseDetailViewModelProvider(widget.courseId).notifier)
          .toggleCoursePublish(course);
      _toast(course.isPublished ? 'Course unpublished' : 'Course published');
    } catch (e) {
      _toast('Failed to update course status: ${AppToast.errorMessage(e)}');
    }
  }

  Future<void> _deleteCourse() async {
    final course = ref
        .read(adminCourseDetailViewModelProvider(widget.courseId))
        .course;
    if (course == null) return;
    final confirm = await showAppConfirmDialog(
      context,
      title: 'Delete Course',
      message: 'Delete "${course.title}"? This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirm) return;
    try {
      await ref
          .read(adminCourseDetailViewModelProvider(widget.courseId).notifier)
          .deleteCourse(course.id);
      if (!mounted) return;
      _toast('Course deleted');
      context.go('/admin/courses');
    } catch (e) {
      _toast('Failed to delete course: ${AppToast.errorMessage(e)}');
    }
  }

  Future<void> _openCreateUnitDialog() async {
    final result = await showAppDialog<_UnitFormResult>(
      context: context,
      useRootNavigator: true,
      builder: (context) => const _UnitFormDialog(title: 'Create Unit'),
    );
    if (result == null) return;
    try {
      await ref
          .read(adminCourseDetailViewModelProvider(widget.courseId).notifier)
          .createUnit(
            title: result.title,
            type: result.type,
            summary: result.summary,
            estimatedMinutes: result.estimatedMinutes,
          );
      _toast('Unit created');
    } catch (e) {
      _toast('Failed to create unit: ${AppToast.errorMessage(e)}');
    }
  }

  Future<void> _openEditUnitDialog(AdminUnitPreview unit) async {
    final result = await showAppDialog<_UnitFormResult>(
      context: context,
      useRootNavigator: true,
      builder: (context) => _UnitFormDialog(title: 'Edit Unit', initial: unit),
    );
    if (result == null) return;
    try {
      await ref
          .read(adminCourseDetailViewModelProvider(widget.courseId).notifier)
          .updateUnit(
            unit: unit,
            title: result.title,
            type: result.type,
            summary: result.summary,
            estimatedMinutes: result.estimatedMinutes,
          );
      _toast('Unit updated');
    } catch (e) {
      _toast('Failed to update unit: ${AppToast.errorMessage(e)}');
    }
  }

  Future<void> _deleteUnit(AdminUnitPreview unit) async {
    final confirm = await showAppConfirmDialog(
      context,
      title: 'Delete Unit',
      message: 'Delete "${unit.title}"? This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirm) return;
    try {
      await ref
          .read(adminCourseDetailViewModelProvider(widget.courseId).notifier)
          .deleteUnit(unit.id);
      _toast('Unit deleted');
    } catch (e) {
      _toast('Failed to delete unit: ${AppToast.errorMessage(e)}');
    }
  }

  Future<void> _toggleUnitPublish(AdminUnitPreview unit) async {
    try {
      await ref
          .read(adminCourseDetailViewModelProvider(widget.courseId).notifier)
          .toggleUnitPublish(unit);
      _toast(unit.isPublished ? 'Unit unpublished' : 'Unit published');
    } catch (e) {
      _toast('Failed to update unit status: ${AppToast.errorMessage(e)}');
    }
  }

  Future<void> _handleReorder(int oldIndex, int newIndex) async {
    final course = ref
        .read(adminCourseDetailViewModelProvider(widget.courseId))
        .course;
    if (course == null) return;
    try {
      await ref
          .read(adminCourseDetailViewModelProvider(widget.courseId).notifier)
          .reorderUnits(
            originalUnits: course.units,
            oldIndex: oldIndex,
            newIndex: newIndex,
          );
      _toast('Unit order updated');
    } catch (e) {
      _toast('Failed to reorder units: ${AppToast.errorMessage(e)}');
    }
  }

  Future<void> _openPrerequisitesDialog(AdminUnitPreview unit) async {
    final course = ref
        .read(adminCourseDetailViewModelProvider(widget.courseId))
        .course;
    if (course == null) return;
    await showAppDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (context) => _PrerequisitesDialog(
        unit: unit,
        availableUnits: course.units
            .where((item) => item.id != unit.id)
            .toList(),
        onAdd: (prerequisiteId) async {
          await ref
              .read(
                adminCourseDetailViewModelProvider(widget.courseId).notifier,
              )
              .addPrerequisite(
                unitId: unit.id,
                prerequisiteUnitId: prerequisiteId,
              );
        },
        onRemove: (prerequisiteId) async {
          await ref
              .read(
                adminCourseDetailViewModelProvider(widget.courseId).notifier,
              )
              .removePrerequisite(
                unitId: unit.id,
                prerequisiteUnitId: prerequisiteId,
              );
        },
      ),
    );
  }

  void _openUnitDetail(AdminUnitPreview unit) {
    context.push('/admin/courses/${widget.courseId}/${unit.id}');
  }

  Future<void> _openUnitActions(AdminUnitPreview unit) async {
    await showAppBottomSheet<void>(
      context: context,
      initialChildSize: 0.46,
      minChildSize: 0.32,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(unit.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              '${_unitTypeLabel(unit.type)} • ${unit.estimatedMinutes} min',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _ActionSheetTile(
              icon: Icons.open_in_new_rounded,
              label: 'Open Unit',
              onTap: () {
                Navigator.of(context).pop();
                _openUnitDetail(unit);
              },
            ),
            _ActionSheetTile(
              icon: Icons.edit_outlined,
              label: 'Edit Unit',
              onTap: () {
                Navigator.of(context).pop();
                _openEditUnitDialog(unit);
              },
            ),
            _ActionSheetTile(
              icon: unit.isPublished
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              label: unit.isPublished ? 'Unpublish Unit' : 'Publish Unit',
              onTap: () {
                Navigator.of(context).pop();
                _toggleUnitPublish(unit);
              },
            ),
            _ActionSheetTile(
              icon: Icons.link_outlined,
              label: 'Manage Prerequisites',
              onTap: () {
                Navigator.of(context).pop();
                _openPrerequisitesDialog(unit);
              },
            ),
            _ActionSheetTile(
              icon: Icons.delete_outline,
              label: 'Delete Unit',
              destructive: true,
              onTap: () {
                Navigator.of(context).pop();
                _deleteUnit(unit);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vmState = ref.watch(
      adminCourseDetailViewModelProvider(widget.courseId),
    );
    final course = vmState.course;
    final busy = vmState.busy;
    final thumbUrl = AssetUrls.courseThumbnailUrl(course?.thumbnailS3Key);

    return AppPage(
      title: course == null ? 'Course Detail' : course.title,
      subtitle: 'Course details and unit list',
      child: vmState.loading
          ? AppAsyncState.loading()
          : vmState.error != null
          ? AppAsyncState.error(vmState.error!)
          : course == null
          ? AppAsyncState.error('Course not found')
          : ListView(
              children: [
                GlassPanel(
                  radius: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (thumbUrl != null) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            thumbUrl,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  course.title,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 4),
                                Text(course.subtitle),
                              ],
                            ),
                          ),
                          Chip(
                            label: Text(
                              course.isPublished ? 'Published' : 'Draft',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(course.description),
                      const SizedBox(height: 8),
                      Text(
                        '${course.creator.displayName} • ${course.level} • ${course.language} • '
                        '${(course.priceCents / 100).toStringAsFixed(2)} ${course.currencyCode} • '
                        '${course.units.length} units',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: busy ? null : _openCreateUnitDialog,
                              icon: const Icon(Icons.add),
                              label: const Text('Create Unit'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          PopupMenuButton<_CourseHeaderAction>(
                            enabled: !busy,
                            useRootNavigator: true,
                            onSelected: (action) {
                              switch (action) {
                                case _CourseHeaderAction.edit:
                                  _openEditCourseDialog();
                                  return;
                                case _CourseHeaderAction.publishToggle:
                                  _toggleCoursePublish();
                                  return;
                                case _CourseHeaderAction.delete:
                                  _deleteCourse();
                                  return;
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: _CourseHeaderAction.edit,
                                child: Text('Edit Course'),
                              ),
                              PopupMenuItem(
                                value: _CourseHeaderAction.publishToggle,
                                child: Text(
                                  course.isPublished
                                      ? 'Unpublish Course'
                                      : 'Publish Course',
                                ),
                              ),
                              const PopupMenuItem(
                                value: _CourseHeaderAction.delete,
                                child: Text('Delete Course'),
                              ),
                            ],
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.more_horiz),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                GlassPanel(
                  radius: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manage Units - ${course.title}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text('${course.units.length} unit(s) in this course'),
                      const SizedBox(height: 12),
                      if (course.units.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: Text('No units yet')),
                        )
                      else
                        ReorderableListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          buildDefaultDragHandles: false,
                          onReorder: (oldIndex, newIndex) {
                            if (busy) return;
                            _handleReorder(oldIndex, newIndex);
                          },
                          itemCount: course.units.length,
                          itemBuilder: (context, index) {
                            final unit = course.units[index];
                            return _UnitRow(
                              key: ValueKey(unit.id),
                              unit: unit,
                              disabled: busy,
                              onOpen: () => _openUnitDetail(unit),
                              onMore: () => _openUnitActions(unit),
                              dragHandle: ReorderableDragStartListener(
                                index: index,
                                child: const Icon(Icons.drag_indicator),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _UnitRow extends StatelessWidget {
  const _UnitRow({
    super.key,
    required this.unit,
    required this.disabled,
    required this.onOpen,
    required this.onMore,
    required this.dragHandle,
  });

  final AdminUnitPreview unit;
  final bool disabled;
  final VoidCallback onOpen;
  final VoidCallback onMore;
  final Widget dragHandle;

  @override
  Widget build(BuildContext context) {
    final prerequisiteSummary = unit.prerequisites.isEmpty
        ? 'No prerequisites'
        : unit.prerequisites.length == 1
        ? 'Requires ${unit.prerequisites.first.title}'
        : 'Requires ${unit.prerequisites.first.title} +${unit.prerequisites.length - 1} more';

    return Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: dragHandle,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              unit.title,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(width: 8),
                          AppStatusBadge(
                            label: unit.isPublished ? 'Published' : 'Draft',
                            color: unit.isPublished
                                ? Colors.green
                                : Colors.amber,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _unitTypeLabel(unit.type),
                        // '${_unitTypeLabel(unit.type)} • ${unit.estimatedMinutes} min • Position ${unit.position}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        prerequisiteSummary,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    IconButton(
                      onPressed: disabled ? null : onMore,
                      icon: const Icon(Icons.more_horiz),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _CourseHeaderAction { edit, publishToggle, delete }

class _ActionSheetTile extends StatelessWidget {
  const _ActionSheetTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? Colors.red : null;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: color == null
            ? null
            : TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
      onTap: onTap,
    );
  }
}

class _CourseEditResult {
  const _CourseEditResult({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.level,
    required this.language,
    required this.priceCents,
    required this.currencyCode,
    required this.trailerUrl,
    this.thumbnailBytes,
    this.thumbnailName,
  });

  final String title;
  final String subtitle;
  final String description;
  final String level;
  final String language;
  final int priceCents;
  final String currencyCode;
  final String trailerUrl;
  final Uint8List? thumbnailBytes;
  final String? thumbnailName;
}

class _CourseEditDialog extends StatefulWidget {
  const _CourseEditDialog({required this.course, required this.languages});

  final AdminCourse course;
  final List<SandboxLanguageSummary> languages;

  @override
  State<_CourseEditDialog> createState() => _CourseEditDialogState();
}

class _CourseEditDialogState extends State<_CourseEditDialog> {
  static const _levels = ['beginner', 'intermediate', 'advanced'];
  static const _currencies = ['IDR', 'USD', 'EUR', 'GBP', 'JPY', 'CNY'];

  late final TextEditingController _title;
  late final TextEditingController _subtitle;
  late final TextEditingController _description;
  late final TextEditingController _priceCents;
  late final TextEditingController _trailerUrl;
  late String _level;
  late String _language;
  late String _currency;
  Uint8List? _thumbnailBytes;
  String? _thumbnailName;
  bool _submitted = false;
  String? _previewUrl;

  @override
  void initState() {
    super.initState();
    final course = widget.course;
    _title = TextEditingController(text: course.title);
    _subtitle = TextEditingController(text: course.subtitle);
    _description = TextEditingController(text: course.description);
    _priceCents = TextEditingController(text: course.priceCents.toString());
    _trailerUrl = TextEditingController(text: course.trailerUrl ?? '');
    _level = course.level;
    _language = course.language;
    _currency = course.currencyCode;
    _previewUrl = AssetUrls.courseThumbnailUrl(course.thumbnailS3Key);
  }

  @override
  void dispose() {
    _title.dispose();
    _subtitle.dispose();
    _description.dispose();
    _priceCents.dispose();
    _trailerUrl.dispose();
    super.dispose();
  }

  Future<void> _pickThumbnail() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final file = result?.files.single;
    if (file?.bytes == null || file?.name == null) return;
    setState(() {
      _thumbnailBytes = file!.bytes;
      _thumbnailName = file.name;
      _previewUrl = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final titleText = _title.text.trim();
    final subtitleText = _subtitle.text.trim();
    final descriptionText = _description.text.trim();
    final parsedPrice = int.tryParse(_priceCents.text.trim());

    final previewImage = _thumbnailBytes != null
        ? Image.memory(_thumbnailBytes!, fit: BoxFit.cover)
        : (_previewUrl != null
              ? Image.network(_previewUrl!, fit: BoxFit.cover)
              : null);

    return AlertDialog(
      title: const Text('Edit Course'),
      insetPadding: const EdgeInsets.all(14),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _title,
                decoration: InputDecoration(
                  labelText: 'Course Title *',
                  errorText: _submitted && titleText.isEmpty
                      ? 'Title is required'
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _subtitle,
                decoration: InputDecoration(
                  labelText: 'Subtitle *',
                  errorText: _submitted && subtitleText.isEmpty
                      ? 'Subtitle is required'
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _description,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Description *',
                  errorText: _submitted && descriptionText.isEmpty
                      ? 'Description is required'
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              if (previewImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    height: 160,
                    width: double.infinity,
                    child: previewImage,
                  ),
                ),
              if (previewImage != null) const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickThumbnail,
                icon: const Icon(Icons.upload_outlined),
                label: const Text('Replace Thumbnail'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _level,
                decoration: const InputDecoration(labelText: 'Level *'),
                items: _levels
                    .map(
                      (level) =>
                          DropdownMenuItem(value: level, child: Text(level)),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _level = value ?? _level),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _language,
                decoration: const InputDecoration(labelText: 'Language *'),
                items:
                    (widget.languages.isEmpty
                            ? [
                                SandboxLanguageSummary(
                                  id: _language,
                                  name: _language,
                                ),
                              ]
                            : widget.languages)
                        .map(
                          (language) => DropdownMenuItem(
                            value: language.id,
                            child: Text(language.name),
                          ),
                        )
                        .toList(),
                onChanged: (value) =>
                    setState(() => _language = value ?? _language),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _priceCents,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Price (in cents) *',
                        errorText:
                            _submitted &&
                                (parsedPrice == null || parsedPrice < 0)
                            ? 'Price must be zero or greater'
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _currency,
                      decoration: const InputDecoration(
                        labelText: 'Currency *',
                      ),
                      items: _currencies
                          .map(
                            (currency) => DropdownMenuItem(
                              value: currency,
                              child: Text(currency),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _currency = value ?? _currency),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _trailerUrl,
                decoration: const InputDecoration(
                  labelText: 'Trailer URL (optional)',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            setState(() => _submitted = true);
            final title = _title.text.trim();
            final subtitle = _subtitle.text.trim();
            final description = _description.text.trim();
            final priceCents = int.tryParse(_priceCents.text.trim());
            if (title.isEmpty ||
                subtitle.isEmpty ||
                description.isEmpty ||
                priceCents == null ||
                priceCents < 0) {
              return;
            }
            Navigator.of(context).pop(
              _CourseEditResult(
                title: title,
                subtitle: subtitle,
                description: description,
                level: _level,
                language: _language,
                priceCents: priceCents,
                currencyCode: _currency,
                trailerUrl: _trailerUrl.text.trim(),
                thumbnailBytes: _thumbnailBytes,
                thumbnailName: _thumbnailName,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _UnitFormResult {
  const _UnitFormResult({
    required this.title,
    required this.type,
    required this.summary,
    required this.estimatedMinutes,
  });

  final String title;
  final String type;
  final String summary;
  final int estimatedMinutes;
}

class _UnitFormDialog extends StatefulWidget {
  const _UnitFormDialog({required this.title, this.initial});

  final String title;
  final AdminUnitPreview? initial;

  @override
  State<_UnitFormDialog> createState() => _UnitFormDialogState();
}

class _UnitFormDialogState extends State<_UnitFormDialog> {
  static const _types = ['module', 'exercise', 'assessment', 'final_exam'];

  late final TextEditingController _title;
  late final TextEditingController _summary;
  late final TextEditingController _minutes;
  String _type = 'module';
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _title = TextEditingController(text: initial?.title ?? '');
    _summary = TextEditingController(text: initial?.summary ?? '');
    _minutes = TextEditingController(
      text: (initial?.estimatedMinutes ?? 30).toString(),
    );
    _type = initial?.type ?? 'module';
  }

  @override
  void dispose() {
    _title.dispose();
    _summary.dispose();
    _minutes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titleText = _title.text.trim();
    final minutes = int.tryParse(_minutes.text.trim());

    return AlertDialog(
      title: Text(widget.title),
      insetPadding: const EdgeInsets.all(14),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _title,
                decoration: InputDecoration(
                  labelText: 'Unit Title *',
                  errorText: _submitted && titleText.isEmpty
                      ? 'Title is required'
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(labelText: 'Type *'),
                items: _types
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(_unitTypeLabel(type)),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _type = value ?? _type),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _summary,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Summary'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _minutes,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Estimated Minutes *',
                  errorText: _submitted && (minutes == null || minutes < 0)
                      ? 'Estimated minutes must be zero or greater'
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            setState(() => _submitted = true);
            final title = _title.text.trim();
            final estimatedMinutes = int.tryParse(_minutes.text.trim()) ?? -1;
            if (title.isEmpty || estimatedMinutes < 0) {
              return;
            }
            Navigator.of(context).pop(
              _UnitFormResult(
                title: title,
                type: _type,
                summary: _summary.text.trim(),
                estimatedMinutes: estimatedMinutes,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _PrerequisitesDialog extends StatefulWidget {
  const _PrerequisitesDialog({
    required this.unit,
    required this.availableUnits,
    required this.onAdd,
    required this.onRemove,
  });

  final AdminUnitPreview unit;
  final List<AdminUnitPreview> availableUnits;
  final Future<void> Function(String prerequisiteId) onAdd;
  final Future<void> Function(String prerequisiteId) onRemove;

  @override
  State<_PrerequisitesDialog> createState() => _PrerequisitesDialogState();
}

class _PrerequisitesDialogState extends State<_PrerequisitesDialog> {
  bool _busy = false;
  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.unit.prerequisites.map((item) => item.id).toSet();
  }

  Future<void> _run(Future<void> Function() action, String success) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      AppToast.show(context, success);
    } catch (e) {
      if (!mounted) return;
      AppToast.show(context, AppToast.errorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allUnits = {
      for (final item in widget.availableUnits) item.id: item,
      for (final item in widget.unit.prerequisites)
        item.id: AdminUnitPreview(
          id: item.id,
          title: item.title,
          summary: '',
          type: item.type ?? 'module',
          estimatedMinutes: item.position ?? 0,
          position: item.position ?? 0,
          isPublished: false,
          prerequisites: const [],
          requiredFor: const [],
        ),
    };
    final selected =
        _selectedIds
            .map((id) => allUnits[id])
            .whereType<AdminUnitPreview>()
            .toList()
          ..sort((a, b) => a.position.compareTo(b.position));
    final available = widget.availableUnits
        .where((unit) => !_selectedIds.contains(unit.id))
        .toList();

    return AlertDialog(
      title: Text('Prerequisites - ${widget.unit.title}'),
      insetPadding: const EdgeInsets.all(14),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Current prerequisites',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              if (selected.isEmpty)
                const Text('No prerequisites set')
              else
                ...selected.map(
                  (item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.title),
                    subtitle: Text(_unitTypeLabel(item.type)),
                    trailing: IconButton(
                      onPressed: _busy
                          ? null
                          : () => _run(() async {
                              await widget.onRemove(item.id);
                              if (!mounted) return;
                              setState(() => _selectedIds.remove(item.id));
                            }, 'Prerequisite removed'),
                      icon: const Icon(Icons.close),
                    ),
                  ),
                ),
              const Divider(height: 24),
              Text(
                'Available units',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              if (available.isEmpty)
                const Text('No more units available for prerequisites')
              else
                ...available.map(
                  (item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.title),
                    subtitle: Text(_unitTypeLabel(item.type)),
                    trailing: IconButton(
                      onPressed: _busy
                          ? null
                          : () => _run(() async {
                              await widget.onAdd(item.id);
                              if (!mounted) return;
                              setState(() => _selectedIds.add(item.id));
                            }, 'Prerequisite added'),
                      icon: const Icon(Icons.add),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

String _unitTypeLabel(String type) {
  switch (type) {
    case 'module':
      return 'Module';
    case 'exercise':
      return 'Exercise';
    case 'assessment':
      return 'Assessment';
    case 'final_exam':
      return 'Final Exam';
    default:
      return type;
  }
}

String _imageMimeType(String fileName) {
  final lower = fileName.toLowerCase();
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.gif')) return 'image/gif';
  if (lower.endsWith('.webp')) return 'image/webp';
  return 'application/octet-stream';
}
