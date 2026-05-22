import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skillforgeapp/view_models/admin/admin_unit_placeholder_view_model.dart';
import 'package:skillforgeapp/config/asset_urls.dart';
import 'package:skillforgeapp/models/admin/admin_models.dart';
import 'package:skillforgeapp/models/shared/api_error.dart';
import 'package:skillforgeapp/ui/design_system.dart';
import 'package:skillforgeapp/views/admin/admin_unit_assessment_final_exam_section.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

class AdminUnitPlaceholderPage extends ConsumerStatefulWidget {
  const AdminUnitPlaceholderPage({
    super.key,
    required this.courseId,
    required this.unitId,
  });

  final String courseId;
  final String unitId;

  @override
  ConsumerState<AdminUnitPlaceholderPage> createState() =>
      _AdminUnitPlaceholderPageState();
}

class _AdminUnitPlaceholderPageState
    extends ConsumerState<AdminUnitPlaceholderPage> {
  AdminCourse? _course;
  AdminUnitDetail? _unit;
  List<SandboxLanguageSummary> _languages = const [];
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(adminUnitPlaceholderActionsProvider.notifier);
      final unit = await repo.getAdminUnitById(widget.unitId);
      if (unit.courseId != widget.courseId) {
        throw ApiError(
          message: 'Unit does not belong to this course',
          timestamp: DateTime.now().toIso8601String(),
        );
      }
      final course = await repo.getAdminCourse(widget.courseId);
      List<SandboxLanguageSummary> languages = _languages;
      if (unit.type == 'exercise') {
        try {
          languages = await repo.getSandboxLanguageCatalog(
            includeBaseCode: true,
          );
        } catch (_) {
          languages = _languages;
        }
      }
      if (!mounted) return;
      setState(() {
        _unit = unit;
        _course = course;
        _languages = languages;
      });
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _error = 'Failed to load unit: ${AppToast.errorMessage(e)}',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<AdminUnitDetail> _refreshUnit() async {
    final updated = await ref
        .read(adminUnitPlaceholderActionsProvider.notifier)
        .getAdminUnitById(widget.unitId);
    if (!mounted) return updated;
    setState(() => _unit = updated);
    return updated;
  }

  void _toast(String message) {
    AppToast.show(context, message);
  }

  Future<void> _openEditUnitDialog() async {
    final unit = _unit;
    if (unit == null) return;
    final result = await showAppDialog<_UnitMetaFormResult>(
      context: context,
      useRootNavigator: true,
      builder: (context) => _UnitMetaFormDialog(unit: unit),
    );
    if (result == null) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(adminUnitPlaceholderActionsProvider.notifier)
          .updateAdminUnitPatch(
            unitId: unit.id,
            title: result.title,
            type: result.type,
            summary: result.summary,
            estimatedMinutes: result.estimatedMinutes,
            position: result.position,
            isPublished: unit.isPublished,
          );
      await _load();
      _toast('Unit updated');
    } catch (e) {
      _toast('Failed to update unit: ${AppToast.errorMessage(e)}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteUnit() async {
    final unit = _unit;
    if (unit == null) return;
    final confirm = await showAppDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (context) => AlertDialog(
        title: const Text('Delete Unit'),
        content: Text('Delete "${unit.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _busy = true);
    try {
      await ref
          .read(adminUnitPlaceholderActionsProvider.notifier)
          .deleteAdminUnit(unit.id);
      if (!mounted) return;
      _toast('Unit deleted');
      context.go('/admin/courses/${widget.courseId}');
    } catch (e) {
      _toast('Failed to delete unit: ${AppToast.errorMessage(e)}');
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unit = _unit;

    return AppPage(
      title: unit?.title ?? 'Unit Detail',
      subtitle: unit == null ? widget.unitId : _prettyType(unit.type),
      child: _loading
          ? AppAsyncState.loading()
          : _error != null
          ? _ErrorState(message: _error!, onRetry: _load)
          : unit == null
          ? _ErrorState(message: 'Unit not found', onRetry: _load)
          : ListView(
              children: [
                GlassPanel(
                  radius: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  unit.title,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  unit.summary.isEmpty
                                      ? 'No summary yet.'
                                      : unit.summary,
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    Chip(label: Text(_prettyType(unit.type))),
                                    Chip(
                                      label: Text('Position ${unit.position}'),
                                    ),
                                    Chip(
                                      label: Text(
                                        '${unit.estimatedMinutes} min',
                                      ),
                                    ),
                                    Chip(
                                      label: Text(
                                        unit.isPublished
                                            ? 'Published'
                                            : 'Draft',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            children: [
                              IconButton.filledTonal(
                                onPressed: _busy ? null : _openEditUnitDialog,
                                icon: const Icon(Icons.edit_outlined),
                              ),
                              const SizedBox(height: 8),
                              IconButton.filledTonal(
                                style: IconButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                onPressed: _busy ? null : _deleteUnit,
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        spacing: 8,
                        children: [
                          _InfoPill(
                            label: 'Course',
                            value: _course?.title ?? widget.courseId,
                          ),
                          _InfoPill(
                            label: 'Created',
                            value: _shortDate(unit.createdAt),
                          ),
                          _InfoPill(
                            label: 'Updated',
                            value: _shortDate(unit.updatedAt),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 10,
                        children: [
                          Expanded(
                            child: _DependencyPanel(
                              title: 'Requires Before This Unit',
                              emptyLabel: 'No prerequisites yet.',
                              color: Colors.blue,
                              items: unit.prerequisites,
                            ),
                          ),
                          Expanded(
                            child: _DependencyPanel(
                              title: 'Required For These Units',
                              emptyLabel: 'No dependent units yet.',
                              color: Colors.green,
                              items: unit.requiredFor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                if (unit.type == 'module')
                  _AdminModuleEditor(
                    unit: unit,
                    onToast: _toast,
                    refreshUnit: _refreshUnit,
                  )
                else if (unit.type == 'exercise')
                  _AdminExerciseEditor(
                    unit: unit,
                    languages: _languages,
                    onToast: _toast,
                    refreshUnit: _refreshUnit,
                  )
                else
                  AdminAssessmentFinalExamSection(
                    unit: unit,
                    onToast: _toast,
                    refreshUnit: _refreshUnit,
                  ),
              ],
            ),
    );
  }
}

class _AdminModuleEditor extends ConsumerStatefulWidget {
  const _AdminModuleEditor({
    required this.unit,
    required this.onToast,
    required this.refreshUnit,
  });

  final AdminUnitDetail unit;
  final void Function(String message) onToast;
  final Future<AdminUnitDetail> Function() refreshUnit;

  @override
  ConsumerState<_AdminModuleEditor> createState() => _AdminModuleEditorState();
}

class _AdminModuleEditorState extends ConsumerState<_AdminModuleEditor> {
  late String _contentKind;
  late TextEditingController _videoUrlController;
  late TextEditingController _articleController;
  late TextEditingController _speedsController;
  late TextEditingController _attachmentLabelController;
  bool _supportsPip = true;
  bool _loading = true;
  bool _saving = false;
  bool _hasExistingContent = false;
  List<AdminModuleResource> _resources = const [];

  @override
  void initState() {
    super.initState();
    final content = widget.unit.moduleContent;
    _contentKind = content?.contentKind == 'video'
        ? 'video'
        : 'article_markdown';
    _videoUrlController = TextEditingController(text: content?.videoUrl ?? '');
    _articleController = TextEditingController(
      text: content?.articleMarkdown ?? '',
    );
    _speedsController = TextEditingController(
      text: (content?.playbackSpeeds.isNotEmpty ?? false)
          ? content!.playbackSpeeds.join(',')
          : '1,1.25,1.5',
    );
    _attachmentLabelController = TextEditingController();
    _supportsPip = content?.supportsPip ?? true;
    _resources = widget.unit.moduleResources;
    _hasExistingContent = content != null;
    _load();
  }

  @override
  void dispose() {
    _videoUrlController.dispose();
    _articleController.dispose();
    _speedsController.dispose();
    _attachmentLabelController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(adminUnitPlaceholderActionsProvider.notifier);
      AdminModuleContent? content;
      try {
        content = await repo.getAdminModuleContent(widget.unit.id);
      } catch (error) {
        if (error is! ApiError || error.statusCode != 404) rethrow;
      }
      final resources = await repo.listAdminModuleResources(widget.unit.id);
      if (!mounted) return;
      setState(() {
        _hasExistingContent = content != null;
        if (content != null) {
          _contentKind = content.contentKind == 'video'
              ? 'video'
              : 'article_markdown';
          _videoUrlController.text = content.videoUrl ?? '';
          _articleController.text = content.articleMarkdown ?? '';
          _speedsController.text = content.playbackSpeeds.isNotEmpty
              ? content.playbackSpeeds.join(',')
              : '1,1.25,1.5';
          _supportsPip = content.supportsPip;
        }
        _resources = resources;
      });
    } catch (e) {
      widget.onToast(
        'Failed to load module content: ${AppToast.errorMessage(e)}',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<double> _parsePlaybackSpeeds() {
    return _speedsController.text
        .split(',')
        .map((part) => double.tryParse(part.trim()))
        .whereType<double>()
        .where((value) => value > 0)
        .toList();
  }

  Future<void> _saveContent() async {
    if (_contentKind == 'video' && _videoUrlController.text.trim().isEmpty) {
      widget.onToast('Video URL is required for video modules');
      return;
    }
    if (_contentKind == 'article_markdown' &&
        _articleController.text.trim().isEmpty) {
      widget.onToast('Markdown content is required for article modules');
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = ref.read(adminUnitPlaceholderActionsProvider.notifier);
      if (_hasExistingContent) {
        await repo.updateAdminModuleContent(
          unitId: widget.unit.id,
          contentKind: _contentKind,
          videoUrl: _contentKind == 'video'
              ? _videoUrlController.text.trim()
              : null,
          articleMarkdown: _contentKind == 'article_markdown'
              ? _articleController.text
              : null,
          playbackSpeeds: _parsePlaybackSpeeds(),
          supportsPip: _supportsPip,
        );
      } else {
        await repo.createAdminModuleContent(
          unitId: widget.unit.id,
          contentKind: _contentKind,
          videoUrl: _contentKind == 'video'
              ? _videoUrlController.text.trim()
              : null,
          articleMarkdown: _contentKind == 'article_markdown'
              ? _articleController.text
              : null,
          playbackSpeeds: _parsePlaybackSpeeds(),
          supportsPip: _supportsPip,
        );
      }
      _hasExistingContent = true;
      await widget.refreshUnit();
      widget.onToast('Module content saved');
    } catch (e) {
      widget.onToast(
        'Failed to save module content: ${AppToast.errorMessage(e)}',
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      withData: true,
      allowedExtensions: const ['mp4', 'webm'],
    );
    final file = result?.files.single;
    if (file == null || file.bytes == null) return;

    setState(() => _saving = true);
    try {
      final uploaded = await ref
          .read(adminUnitPlaceholderActionsProvider.notifier)
          .uploadAdminModuleVideo(
            unitId: widget.unit.id,
            fileName: file.name,
            bytes: file.bytes!,
            contentType: _resourceMimeType(file.name),
          );
      final url =
          uploaded['videoUrl']?.toString() ??
          AssetUrls.cdnUrl(uploaded['s3Key']?.toString()) ??
          '';
      if (!mounted) return;
      setState(() => _videoUrlController.text = url);
      widget.onToast('Video uploaded');
    } catch (e) {
      widget.onToast('Failed to upload video: ${AppToast.errorMessage(e)}');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    final file = result?.files.single;
    if (file == null || file.bytes == null) return;
    final label = _attachmentLabelController.text.trim().isEmpty
        ? file.name
        : _attachmentLabelController.text.trim();
    setState(() => _saving = true);
    try {
      final uploaded = await ref
          .read(adminUnitPlaceholderActionsProvider.notifier)
          .uploadAdminModuleResource(
            unitId: widget.unit.id,
            fileName: file.name,
            bytes: file.bytes!,
            label: label,
            resourceType: _resourceKindForFile(file.name),
            contentType: _resourceMimeType(file.name),
          );
      final resourceMap = uploaded['resource'] is Map<String, dynamic>
          ? uploaded['resource'] as Map<String, dynamic>
          : uploaded;
      if (!mounted) return;
      setState(() {
        _resources = [AdminModuleResource.fromJson(resourceMap), ..._resources];
        _attachmentLabelController.clear();
      });
      await widget.refreshUnit();
      widget.onToast('Attachment uploaded');
    } catch (e) {
      widget.onToast(
        'Failed to upload attachment: ${AppToast.errorMessage(e)}',
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteAttachment(AdminModuleResource resource) async {
    try {
      await ref
          .read(adminUnitPlaceholderActionsProvider.notifier)
          .deleteAdminModuleResource(resource.id);
      if (!mounted) return;
      setState(() {
        _resources = _resources
            .where((item) => item.id != resource.id)
            .toList();
      });
      await widget.refreshUnit();
      widget.onToast('Attachment removed');
    } catch (e) {
      widget.onToast(
        'Failed to remove attachment: ${AppToast.errorMessage(e)}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final videoUrl = _videoUrlController.text.trim();
    return GlassPanel(
      radius: 20,
      child: _loading
          ? const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Module Content',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _contentKind,
                      decoration: const InputDecoration(
                        labelText: 'Content Type',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'article_markdown',
                          child: Text('Article (Markdown)'),
                        ),
                        DropdownMenuItem(value: 'video', child: Text('Video')),
                      ],
                      onChanged: _saving
                          ? null
                          : (value) {
                              if (value == null) return;
                              setState(() => _contentKind = value);
                            },
                    ),
                    const SizedBox(height: 10),
                    if (_contentKind == 'video') ...[
                      TextField(
                        controller: _videoUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Video URL',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.tonalIcon(
                        onPressed: _saving ? null : _pickVideo,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Upload Video to Platform'),
                      ),
                    ] else ...[
                      TextField(
                        controller: _articleController,
                        minLines: 16,
                        maxLines: 22,
                        decoration: const InputDecoration(
                          labelText: 'Article Markdown',
                          alignLabelWithHint: true,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                    if (_contentKind == 'video') ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: _speedsController,
                        decoration: const InputDecoration(
                          labelText: 'Playback Speeds',
                          helperText: 'Comma separated, e.g. 1,1.25,1.5',
                        ),
                      ),
                      CheckboxListTile(
                        value: _supportsPip,
                        onChanged: _saving
                            ? null
                            : (value) {
                                if (value == null) return;
                                setState(() => _supportsPip = value);
                              },
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Support Picture-in-Picture'),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ],
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_contentKind == 'article_markdown')
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: MarkdownBody(
                            data: _articleController.text.isEmpty
                                ? '*Start writing markdown...*'
                                : _articleController.text,
                            selectable: true,
                          ),
                        ),
                      )
                    else
                      _VideoPreview(url: videoUrl),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Attachments',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _attachmentLabelController,
                                    decoration: const InputDecoration(
                                      labelText: 'Attachment Label',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                FilledButton.tonalIcon(
                                  onPressed: _saving ? null : _pickAttachment,
                                  icon: const Icon(Icons.attach_file),
                                  label: const Text('Upload'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (_resources.isEmpty)
                              const Text('No attachments yet.')
                            else
                              ..._resources.map(
                                (resource) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(resource.label),
                                  subtitle: Text(resource.resourceType),
                                  trailing: IconButton(
                                    onPressed: () =>
                                        _deleteAttachment(resource),
                                    icon: const Icon(Icons.delete_outline),
                                  ),
                                  onTap: () => _openResource(resource),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _saveContent,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_saving ? 'Saving...' : 'Save Content'),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _openResource(AdminModuleResource resource) async {
    final url = resource.url ?? AssetUrls.cdnUrl(resource.s3Key);
    if (url == null) return;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}

class _AdminExerciseEditor extends ConsumerStatefulWidget {
  const _AdminExerciseEditor({
    required this.unit,
    required this.languages,
    required this.onToast,
    required this.refreshUnit,
  });

  final AdminUnitDetail unit;
  final List<SandboxLanguageSummary> languages;
  final void Function(String message) onToast;
  final Future<AdminUnitDetail> Function() refreshUnit;

  @override
  ConsumerState<_AdminExerciseEditor> createState() =>
      _AdminExerciseEditorState();
}

class _AdminExerciseEditorState extends ConsumerState<_AdminExerciseEditor> {
  bool _busy = false;

  AdminExerciseDetail? get _exercise => widget.unit.exercise;

  Future<void> _openCreateExerciseDialog() async {
    final result = await showAppDialog<_ExerciseFormResult>(
      context: context,
      useRootNavigator: true,
      builder: (context) => _ExerciseFormDialog(languages: widget.languages),
    );
    if (result == null) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(adminUnitPlaceholderActionsProvider.notifier)
          .createAdminExercise(
            unitId: widget.unit.id,
            title: result.title,
            promptMarkdown: result.promptMarkdown,
            difficulty: result.difficulty,
            language: result.language,
            starterCode: result.starterCode,
            maxCpuMs: result.maxCpuMs,
            maxMemoryKb: result.maxMemoryKb,
          );
      await widget.refreshUnit();
      widget.onToast('Exercise created');
    } catch (e) {
      widget.onToast('Failed to create exercise: ${AppToast.errorMessage(e)}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openEditExerciseDialog(AdminExerciseDetail exercise) async {
    final result = await showAppDialog<_ExerciseFormResult>(
      context: context,
      useRootNavigator: true,
      builder: (context) =>
          _ExerciseFormDialog(languages: widget.languages, initial: exercise),
    );
    if (result == null) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(adminUnitPlaceholderActionsProvider.notifier)
          .updateAdminExercise(
            exerciseId: exercise.id,
            title: result.title,
            promptMarkdown: result.promptMarkdown,
            difficulty: result.difficulty,
            language: result.language,
            starterCode: result.starterCode,
            maxCpuMs: result.maxCpuMs,
            maxMemoryKb: result.maxMemoryKb,
          );
      await widget.refreshUnit();
      widget.onToast('Exercise updated');
    } catch (e) {
      widget.onToast('Failed to update exercise: ${AppToast.errorMessage(e)}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteExercise(AdminExerciseDetail exercise) async {
    final confirm = await showAppDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (context) => AlertDialog(
        title: const Text('Delete Exercise'),
        content: Text('Delete "${exercise.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _busy = true);
    try {
      await ref
          .read(adminUnitPlaceholderActionsProvider.notifier)
          .deleteAdminExercise(exercise.id);
      await widget.refreshUnit();
      widget.onToast('Exercise deleted');
    } catch (e) {
      widget.onToast('Failed to delete exercise: ${AppToast.errorMessage(e)}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openCreateTestCases(AdminExerciseDetail exercise) async {
    final result = await showAppDialog<List<_TestCaseDraft>>(
      context: context,
      useRootNavigator: true,
      builder: (context) => const _CreateTestCasesDialog(),
    );
    if (result == null || result.isEmpty) return;
    setState(() => _busy = true);
    try {
      final repo = ref.read(adminUnitPlaceholderActionsProvider.notifier);
      for (final draft in result) {
        await repo.addAdminExerciseTestCase(
          exerciseId: exercise.id,
          inputText: draft.inputText,
          expectedOutput: draft.expectedOutput,
          isHidden: draft.isHidden,
        );
      }
      await widget.refreshUnit();
      widget.onToast(
        '${result.length} test case${result.length == 1 ? '' : 's'} added',
      );
    } catch (e) {
      widget.onToast('Failed to add test cases: ${AppToast.errorMessage(e)}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openEditTestCase(
    AdminExerciseDetail exercise,
    AdminExerciseTestCase testCase,
  ) async {
    final result = await showAppDialog<_TestCaseDraft>(
      context: context,
      useRootNavigator: true,
      builder: (context) => _EditTestCaseDialog(initial: testCase),
    );
    if (result == null) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(adminUnitPlaceholderActionsProvider.notifier)
          .updateAdminExerciseTestCase(
            testCaseId: testCase.id,
            inputText: result.inputText,
            expectedOutput: result.expectedOutput,
            isHidden: result.isHidden,
          );
      await widget.refreshUnit();
      widget.onToast('Test case updated');
    } catch (e) {
      widget.onToast('Failed to update test case: ${AppToast.errorMessage(e)}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteTestCase(AdminExerciseTestCase testCase) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(adminUnitPlaceholderActionsProvider.notifier)
          .deleteAdminExerciseTestCase(testCase.id);
      await widget.refreshUnit();
      widget.onToast('Test case deleted');
    } catch (e) {
      widget.onToast('Failed to delete test case: ${AppToast.errorMessage(e)}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openCreateHint(AdminExerciseDetail exercise) async {
    final result = await showAppDialog<_HintFormResult>(
      context: context,
      useRootNavigator: true,
      builder: (context) => const _HintFormDialog(),
    );
    if (result == null) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(adminUnitPlaceholderActionsProvider.notifier)
          .addAdminExerciseHint(
            exerciseId: exercise.id,
            content: result.hintText,
            requiredFailedAttempts: result.unlockAfterFailedAttempts,
          );
      await widget.refreshUnit();
      widget.onToast('Hint added');
    } catch (e) {
      widget.onToast('Failed to add hint: ${AppToast.errorMessage(e)}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openEditHint(AdminExerciseHint hint) async {
    final result = await showAppDialog<_HintFormResult>(
      context: context,
      useRootNavigator: true,
      builder: (context) => _HintFormDialog(initial: hint),
    );
    if (result == null) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(adminUnitPlaceholderActionsProvider.notifier)
          .updateAdminExerciseHint(
            hintId: hint.id,
            content: result.hintText,
            requiredFailedAttempts: result.unlockAfterFailedAttempts,
          );
      await widget.refreshUnit();
      widget.onToast('Hint updated');
    } catch (e) {
      widget.onToast('Failed to update hint: ${AppToast.errorMessage(e)}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteHint(AdminExerciseHint hint) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(adminUnitPlaceholderActionsProvider.notifier)
          .deleteAdminExerciseHint(hint.id);
      await widget.refreshUnit();
      widget.onToast('Hint deleted');
    } catch (e) {
      widget.onToast('Failed to delete hint: ${AppToast.errorMessage(e)}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercise = _exercise;
    return GlassPanel(
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Exercise Editor',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (exercise == null)
                FilledButton.icon(
                  onPressed: _busy ? null : _openCreateExerciseDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Create Exercise'),
                )
              else ...[
                IconButton.filledTonal(
                  onPressed: _busy
                      ? null
                      : () => _openEditExerciseDialog(exercise),
                  icon: const Icon(Icons.edit_outlined),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  style: IconButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: _busy ? null : () => _deleteExercise(exercise),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (exercise == null)
            const Text(
              'No exercise yet. Create the exercise content for this unit.',
            )
          else ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(exercise.difficulty)),
                Chip(label: Text(exercise.language)),
                Chip(label: Text('${exercise.testCases.length} test cases')),
                Chip(label: Text('${exercise.hints.length} hints')),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    MarkdownBody(
                      data: exercise.promptMarkdown,
                      selectable: true,
                    ),
                  ],
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Starter Code',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _CodeBox(text: exercise.starterCode),
                    const SizedBox(height: 10),
                    Text(
                      'Limits: ${exercise.maxCpuMs}ms CPU • ${exercise.maxMemoryKb}KB memory',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Test Cases (${exercise.testCases.length})',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: _busy
                              ? null
                              : () => _openCreateTestCases(exercise),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Test Cases'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (exercise.testCases.isEmpty)
                      const Text('No test cases yet.')
                    else
                      ...exercise.testCases.asMap().entries.map((entry) {
                        final index = entry.key;
                        final testCase = entry.value;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('Case ${index + 1}'),
                          subtitle: Text(
                            '${testCase.isHidden ? 'Hidden' : 'Visible'} • ${_trimInline(testCase.expectedOutput)}',
                          ),
                          trailing: Wrap(
                            spacing: 4,
                            children: [
                              IconButton(
                                onPressed: _busy
                                    ? null
                                    : () =>
                                          _openEditTestCase(exercise, testCase),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                              IconButton(
                                onPressed: _busy
                                    ? null
                                    : () => _deleteTestCase(testCase),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                          onTap: _busy
                              ? null
                              : () => _openEditTestCase(exercise, testCase),
                        );
                      }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Hints (${exercise.hints.length})',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: _busy
                              ? null
                              : () => _openCreateHint(exercise),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Hint'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (exercise.hints.isEmpty)
                      const Text('No hints yet.')
                    else
                      ...(() {
                        final sorted = [...exercise.hints]
                          ..sort(
                            (a, b) => a.unlockAfterFailedAttempts.compareTo(
                              b.unlockAfterFailedAttempts,
                            ),
                          );
                        return sorted.map(
                          (hint) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(hint.hintText),
                            subtitle: Text(
                              'Unlock after ${hint.unlockAfterFailedAttempts} failed attempts',
                            ),
                            trailing: Wrap(
                              spacing: 4,
                              children: [
                                IconButton(
                                  onPressed: _busy
                                      ? null
                                      : () => _openEditHint(hint),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  onPressed: _busy
                                      ? null
                                      : () => _deleteHint(hint),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                            onTap: _busy ? null : () => _openEditHint(hint),
                          ),
                        );
                      })(),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DependencyPanel extends StatelessWidget {
  const _DependencyPanel({
    required this.title,
    required this.emptyLabel,
    required this.color,
    required this.items,
  });

  final String title;
  final String emptyLabel;
  final Color color;
  final List<AdminPrerequisite> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: color),
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              Text(emptyLabel)
            else
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(child: Text(item.title)),
                      Text(
                        [
                          if (item.type != null && item.type!.isNotEmpty)
                            _prettyType(item.type!),
                          if (item.position != null)
                            'Position ${item.position}',
                        ].join(' • '),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GlassPanel(
        radius: 20,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              Text(value, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _CodeBox extends StatelessWidget {
  const _CodeBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 180),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF020617)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SelectableText(
        text.isEmpty ? '// No starter code yet' : text,
        style: const TextStyle(fontFamily: 'monospace', height: 1.45),
      ),
    );
  }
}

class _VideoPreview extends StatelessWidget {
  const _VideoPreview({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No video selected yet.'),
        ),
      );
    }
    if (_isYouTubeUrl(url)) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.play_circle_outline),
          title: const Text('Video Preview'),
          subtitle: const Text('Open YouTube link externally'),
          onTap: () =>
              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
        ),
      );
    }
    return _InlineVideoPlayer(url: url);
  }
}

class _InlineVideoPlayer extends StatefulWidget {
  const _InlineVideoPlayer({required this.url});

  final String url;

  @override
  State<_InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}

class _InlineVideoPlayerState extends State<_InlineVideoPlayer> {
  VideoPlayerController? _controller;
  Future<void>? _initialize;

  @override
  void initState() {
    super.initState();
    _configure();
  }

  @override
  void didUpdateWidget(covariant _InlineVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _configure();
    }
  }

  Future<void> _configure() async {
    await _controller?.dispose();
    final uri = Uri.tryParse(widget.url);
    if (uri == null) {
      setState(() {
        _controller = null;
        _initialize = null;
      });
      return;
    }
    final controller = VideoPlayerController.networkUrl(uri);
    final initialize = controller.initialize();
    setState(() {
      _controller = controller;
      _initialize = initialize;
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || _initialize == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Invalid video URL'),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: FutureBuilder<void>(
          future: _initialize,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const AspectRatio(
                aspectRatio: 16 / 9,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return Column(
              children: [
                AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio == 0
                      ? 16 / 9
                      : _controller!.value.aspectRatio,
                  child: VideoPlayer(_controller!),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          if (_controller!.value.isPlaying) {
                            _controller!.pause();
                          } else {
                            _controller!.play();
                          }
                        });
                      },
                      icon: Icon(
                        _controller!.value.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                      ),
                    ),
                    Expanded(
                      child: VideoProgressIndicator(
                        _controller!,
                        allowScrubbing: true,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _UnitMetaFormResult {
  const _UnitMetaFormResult({
    required this.title,
    required this.type,
    required this.summary,
    required this.position,
    required this.estimatedMinutes,
  });

  final String title;
  final String type;
  final String summary;
  final int position;
  final int estimatedMinutes;
}

class _UnitMetaFormDialog extends StatefulWidget {
  const _UnitMetaFormDialog({required this.unit});

  final AdminUnitDetail unit;

  @override
  State<_UnitMetaFormDialog> createState() => _UnitMetaFormDialogState();
}

class _UnitMetaFormDialogState extends State<_UnitMetaFormDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _summaryController;
  late final TextEditingController _positionController;
  late final TextEditingController _estimatedController;
  late String _type;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.unit.title);
    _summaryController = TextEditingController(text: widget.unit.summary);
    _positionController = TextEditingController(
      text: widget.unit.position.toString(),
    );
    _estimatedController = TextEditingController(
      text: widget.unit.estimatedMinutes.toString(),
    );
    _type = widget.unit.type;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _positionController.dispose();
    _estimatedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Unit'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(value: 'module', child: Text('Module')),
                  DropdownMenuItem(value: 'exercise', child: Text('Exercise')),
                  DropdownMenuItem(
                    value: 'assessment',
                    child: Text('Assessment'),
                  ),
                  DropdownMenuItem(
                    value: 'final_exam',
                    child: Text('Final Exam'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _type = value);
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _estimatedController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Estimated Minutes',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _summaryController,
                minLines: 4,
                maxLines: 6,
                decoration: const InputDecoration(labelText: 'Summary'),
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
            Navigator.of(context).pop(
              _UnitMetaFormResult(
                title: _titleController.text.trim(),
                type: _type,
                summary: _summaryController.text,
                position: int.tryParse(_positionController.text) ?? 1,
                estimatedMinutes: int.tryParse(_estimatedController.text) ?? 0,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _ExerciseFormResult {
  const _ExerciseFormResult({
    required this.title,
    required this.promptMarkdown,
    required this.difficulty,
    required this.language,
    required this.starterCode,
    required this.maxCpuMs,
    required this.maxMemoryKb,
  });

  final String title;
  final String promptMarkdown;
  final String difficulty;
  final String language;
  final String starterCode;
  final int maxCpuMs;
  final int maxMemoryKb;
}

class _ExerciseFormDialog extends StatefulWidget {
  const _ExerciseFormDialog({required this.languages, this.initial});

  final List<SandboxLanguageSummary> languages;
  final AdminExerciseDetail? initial;

  @override
  State<_ExerciseFormDialog> createState() => _ExerciseFormDialogState();
}

class _ExerciseFormDialogState extends State<_ExerciseFormDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _promptController;
  late final TextEditingController _starterCodeController;
  late final TextEditingController _cpuController;
  late final TextEditingController _memoryController;
  late String _difficulty;
  late String _language;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _titleController = TextEditingController(text: initial?.title ?? '');
    _promptController = TextEditingController(
      text: initial?.promptMarkdown ?? '',
    );
    _starterCodeController = TextEditingController(
      text: initial?.starterCode ?? '',
    );
    _cpuController = TextEditingController(
      text: (initial?.maxCpuMs ?? 5000).toString(),
    );
    _memoryController = TextEditingController(
      text: (initial?.maxMemoryKb ?? 256000).toString(),
    );
    _difficulty = initial?.difficulty ?? 'normal';
    _language =
        initial?.language ??
        (widget.languages.isNotEmpty
            ? widget.languages.first.id
            : 'javascript');
    if (initial == null) {
      final defaultBaseCode = _baseCodeForLanguage(_language);
      if (defaultBaseCode != null && defaultBaseCode.isNotEmpty) {
        _starterCodeController.text = defaultBaseCode;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _promptController.dispose();
    _starterCodeController.dispose();
    _cpuController.dispose();
    _memoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageIds = widget.languages
        .map((item) => item.id)
        .toSet()
        .toList();
    if (!languageIds.contains(_language)) {
      languageIds.add(_language);
    }

    return AlertDialog(
      title: Text(widget.initial == null ? 'Create Exercise' : 'Edit Exercise'),
      content: SizedBox(
        width: 760,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _difficulty,
                      decoration: const InputDecoration(
                        labelText: 'Difficulty',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'normal',
                          child: Text('Normal'),
                        ),
                        DropdownMenuItem(
                          value: 'advanced',
                          child: Text('Advanced'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _difficulty = value);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _language,
                      decoration: const InputDecoration(labelText: 'Language'),
                      items: languageIds
                          .map(
                            (id) =>
                                DropdownMenuItem(value: id, child: Text(id)),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _language = value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _promptController,
                minLines: 8,
                maxLines: 14,
                decoration: const InputDecoration(
                  labelText: 'Prompt Markdown',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () {
                      final baseCode = _baseCodeForLanguage(_language);
                      if (baseCode == null || baseCode.isEmpty) return;
                      setState(() {
                        _starterCodeController.text = baseCode;
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Use Default Starter Code'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _starterCodeController,
                minLines: 8,
                maxLines: 14,
                decoration: const InputDecoration(
                  labelText: 'Starter Code',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _cpuController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Max CPU (ms)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _memoryController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Max Memory (KB)',
                      ),
                    ),
                  ),
                ],
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
            Navigator.of(context).pop(
              _ExerciseFormResult(
                title: _titleController.text.trim(),
                promptMarkdown: _promptController.text,
                difficulty: _difficulty,
                language: _language,
                starterCode: _starterCodeController.text,
                maxCpuMs: int.tryParse(_cpuController.text) ?? 5000,
                maxMemoryKb: int.tryParse(_memoryController.text) ?? 256000,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  String? _baseCodeForLanguage(String languageId) {
    for (final language in widget.languages) {
      if (language.id == languageId) {
        return language.baseCode;
      }
    }
    return null;
  }
}

class _TestCaseDraft {
  const _TestCaseDraft({
    required this.inputText,
    required this.expectedOutput,
    required this.isHidden,
  });

  final String inputText;
  final String expectedOutput;
  final bool isHidden;
}

class _CreateTestCasesDialog extends StatefulWidget {
  const _CreateTestCasesDialog();

  @override
  State<_CreateTestCasesDialog> createState() => _CreateTestCasesDialogState();
}

class _CreateTestCasesDialogState extends State<_CreateTestCasesDialog> {
  final List<_DraftControllers> _drafts = [_DraftControllers()];

  @override
  void dispose() {
    for (final draft in _drafts) {
      draft.dispose();
    }
    super.dispose();
  }

  void _addDraft() {
    setState(() => _drafts.add(_DraftControllers()));
  }

  void _removeDraft(_DraftControllers draft) {
    if (_drafts.length == 1) return;
    setState(() {
      _drafts.remove(draft);
      draft.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Test Cases'),
      content: SizedBox(
        width: 800,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ..._drafts.map(
                (draft) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Spacer(),
                              IconButton(
                                onPressed: () => _removeDraft(draft),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                          TextField(
                            controller: draft.inputController,
                            minLines: 4,
                            maxLines: 8,
                            decoration: const InputDecoration(
                              labelText: 'Input',
                              alignLabelWithHint: true,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: draft.outputController,
                            minLines: 4,
                            maxLines: 8,
                            decoration: const InputDecoration(
                              labelText: 'Expected Output',
                              alignLabelWithHint: true,
                            ),
                          ),
                          CheckboxListTile(
                            value: draft.isHidden,
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => draft.isHidden = value);
                            },
                            title: const Text('Hidden'),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonalIcon(
                  onPressed: _addDraft,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Another'),
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
            final drafts = _drafts
                .where(
                  (draft) =>
                      draft.inputController.text.trim().isNotEmpty ||
                      draft.outputController.text.trim().isNotEmpty,
                )
                .map(
                  (draft) => _TestCaseDraft(
                    inputText: draft.inputController.text,
                    expectedOutput: draft.outputController.text,
                    isHidden: draft.isHidden,
                  ),
                )
                .toList();
            Navigator.of(context).pop(drafts);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _DraftControllers {
  _DraftControllers()
    : inputController = TextEditingController(),
      outputController = TextEditingController();

  final TextEditingController inputController;
  final TextEditingController outputController;
  bool isHidden = false;

  void dispose() {
    inputController.dispose();
    outputController.dispose();
  }
}

class _EditTestCaseDialog extends StatefulWidget {
  const _EditTestCaseDialog({required this.initial});

  final AdminExerciseTestCase initial;

  @override
  State<_EditTestCaseDialog> createState() => _EditTestCaseDialogState();
}

class _EditTestCaseDialogState extends State<_EditTestCaseDialog> {
  late final TextEditingController _inputController;
  late final TextEditingController _outputController;
  late bool _isHidden;

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController(text: widget.initial.inputText);
    _outputController = TextEditingController(
      text: widget.initial.expectedOutput,
    );
    _isHidden = widget.initial.isHidden;
  }

  @override
  void dispose() {
    _inputController.dispose();
    _outputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Test Case'),
      content: SizedBox(
        width: 760,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _inputController,
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Input',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _outputController,
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Expected Output',
                  alignLabelWithHint: true,
                ),
              ),
              CheckboxListTile(
                value: _isHidden,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _isHidden = value);
                },
                title: const Text('Hidden'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
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
            Navigator.of(context).pop(
              _TestCaseDraft(
                inputText: _inputController.text,
                expectedOutput: _outputController.text,
                isHidden: _isHidden,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _HintFormResult {
  const _HintFormResult({
    required this.hintText,
    required this.unlockAfterFailedAttempts,
  });

  final String hintText;
  final int unlockAfterFailedAttempts;
}

class _HintFormDialog extends StatefulWidget {
  const _HintFormDialog({this.initial});

  final AdminExerciseHint? initial;

  @override
  State<_HintFormDialog> createState() => _HintFormDialogState();
}

class _HintFormDialogState extends State<_HintFormDialog> {
  late final TextEditingController _hintController;
  late final TextEditingController _attemptsController;
  String? _error;

  @override
  void initState() {
    super.initState();
    _hintController = TextEditingController(
      text: widget.initial?.hintText ?? '',
    );
    _attemptsController = TextEditingController(
      text: (widget.initial?.unlockAfterFailedAttempts ?? 3).toString(),
    );
  }

  @override
  void dispose() {
    _hintController.dispose();
    _attemptsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Add Hint' : 'Edit Hint'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _hintController,
                minLines: 10,
                maxLines: 100,
                decoration: const InputDecoration(
                  labelText: 'Hint Text',
                  alignLabelWithHint: true,
                ),
                onChanged: (_) {
                  if (_error == null) return;
                  setState(() => _error = null);
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _attemptsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Unlock After Failed Attempts',
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
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
            if (_hintController.text.trim().length < 10) {
              setState(() {
                _error = 'Hint must be at least 10 characters.';
              });
              return;
            }
            Navigator.of(context).pop(
              _HintFormResult(
                hintText: _hintController.text,
                unlockAfterFailedAttempts:
                    int.tryParse(_attemptsController.text) ?? 3,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

String _shortDate(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}

String _prettyType(String type) => type.replaceAll('_', ' ');

String _trimInline(String text) {
  final normalized = text.replaceAll('\n', ' ').trim();
  if (normalized.length <= 64) return normalized;
  return '${normalized.substring(0, 64)}...';
}

bool _isYouTubeUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  final host = uri.host.replaceFirst('www.', '');
  return host == 'youtube.com' || host == 'youtu.be' || host == 'm.youtube.com';
}

String _resourceKindForFile(String fileName) {
  final ext = fileName.split('.').last.toLowerCase();
  switch (ext) {
    case 'pdf':
    case 'doc':
    case 'docx':
    case 'txt':
      return 'document';
    case 'xls':
    case 'xlsx':
    case 'csv':
      return 'spreadsheet';
    case 'ppt':
    case 'pptx':
      return 'presentation';
    default:
      return 'other';
  }
}

String _resourceMimeType(String fileName) {
  final ext = fileName.split('.').last.toLowerCase();
  switch (ext) {
    case 'mp4':
      return 'video/mp4';
    case 'webm':
      return 'video/webm';
    case 'pdf':
      return 'application/pdf';
    case 'doc':
      return 'application/msword';
    case 'docx':
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    case 'xls':
      return 'application/vnd.ms-excel';
    case 'xlsx':
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    case 'ppt':
      return 'application/vnd.ms-powerpoint';
    case 'pptx':
      return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
    case 'txt':
      return 'text/plain';
    default:
      return 'application/octet-stream';
  }
}
