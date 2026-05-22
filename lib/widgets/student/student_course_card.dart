import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:skillforgeapp/config/asset_urls.dart';

class StudentCourseCard extends StatelessWidget {
  const StudentCourseCard({
    super.key,
    required this.course,
    required this.accent,
    required this.completed,
    required this.actionLabel,
    this.progressOverride,
  });

  final Map<String, dynamic> course;
  final Color accent;
  final bool completed;
  final String actionLabel;
  final double? progressOverride;

  double _percent(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse((value ?? '0').toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final id = (course['id'] ?? '').toString();
    final title = (course['title'] ?? course['slug'] ?? 'Course').toString();
    final level = (course['level'] ?? 'beginner').toString();
    final creatorMap = (course['creator'] is Map)
        ? (course['creator'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final creator = (creatorMap['displayName'] ?? '').toString();
    final creatorId = (creatorMap['id'] ?? creatorMap['userId'] ?? '')
        .toString();
    final isCreatorMe = creatorId == 'me';
    final creatorProfileId = isCreatorMe ? 'me' : creatorId;
    final thumbUrl = AssetUrls.courseThumbnailUrl(
      course['thumbnailS3Key']?.toString(),
    );
    final progress = (progressOverride ?? _percent(course['progressPercent']))
        .clamp(0.0, 100.0);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: id.isEmpty ? null : () => context.push('/student/courses/$id'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 132,
              width: double.infinity,
              child: thumbUrl == null
                  ? Container(
                      color: accent.withValues(alpha: 0.18),
                      child: Icon(
                        completed
                            ? Icons.check_circle
                            : Icons.menu_book_rounded,
                        color: accent,
                        size: 44,
                      ),
                    )
                  : Image.network(
                      thumbUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: accent.withValues(alpha: 0.18),
                        child: Icon(
                          Icons.menu_book_rounded,
                          color: accent,
                          size: 44,
                        ),
                      ),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Chip(
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        label: Text(level.toUpperCase()),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    if (creator.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: creatorProfileId.isEmpty
                            ? null
                            : () => context.push(
                                '/student/profile/$creatorProfileId',
                              ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 2,
                            vertical: 1,
                          ),
                          child: Text(
                            'By $creator',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Row(
                      children: [
                        const Text(
                          'Progress',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${progress.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: LinearProgressIndicator(
                        minHeight: 7,
                        value: progress / 100,
                        backgroundColor: accent.withValues(alpha: 0.14),
                        valueColor: AlwaysStoppedAnimation(accent),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: id.isEmpty
                            ? null
                            : () => context.push('/student/courses/$id'),
                        icon: Icon(
                          completed
                              ? Icons.replay_rounded
                              : Icons.play_arrow_rounded,
                        ),
                        label: Text(actionLabel),
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
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
