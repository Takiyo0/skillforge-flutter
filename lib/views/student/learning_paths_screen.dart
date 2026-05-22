import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skillforgeapp/config/asset_urls.dart';
import 'package:skillforgeapp/ui/design_system.dart';
import 'package:skillforgeapp/view_models/student/learning_paths_view_model.dart';

class LearningPathsPage extends ConsumerStatefulWidget {
  const LearningPathsPage({super.key});

  @override
  ConsumerState<LearningPathsPage> createState() => _LearningPathsPageState();
}

class _LearningPathsPageState extends ConsumerState<LearningPathsPage> {
  String? _joiningPathId;
  bool _isLeaving = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(learningPathsViewModelProvider);
    return AppPage(
      title: 'Learning Paths',
      subtitle: 'Choose your route and track progress',
      child: state.when(
        data: (data) {
          final allPaths = data.allPaths.data
              .whereType<Map<String, dynamic>>()
              .toList();
          final userPath = _userPathOrNull(data.userPath);
          final userPathId = userPath == null ? '' : _text(userPath['id']);

          if (allPaths.isEmpty && userPath == null) {
            return const Center(child: Text('No learning paths available yet'));
          }

          return RefreshIndicator(
            onRefresh: () async =>
                ref.refresh(learningPathsViewModelProvider.future),
            child: ListView(
              children: [
                if (userPath != null) ...[
                  _CurrentPathSection(
                    path: userPath,
                    isLeaving: _isLeaving,
                    onLeave: () => _leavePath(userPathId),
                  ),
                  const SizedBox(height: 20),
                ],
                Row(
                  children: [
                    Icon(
                      Icons.route_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'All Learning Paths',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (allPaths.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: Text('No learning paths available yet'),
                      ),
                    ),
                  )
                else
                  ...allPaths.map((path) {
                    final pathId = _text(path['id']);
                    final canJoin = userPath == null && pathId.isNotEmpty;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PathCard(
                        path: path,
                        canJoin: canJoin,
                        isJoining: _joiningPathId == pathId,
                        isCurrent: userPathId == pathId,
                        onJoin: canJoin ? () => _joinPath(pathId) : null,
                      ),
                    );
                  }),
              ],
            ),
          );
        },
        loading: AppAsyncState.loading,
        error: (e, _) => AppAsyncState.error('Failed to load paths: $e'),
      ),
    );
  }

  Future<void> _joinPath(String pathId) async {
    if (_joiningPathId != null) return;
    setState(() => _joiningPathId = pathId);
    try {
      final actions = ref.read(learningPathActionsProvider);
      final result = await actions.join(pathId);
      if (!mounted) return;
      AppToast.show(
        context,
        _text(
          result['message'],
          fallback: 'Joined learning path successfully.',
        ),
      );
      ref.invalidate(learningPathsViewModelProvider);
    } catch (e) {
      if (!mounted) return;
      AppToast.show(context, AppToast.errorMessage(e));
    } finally {
      if (mounted) setState(() => _joiningPathId = null);
    }
  }

  Future<void> _leavePath(String pathId) async {
    if (_isLeaving) return;
    setState(() => _isLeaving = true);
    try {
      final actions = ref.read(learningPathActionsProvider);
      final result = await actions.leave(pathId);
      if (!mounted) return;
      AppToast.show(
        context,
        _text(result['message'], fallback: 'Left learning path successfully.'),
      );
      ref.invalidate(learningPathsViewModelProvider);
    } catch (e) {
      if (!mounted) return;
      AppToast.show(context, AppToast.errorMessage(e));
    } finally {
      if (mounted) setState(() => _isLeaving = false);
    }
  }
}

class _CurrentPathSection extends StatelessWidget {
  const _CurrentPathSection({
    required this.path,
    required this.isLeaving,
    required this.onLeave,
  });

  final Map<String, dynamic> path;
  final bool isLeaving;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final pathId = _text(path['id'], fallback: 'path');
    final color = _seededColor(pathId);
    final courses = _courses(path);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.32)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.14),
            color.withValues(alpha: 0.05),
          ],
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Current Learning Path',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              OutlinedButton.icon(
                onPressed: isLeaving ? null : onLeave,
                icon: isLeaving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.logout_rounded),
                label: const Text('Leave'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(_text(path['title'], fallback: 'Untitled Path')),
          const SizedBox(height: 4),
          Text(_text(path['description'])),
          const SizedBox(height: 12),
          Text('Courses', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (courses.isEmpty)
            const Text('No courses in this path yet.')
          else
            ...courses.map((course) => _CurrentPathCourseCard(course: course)),
        ],
      ),
    );
  }
}

class _CurrentPathCourseCard extends StatelessWidget {
  const _CurrentPathCourseCard({required this.course});

  final Map<String, dynamic> course;

