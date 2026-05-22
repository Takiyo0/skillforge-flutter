import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skillforgeapp/config/asset_urls.dart';
import 'package:skillforgeapp/models/admin/admin_models.dart';
import 'package:skillforgeapp/ui/design_system.dart';
import 'package:skillforgeapp/view_models/admin/admin_courses_view_model.dart';
import 'package:skillforgeapp/widgets/shared/app_status_badge.dart';

class AdminCoursesPage extends ConsumerStatefulWidget {
  const AdminCoursesPage({super.key});

  @override
  ConsumerState<AdminCoursesPage> createState() => _AdminCoursesPageState();
}

class _AdminCoursesPageState extends ConsumerState<AdminCoursesPage> {
  List<AdminCourse> _courses = const [];
  List<SandboxLanguageSummary> _languages = const [];
  bool _loading = true;
  bool _busy = false;
  String? _error;
  String _query = '';

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
      final repo = ref.read(adminCoursesActionsProvider.notifier);
      final courses = await repo.getAdminCourses();
      final languages = await repo.getSandboxLanguageCatalog();
      if (!mounted) return;
      setState(() {
        _courses = courses;
        _languages = languages;
      });
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _error = 'Failed to load courses: ${AppToast.errorMessage(e)}',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(String message) {
    AppToast.show(context, message);
  }

