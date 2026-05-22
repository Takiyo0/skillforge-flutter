import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skillforgeapp/models/admin/admin_models.dart';
import 'package:skillforgeapp/ui/design_system.dart';
import 'package:skillforgeapp/view_models/admin/admin_learning_paths_view_model.dart';

class AdminLearningPathsPage extends ConsumerStatefulWidget {
  const AdminLearningPathsPage({super.key});

  @override
  ConsumerState<AdminLearningPathsPage> createState() =>
      _AdminLearningPathsPageState();
}

class _AdminLearningPathsPageState
    extends ConsumerState<AdminLearningPathsPage> {
  List<AdminLearningPath> _paths = const [];
  List<AdminCourseSummary> _courses = const [];
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
      final repo = ref.read(adminLearningPathsActionsProvider.notifier);
      final paths = await repo.getAllLearningPathsAdmin();
      final courses = await repo.getInstructorCourses();
      setState(() {
        _paths = paths;
        _courses = courses;
      });
    } catch (e) {
      setState(
        () => _error =
            'Failed to load learning paths: ${AppToast.errorMessage(e)}',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refreshSinglePath(String pathId) async {
    final updated = await ref
        .read(adminLearningPathsActionsProvider.notifier)
        .getLearningPathAdmin(pathId);
    if (!mounted) return;
    setState(() {
      _paths = _paths
          .map((path) => path.id == pathId ? updated : path)
          .toList();
    });
  }

  void _toast(String message) {
    AppToast.show(context, message);
  }

  Future<void> _run(
    Future<void> Function() action, {
    required String success,
    required String errorPrefix,
    bool reloadAll = false,
  }) async {
    setState(() => _busy = true);
    try {
      await action();
      _toast(success);
      if (reloadAll) await _load();
    } catch (e) {
      _toast('$errorPrefix: ${AppToast.errorMessage(e)}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openCreateDialog() async {
    final result = await showAppDialog<_PathFormResult>(
      context: context,
      useRootNavigator: true,
      builder: (context) => const _PathFormDialog(title: 'Create Path'),
    );
    if (result == null) return;
    await _run(
      () async {
        final path = await ref
            .read(adminLearningPathsActionsProvider.notifier)
            .createLearningPath(
              slug: result.slug,
              title: result.title,
              description: result.description,
              isPublic: result.isPublic,
              wantToLearn: result.wantToLearn,
              languages: result.languages,
              alreadyKnow: result.alreadyKnow,
            );
        if (!mounted) return;
        setState(() => _paths = [..._paths, path]);
      },
      success: 'Learning path created',
      errorPrefix: 'Failed to create path',
    );
  }

  Future<void> _openEditDialog(AdminLearningPath path) async {
    final result = await showAppDialog<_PathFormResult>(
      context: context,
      useRootNavigator: true,
      builder: (context) => _PathFormDialog(
        title: 'Edit Path',
        initial: _PathFormResult(
          slug: path.slug,
          title: path.title,
          description: path.description,
          isPublic: path.isPublic,
          wantToLearn: path.criteria.wantToLearn,
          languages: path.criteria.languages,
          alreadyKnow: path.criteria.alreadyKnow,
        ),
        lockSlug: true,
      ),
    );
    if (result == null) return;
    await _run(
      () async {
        final patch = await ref
            .read(adminLearningPathsActionsProvider.notifier)
            .updateLearningPathPatch(
              pathId: path.id,
              title: result.title,
              description: result.description,
              wantToLearn: result.wantToLearn,
              languages: result.languages,
              alreadyKnow: result.alreadyKnow,
              isPublic: result.isPublic,
            );
        final updated = path.applyPatch(patch);
        if (!mounted) return;
        setState(() {
          _paths = _paths.map((p) => p.id == path.id ? updated : p).toList();
        });
      },
      success: 'Learning path updated',
      errorPrefix: 'Failed to update path',
    );
  }

  Future<void> _deletePath(AdminLearningPath path) async {
    final confirm = await showAppDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (context) => AlertDialog(
        title: const Text('Delete Learning Path'),
        content: Text('Delete "${path.title}"? This action cannot be undone.'),
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

    await _run(
      () async {
        await ref
            .read(adminLearningPathsActionsProvider.notifier)
            .deleteLearningPath(path.id);
        if (!mounted) return;
        setState(() => _paths = _paths.where((p) => p.id != path.id).toList());
      },
      success: 'Learning path deleted',
      errorPrefix: 'Failed to delete path',
    );
  }

  Future<void> _openManageCourses(AdminLearningPath path) async {
    await showAppDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (context) => _ManageCoursesDialog(
        path: path,
        allCourses: _courses,
        onAddCourses: (courseIds) async {
          if (courseIds.isEmpty) return;
          await ref
              .read(adminLearningPathsActionsProvider.notifier)
              .addCoursesToPath(path.id, courseIds);
          await _refreshSinglePath(path.id);
        },
        onRemoveCourse: (courseId) async {
          await ref
              .read(adminLearningPathsActionsProvider.notifier)
              .removeCourseFromPath(path.id, courseId);
          await _refreshSinglePath(path.id);
        },
        onReorder: (courseIds) async {
          await ref
              .read(adminLearningPathsActionsProvider.notifier)
              .reorderCoursesInPath(path.id, courseIds);
          await _refreshSinglePath(path.id);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Learning Paths',
      subtitle: 'Create paths and manage course sequence',
      child: ListView(
        children: [
          GlassPanel(
            radius: 18,
            child: Row(
              children: [
                Expanded(child: Text('${_paths.length} path(s) available')),
                FilledButton.icon(
                  onPressed: _busy ? null : _openCreateDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Create Path'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (_error != null)
            GlassPanel(
              radius: 18,
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            )
          else if (_loading)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_paths.isEmpty)
            const GlassPanel(
              radius: 18,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(child: Text('No learning paths yet')),
              ),
            )
          else
            ..._paths.map(
              (path) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _PathCard(
                  path: path,
                  disabled: _busy,
                  onManageCourses: () => _openManageCourses(path),
                  onEdit: () => _openEditDialog(path),
                  onDelete: () => _deletePath(path),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PathCard extends StatelessWidget {
  const _PathCard({
    required this.path,
    required this.disabled,
    required this.onManageCourses,
    required this.onEdit,
    required this.onDelete,
  });

  final AdminLearningPath path;
  final bool disabled;
  final VoidCallback onManageCourses;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      path.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      path.slug,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Chip(label: Text('${path.courses.length} courses')),
            ],
          ),
          const SizedBox(height: 8),
          Text(path.description),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: disabled ? null : onManageCourses,
                icon: const Icon(Icons.menu_book_outlined),
                label: const Text('Manage Courses'),
              ),
              OutlinedButton.icon(
                onPressed: disabled ? null : onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit'),
              ),
              OutlinedButton.icon(
                onPressed: disabled ? null : onDelete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PathFormResult {
  const _PathFormResult({
    required this.slug,
    required this.title,
    required this.description,
    required this.isPublic,
    required this.wantToLearn,
    required this.languages,
    required this.alreadyKnow,
  });

  final String slug;
  final String title;
  final String description;
  final bool isPublic;
  final List<String> wantToLearn;
  final List<String> languages;
  final List<String> alreadyKnow;
}

class _PathFormDialog extends StatefulWidget {
  const _PathFormDialog({
    required this.title,
    this.initial,
    this.lockSlug = false,
  });

  final String title;
  final _PathFormResult? initial;
  final bool lockSlug;

  @override
  State<_PathFormDialog> createState() => _PathFormDialogState();
}

class _PathFormDialogState extends State<_PathFormDialog> {
  late final TextEditingController _slug;
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _wantToLearn;
  late final TextEditingController _languages;
  late final TextEditingController _alreadyKnow;
  bool _isPublic = true;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _slug = TextEditingController(text: initial?.slug ?? '');
    _title = TextEditingController(text: initial?.title ?? '');
    _description = TextEditingController(text: initial?.description ?? '');
    _wantToLearn = TextEditingController(
      text: (initial?.wantToLearn ?? const <String>[]).join(', '),
    );
    _languages = TextEditingController(
      text: (initial?.languages ?? const <String>[]).join(', '),
    );
    _alreadyKnow = TextEditingController(
      text: (initial?.alreadyKnow ?? const <String>[]).join(', '),
    );
    _isPublic = initial?.isPublic ?? true;
  }

  @override
  void dispose() {
    _slug.dispose();
    _title.dispose();
    _description.dispose();
    _wantToLearn.dispose();
    _languages.dispose();
    _alreadyKnow.dispose();
    super.dispose();
  }

  List<String> _csv(String input) {
    return input
        .split(',')
        .map((v) => v.trim())
        .where((v) => v.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final slugText = _slug.text.trim();
    final titleText = _title.text.trim();
    final descriptionText = _description.text.trim();

    return AlertDialog(
      title: Text(widget.title),
      insetPadding: .zero,
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _slug,
              enabled: !widget.lockSlug,
              decoration: InputDecoration(
                labelText: 'Slug *',
                errorText: _submitted && slugText.isEmpty
                    ? 'Slug is required'
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _title,
              decoration: InputDecoration(
                labelText: 'Title *',
                errorText: _submitted && titleText.isEmpty
                    ? 'Title is required'
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _description,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Description *',
                errorText: _submitted && descriptionText.isEmpty
                    ? 'Description is required'
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _wantToLearn,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Want To Learn (comma-separated)',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _languages,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Languages (comma-separated)',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _alreadyKnow,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Already Know (comma-separated)',
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: _isPublic,
              title: const Text('Public'),
              contentPadding: EdgeInsets.zero,
              onChanged: (value) => setState(() => _isPublic = value),
            ),
          ],
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
            final slug = _slug.text.trim();
            final title = _title.text.trim();
            final description = _description.text.trim();
            if (slug.isEmpty || title.isEmpty || description.isEmpty) {
              return;
            }
            Navigator.of(context).pop(
              _PathFormResult(
                slug: slug,
                title: title,
                description: description,
                isPublic: _isPublic,
                wantToLearn: _csv(_wantToLearn.text),
                languages: _csv(_languages.text),
                alreadyKnow: _csv(_alreadyKnow.text),
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _ManageCoursesDialog extends StatefulWidget {
  const _ManageCoursesDialog({
    required this.path,
    required this.allCourses,
    required this.onAddCourses,
    required this.onRemoveCourse,
    required this.onReorder,
  });

  final AdminLearningPath path;
  final List<AdminCourseSummary> allCourses;
  final Future<void> Function(List<String> courseIds) onAddCourses;
  final Future<void> Function(String courseId) onRemoveCourse;
  final Future<void> Function(List<String> orderedCourseIds) onReorder;

  @override
  State<_ManageCoursesDialog> createState() => _ManageCoursesDialogState();
}

class _ManageCoursesDialogState extends State<_ManageCoursesDialog> {
  late List<AdminLearningPathCourse> _inPath;
  late Set<String> _selectedToAdd;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _inPath = [...widget.path.courses]
      ..sort((a, b) => a.position.compareTo(b.position));
    _selectedToAdd = <String>{};
  }

  List<AdminCourseSummary> get _available {
    final ids = _inPath.map((c) => c.courseId).toSet();
    return widget.allCourses
        .where((course) => !ids.contains(course.id))
        .toList();
  }

  Future<void> _call(Future<void> Function() action, String success) async {
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

  Future<void> _addSelected() async {
    final courseIds = _selectedToAdd.toList();
    if (courseIds.isEmpty) return;
    await _call(() => widget.onAddCourses(courseIds), 'Courses added');
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _removeCourse(String courseId) async {
    await _call(() => widget.onRemoveCourse(courseId), 'Course removed');
    if (!mounted) return;
    setState(
      () => _inPath = _inPath.where((c) => c.courseId != courseId).toList(),
    );
  }

  Future<void> _reorder(int index, int target) async {
    if (target < 0 || target >= _inPath.length) return;
    final updated = [..._inPath];
    final moved = updated.removeAt(index);
    updated.insert(target, moved);
    setState(() => _inPath = updated);
    await _call(
      () => widget.onReorder(updated.map((e) => e.courseId).toList()),
      'Courses reordered',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Manage Courses: ${widget.path.title}'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Courses in Path (${_inPath.length})',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              if (_inPath.isEmpty)
                const Text('No courses in this path')
              else
                ..._inPath.asMap().entries.map((entry) {
                  final index = entry.key;
                  final course = entry.value;
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(course.courseName),
                    subtitle: Text(course.courseLevel),
                    trailing: Wrap(
                      spacing: 2,
                      children: [
                        IconButton(
                          onPressed: _busy
                              ? null
                              : () => _reorder(index, index - 1),
                          icon: const Icon(Icons.arrow_upward),
                        ),
                        IconButton(
                          onPressed: _busy
                              ? null
                              : () => _reorder(index, index + 1),
                          icon: const Icon(Icons.arrow_downward),
                        ),
                        IconButton(
                          onPressed: _busy
                              ? null
                              : () => _removeCourse(course.courseId),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  );
                }),
              const Divider(height: 22),
              Text(
                'Available Courses (${_available.length})',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              if (_available.isEmpty)
                const Text('All available courses are already added')
              else
                ..._available.map(
                  (course) => CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    value: _selectedToAdd.contains(course.id),
                    title: Text(course.title),
                    subtitle: Text(course.level),
                    onChanged: _busy
                        ? null
                        : (value) {
                            setState(() {
                              if (value == true) {
                                _selectedToAdd.add(course.id);
                              } else {
                                _selectedToAdd.remove(course.id);
                              }
                            });
                          },
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
        FilledButton(
          onPressed: _busy ? null : _addSelected,
          child: const Text('Save Changes'),
        ),
      ],
    );
  }
}