  @override
  Widget build(BuildContext context) {
    final id = _text(course['id']);
    final title = _text(course['title'], fallback: 'Untitled Course');
    final level = _text(course['level'], fallback: 'unknown');
    final language = _text(course['language'], fallback: '-');
    final progress = _num(course['progressPercent']).clamp(0, 100).toDouble();
    final completed = course['completed'] == true || progress >= 100;
    final thumbnail = _text(course['thumbnailS3Key']);
    final imageUrl = thumbnail.isEmpty
        ? null
        : AssetUrls.courseThumbnailUrl(thumbnail);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: id.isEmpty ? null : () => context.push('/student/courses/$id'),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: imageUrl == null
                      ? Container(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.14),
                          child: const Icon(Icons.menu_book_outlined),
                        )
                      : Image.network(imageUrl, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${level.toUpperCase()} • ${language.toUpperCase()}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    if (completed)
                      const Text(
                        'Done',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    else
                      LinearProgressIndicator(
                        value: progress / 100,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(99),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PathCard extends StatelessWidget {
  const _PathCard({
    required this.path,
    required this.canJoin,
    required this.isJoining,
    required this.isCurrent,
    required this.onJoin,
  });

  final Map<String, dynamic> path;
  final bool canJoin;
  final bool isJoining;
  final bool isCurrent;
  final VoidCallback? onJoin;

  @override
  Widget build(BuildContext context) {
    final pathId = _text(path['id'], fallback: 'path');
    final color = _seededColor(pathId);
    final criteria = _criteriaChips(path, limit: 4);
    final courses = _courses(path);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.26), width: 1.3),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.10),
            color.withValues(alpha: 0.04),
          ],
        ),
      ),
      padding: const EdgeInsets.all(14),
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
                      _text(path['title'], fallback: 'Untitled Path'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _text(path['description']),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isCurrent)
                Chip(label: const Text('Current'))
              else if (canJoin)
                FilledButton(
                  onPressed: isJoining ? null : onJoin,
                  child: isJoining
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Join'),
                ),
            ],
          ),
          if (criteria.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: criteria),
          ],
          const SizedBox(height: 10),
          Text(
            '${courses.length} course${courses.length == 1 ? '' : 's'}',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          if (courses.isEmpty)
            const Text('No courses in this path yet.')
          else ...[
            ...courses.take(3).map((course) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _PathCoursePreviewItem(course: course),
              );
            }),
            if (courses.length > 3)
              Text(
                '+${courses.length - 3} more courses',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ],
      ),
    );
  }
}

class _PathCoursePreviewItem extends StatelessWidget {
  const _PathCoursePreviewItem({required this.course});

  final Map<String, dynamic> course;

  @override
  Widget build(BuildContext context) {
    final courseId = _text(course['courseId'] ?? course['id']);
    final title = _text(
      course['courseName'] ?? course['title'],
      fallback: 'Untitled Course',
    );
    final description = _text(
      course['courseDescription'] ?? course['description'],
    );
    final level = _text(
      course['courseLevel'] ?? course['level'],
      fallback: 'unknown',
    );
    final language = _text(
      course['courseLanguage'] ?? course['language'],
      fallback: '-',
    );
    final completed = course['completed'] == true;
    final progress = _num(course['progressPercent']).clamp(0, 100).toDouble();

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: courseId.isEmpty
            ? null
            : () => context.push('/student/courses/$courseId'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(
                  completed
                      ? Icons.check_circle_outline
                      : Icons.menu_book_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _InlineTag(text: level),
                        _InlineTag(text: language),
                        if (completed)
                          const _InlineTag(text: 'done')
                        else
                          _InlineTag(text: '${progress.toInt()}%'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<Map<String, dynamic>> _courses(Map<String, dynamic> path) {
  return ((path['courses'] as List?) ?? const [])
      .whereType<Map>()
      .map((e) => e.cast<String, dynamic>())
      .toList();
}

Map<String, dynamic>? _userPathOrNull(dynamic value) {
  if (value is! Map) return null;
  final mapped = value.cast<String, dynamic>();
  if (_text(mapped['id']).isNotEmpty) return mapped;
  return null;
}

List<Widget> _criteriaChips(Map<String, dynamic> path, {int? limit}) {
  final criteria =
      (path['criteria'] as Map?)?.cast<String, dynamic>() ?? const {};
  final chips = <Widget>[];
  criteria.forEach((key, value) {
    if (value is List) {
      for (final item in value) {
        chips.add(_InlineTag(text: '$key: ${item.toString()}'));
      }
    } else if (value != null) {
      chips.add(_InlineTag(text: '$key: ${value.toString()}'));
    }
  });
  if (limit == null || chips.length <= limit) return chips;
  return chips.take(limit).toList();
}

class _InlineTag extends StatelessWidget {
  const _InlineTag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

String _text(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value.toString();
  return text.isEmpty ? fallback : text;
}

num _num(dynamic value) {
  if (value is num) return value;
  return num.tryParse(_text(value)) ?? 0;
}

Color _seededColor(String seed) {
  const colors = [
    Color(0xFFFF6B6B),
    Color(0xFF4ECDC4),
    Color(0xFF45B7D1),
    Color(0xFFFFA07A),
    Color(0xFF98D8C8),
    Color(0xFFF7DC6F),
    Color(0xFFBB8FCE),
    Color(0xFF85C1E9),
  ];
  return colors[seed.hashCode.abs() % colors.length];
}