  List<AdminCourse> get _filteredCourses {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _courses;
    return _courses.where((course) {
      return course.title.toLowerCase().contains(q) ||
          course.subtitle.toLowerCase().contains(q) ||
          course.language.toLowerCase().contains(q) ||
          course.level.toLowerCase().contains(q) ||
          course.creator.displayName.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _openCreateDialog() async {
    final result = await showAppDialog<_CourseFormResult>(
      context: context,
      useRootNavigator: true,
      builder: (context) =>
          _CourseFormDialog(title: 'Create Course', languages: _languages),
    );
    if (result == null) return;

    setState(() => _busy = true);
    try {
      final repo = ref.read(adminCoursesActionsProvider.notifier);
      var course = await repo.createAdminCourse(
        title: result.title,
        subtitle: result.subtitle,
        description: result.description,
        level: result.level,
        language: result.language,
        priceCents: result.priceCents,
        currencyCode: result.currencyCode,
        trailerUrl: result.trailerUrl,
      );
      if (result.thumbnailBytes != null && result.thumbnailName != null) {
        course = await repo.uploadAdminCourseThumbnail(
          courseId: course.id,
          fileName: result.thumbnailName!,
          bytes: result.thumbnailBytes!,
          contentType: _imageMimeType(result.thumbnailName!),
        );
      }
      if (!mounted) return;
      setState(() => _courses = [..._courses, course]);
      _toast('Course created');
    } catch (e) {
      _toast('Failed to create course: ${AppToast.errorMessage(e)}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  int _unitCountForType(AdminCourse course, String type) {
    return course.units.where((unit) => unit.type == type).length;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredCourses;

    return AppPage(
      title: 'Courses',
      subtitle: 'Manage courses and jump into unit setup',
      child: ListView(
        children: [
          GlassPanel(
            radius: 20,
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
                            'Manage Courses',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_courses.length} course(s) created',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _busy ? null : _openCreateDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('New Course'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    labelText: 'Search courses',
                    prefixIcon: Icon(Icons.search),
                  ),
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
          else if (filtered.isEmpty)
            GlassPanel(
              radius: 18,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    const Text('No courses found'),
                    const SizedBox(height: 10),
                    FilledButton(
                      onPressed: _busy ? null : _openCreateDialog,
                      child: const Text('Create Course'),
                    ),
                  ],
                ),
              ),
            )
          else
            ...filtered.map(
              (course) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _CourseCard(
                  course: course,
                  onTap: () => context.push('/admin/courses/${course.id}'),
                  stats: _CourseStats(
                    units: course.unitCount,
                    modules: _unitCountForType(course, 'module'),
                    exercises: _unitCountForType(course, 'exercise'),
                    quizzes: _unitCountForType(course, 'assessment'),
                    finalExams: _unitCountForType(course, 'final_exam'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({
    required this.course,
    required this.onTap,
    required this.stats,
  });

  final AdminCourse course;
  final VoidCallback onTap;
  final _CourseStats stats;

  @override
  Widget build(BuildContext context) {
    final thumbUrl = AssetUrls.courseThumbnailUrl(course.thumbnailS3Key);
    final priceLabel =
        '${(course.priceCents / 100).toStringAsFixed(2)} ${course.currencyCode}';

    return GlassPanel(
      radius: 18,
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CourseThumb(url: thumbUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                course.title,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                course.subtitle,
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        AppStatusBadge(
                          label: course.isPublished ? 'Published' : 'Draft',
                          color: course.isPublished
                              ? Colors.green
                              : Colors.amber,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      course.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${course.creator.displayName} • ${course.level} • ${course.language} • $priceLabel',
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${stats.units} units',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        _CourseBreakdownButton(stats: stats),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseThumb extends StatelessWidget {
  const _CourseThumb({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 84,
        height: 84,
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.14),
        child: url == null
            ? const Icon(Icons.menu_book_outlined, size: 30)
            : Image.network(url!, fit: BoxFit.cover),
      ),
    );
  }
}

class _CourseStats {
  const _CourseStats({
    required this.units,
    required this.modules,
    required this.exercises,
    required this.quizzes,
    required this.finalExams,
  });

  final int units;
  final int modules;
  final int exercises;
  final int quizzes;
  final int finalExams;
}

class _CourseBreakdownButton extends StatelessWidget {
  const _CourseBreakdownButton({required this.stats});

  final _CourseStats stats;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => showAppBottomSheet<void>(
        context: context,
        initialChildSize: 0.42,
        minChildSize: 0.28,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Course Content',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _BottomSheetStatRow(label: 'Units', value: '${stats.units}'),
              _BottomSheetStatRow(label: 'Modules', value: '${stats.modules}'),
              _BottomSheetStatRow(
                label: 'Exercises',
                value: '${stats.exercises}',
              ),
              _BottomSheetStatRow(label: 'Quizzes', value: '${stats.quizzes}'),
              _BottomSheetStatRow(
                label: 'Final Exams',
                value: '${stats.finalExams}',
              ),
            ],
          ),
        ),
      ),
      icon: const Icon(Icons.analytics_outlined, size: 18),
      label: const Text('Breakdown'),
    );
  }
}

class _BottomSheetStatRow extends StatelessWidget {
  const _BottomSheetStatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _CourseFormResult {
  const _CourseFormResult({
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

class _CourseFormDialog extends StatefulWidget {
  const _CourseFormDialog({
    required this.title,
    required this.languages,
    this.initial,
  });

  final String title;
  final List<SandboxLanguageSummary> languages;
  final AdminCourse? initial;

  @override
  State<_CourseFormDialog> createState() => _CourseFormDialogState();
}

class _CourseFormDialogState extends State<_CourseFormDialog> {
  static const _levels = ['beginner', 'intermediate', 'advanced'];
  static const _currencies = ['IDR', 'USD', 'EUR', 'GBP', 'JPY', 'CNY'];

  late final TextEditingController _title;
  late final TextEditingController _subtitle;
  late final TextEditingController _description;
  late final TextEditingController _priceCents;
  late final TextEditingController _trailerUrl;
  String _level = 'beginner';
  String _language = 'javascript';
  String _currency = 'IDR';
  Uint8List? _thumbnailBytes;
  String? _thumbnailName;
  bool _submitted = false;
  String? _previewUrl;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    final fallbackLanguage = widget.languages.isEmpty
        ? 'javascript'
        : widget.languages.first.id;
    _title = TextEditingController(text: initial?.title ?? '');
    _subtitle = TextEditingController(text: initial?.subtitle ?? '');
    _description = TextEditingController(text: initial?.description ?? '');
    _priceCents = TextEditingController(
      text: (initial?.priceCents ?? 0).toString(),
    );
    _trailerUrl = TextEditingController(text: initial?.trailerUrl ?? '');
    _level = initial?.level.isNotEmpty == true ? initial!.level : 'beginner';
    _language = initial?.language.isNotEmpty == true
        ? initial!.language
        : fallbackLanguage;
    _currency = initial?.currencyCode.isNotEmpty == true
        ? initial!.currencyCode
        : 'IDR';
    _previewUrl = AssetUrls.courseThumbnailUrl(initial?.thumbnailS3Key);
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
      title: Text(widget.title),
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
                label: Text(
                  _thumbnailName == null
                      ? 'Upload Thumbnail'
                      : 'Replace Thumbnail',
                ),
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
              _CourseFormResult(
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

String _imageMimeType(String fileName) {
  final lower = fileName.toLowerCase();
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.gif')) return 'image/gif';
  if (lower.endsWith('.webp')) return 'image/webp';
  return 'application/octet-stream';
}
