import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skillforgeapp/config/asset_urls.dart';
import 'package:skillforgeapp/ui/design_system.dart';
import 'package:skillforgeapp/view_models/student/course_detail_view_model.dart';

class CourseDetailPage extends ConsumerStatefulWidget {
  const CourseDetailPage({super.key, required this.courseId});

  final String courseId;

  @override
  ConsumerState<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends ConsumerState<CourseDetailPage> {
  String? _expanded;

  List<Map<String, dynamic>> _toMapList(dynamic raw) {
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(courseDetailViewModelProvider(widget.courseId));

    return AppPage(
      title: 'Course Detail',
      subtitle: widget.courseId,
      child: state.when(
        loading: AppAsyncState.loading,
        error: (e, _) => AppAsyncState.error('Failed to load course: $e'),
        data: (value) {
          final detail = (value['detail'] as Map<String, dynamic>?) ?? const {};
          final unitsPayload =
              (value['units'] as Map<String, dynamic>?) ?? const {};
          final progress = value['progress'] as Map<String, dynamic>?;

          final unitProgress = _toMapList(progress?['unitProgress']);
          final units = _toMapList(unitsPayload['units']).isNotEmpty
              ? _toMapList(unitsPayload['units'])
              : _toMapList(unitsPayload['data']);

          final thumbUrl = AssetUrls.courseThumbnailUrl(
            detail['thumbnailS3Key']?.toString(),
          );

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(courseDetailViewModelProvider(widget.courseId));
              await ref.read(
                courseDetailViewModelProvider(widget.courseId).future,
              );
            },
            child: ListView(
              children: [
                if (thumbUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        thumbUrl,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                Text(
                  (detail['title'] ?? '-').toString(),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text((detail['description'] ?? '').toString()),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => context.push(
                    '/student/courses/${widget.courseId}/forums',
                  ),
                  icon: const Icon(Icons.forum_outlined),
                  label: const Text('Open Forums'),
                ),
                const SizedBox(height: 8),
                if (progress == null)
                  FilledButton(
                    onPressed: () async {
                      await ref
                          .read(courseDetailActionsProvider.notifier)
                          .enroll(widget.courseId);
                      ref.invalidate(
                        courseDetailViewModelProvider(widget.courseId),
                      );
                    },
                    child: const Text('Enroll Now'),
                  )
                else
                  Card(
                    child: ListTile(
                      title: const Text('Enrollment Active'),
                      subtitle: Text(
                        'Progress: ${progress['progressPercent'] ?? 0}% • '
                        '${progress['completedUnits'] ?? 0}/${progress['totalUnits'] ?? 0} units',
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  'Course Units',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...units.asMap().entries.map((entry) {
                  final u = entry.value;
                  final unitId = (u['id'] ?? '').toString();
                  final p = unitProgress
                      .where((it) => (it['unitId'] ?? '').toString() == unitId)
                      .toList();
                  final status = p.isNotEmpty
                      ? (p.first['status'] ?? '').toString()
                      : (progress == null ? 'locked' : 'available');
                  final score = p.isNotEmpty
                      ? (p.first['lastScorePercent'] ?? 0)
                      : 0;
                  final isLocked = status == 'locked';
                  final isCompleted = status == 'completed';
                  final isInProgress = status == 'in_progress';
                  final expanded = _expanded == unitId;
                  final actionLabel = isCompleted
                      ? 'Open Unit'
                      : status == 'available'
                      ? 'Start Unit'
                      : isInProgress
                      ? 'Continue Unit'
                      : 'Open Unit';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      color: isCompleted
                          ? Colors.green.withValues(alpha: 0.12)
                          : null,
                      child: Column(
                        children: [
                          ListTile(
                            onTap: isLocked
                                ? null
                                : () => setState(
                                    () => _expanded = expanded ? null : unitId,
                                  ),
                            leading: isCompleted
                                ? const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  )
                                : isLocked
                                ? const Icon(Icons.lock_outline)
                                : CircleAvatar(child: Text('${entry.key + 1}')),
                            title: Text((u['title'] ?? '-').toString()),
                            subtitle: Text(
                              '${(u['type'] ?? 'unit').toString().replaceAll('_', ' ')} • ${(u['estimatedMinutes'] ?? '-')} min',
                            ),
                            trailing: Icon(
                              expanded ? Icons.expand_less : Icons.expand_more,
                            ),
                          ),
                          if (expanded && !isLocked)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text((u['summary'] ?? '').toString()),
                                  const SizedBox(height: 8),
                                  LinearProgressIndicator(
                                    value:
                                        ((score is num ? score.toDouble() : 0) /
                                                100)
                                            .clamp(0, 1),
                                  ),
                                  const SizedBox(height: 6),
                                  Text('Status: $status • Score: $score%'),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton(
                                      onPressed: progress == null
                                          ? null
                                          : () async {
                                              await context.push(
                                                '/student/courses/${widget.courseId}/units/$unitId',
                                              );
                                              if (!mounted) return;
                                              ref.invalidate(
                                                courseDetailViewModelProvider(
                                                  widget.courseId,
                                                ),
                                              );
                                            },
                                      child: Text(actionLabel),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}
