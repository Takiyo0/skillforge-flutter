import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:skillforgeapp/providers/app_state.dart';
import 'package:skillforgeapp/config/asset_urls.dart';
import 'package:skillforgeapp/ui/design_system.dart';
import 'package:skillforgeapp/view_models/student/profile_view_model.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileViewModelProvider(userId));
    final currentUser = ref.watch(sessionProvider).user;

    return AppPage(
      title: 'Profile',
      subtitle: userId == 'me' ? 'Your profile' : 'User details',
      child: state.when(
        loading: AppAsyncState.loading,
        error: (e, _) => AppAsyncState.error('Failed profile: $e'),
        data: (profile) {
          final profileId = _text(profile['id'], fallback: userId);
          final isOwnProfile =
              userId == 'me' ||
              (currentUser != null && currentUser.id == profileId);
          final email = isOwnProfile ? currentUser?.email : null;
          final recentActivity = _mapList(profile['recentActivity']);
          final badges = _mapList(profile['badges']);
          final enrolledCourses = _mapList(profile['enrolledCourses']);
          final certificates = _mapList(profile['certificates']);
          final currentCourses = enrolledCourses.where((course) {
            final progress = _map(course['progress']);
            return _number(progress['progressPercent']) < 100;
          }).toList();
          final completedCourses = enrolledCourses.where((course) {
            final progress = _map(course['progress']);
            return _number(progress['progressPercent']) >= 100;
          }).toList();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(profileViewModelProvider(userId));
              await ref.read(profileViewModelProvider(userId).future);
            },
            child: ListView(
              children: [
                _ProfileHeader(profile: profile, profileId: profileId),
                const SizedBox(height: 14),
                _ActivityHeatmap(events: recentActivity),
                const SizedBox(height: 14),
                _BadgesSection(badges: badges),
                const SizedBox(height: 14),
                _CoursesSection(
                  title: 'Currently Learning',
                  icon: Icons.menu_book_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  courses: currentCourses,
                  completed: false,
                ),
                const SizedBox(height: 14),
                _CoursesSection(
                  title: 'Completed',
                  icon: Icons.workspace_premium_outlined,
                  color: Colors.green,
                  courses: completedCourses,
                  completed: true,
                ),
                const SizedBox(height: 14),
                _CertificatesSection(certificates: certificates),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile, required this.profileId});

  final Map<String, dynamic> profile;
  final String profileId;

  @override
  Widget build(BuildContext context) {
    final displayName = _text(profile['displayName'], fallback: 'Unknown User');
    final bio = _text(profile['bio']);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 132, color: _seededColor(profileId)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Transform.translate(
                  offset: const Offset(0, -44),
                  child: _ProfileAvatar(
                    avatarS3Key: (profile['avatarS3Key'] ?? profile['avatar'])
                        ?.toString(),
                    seed: profileId,
                    size: 112,
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -26),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        bio.isEmpty ? 'No bio yet' : bio,
                        style: bio.isEmpty
                            ? Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontStyle: FontStyle.italic,
                              )
                            : Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -10),
                  child: _StatsGrid(
                    stats: [
                      _StatData(
                        label: 'Level',
                        value: _number(profile['level']).toInt().toString(),
                        icon: Icons.trending_up,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      _StatData(
                        label: 'Total XP',
                        value: _formatInt(
                          _number(
                            profile['totalXp'] ?? profile['totalXP'],
                          ).toInt(),
                        ),
                        icon: Icons.bolt,
                        color: Colors.amber,
                      ),
                      _StatData(
                        label: 'Streak',
                        value:
                            '${_number(profile['currentStreak'] ?? profile['currentStreakDays']).toInt()}',
                        helper: 'Days',
                        icon: Icons.local_fire_department,
                        color: Colors.deepOrange,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityHeatmap extends StatelessWidget {
  const _ActivityHeatmap({required this.events});

  final List<Map<String, dynamic>> events;

  @override
  Widget build(BuildContext context) {
    final days = _heatmapDays(events);
    return _SectionCard(
      title: 'Activity',
      icon: Icons.calendar_month_outlined,
      color: Theme.of(context).colorScheme.primary,
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: days.map((day) {
          final color = _heatmapColor(context, day.intensity);
          return Tooltip(
            message: '${day.date}: ${day.count} events',
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _BadgesSection extends StatelessWidget {
  const _BadgesSection({required this.badges});

  final List<Map<String, dynamic>> badges;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Badges (${badges.length})',
      icon: Icons.emoji_events_outlined,
      color: Colors.amber,
      child: badges.isEmpty
          ? const Text('This user does not have any badges yet.')
          : LayoutBuilder(
              builder: (context, constraints) {
                final width = _tileWidth(constraints.maxWidth, minWidth: 150);
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: badges.map((badge) {
                    final badgeId = _text(badge['badgeId'] ?? badge['id']);
                    final color = _seededColor(
                      badgeId.isEmpty
                          ? _text(badge['name'], fallback: 'badge')
                          : badgeId,
                    );
                    final iconS3Key = _text(
                      badge['iconS3Key'] ?? badge['icon'],
                    );
                    return SizedBox(
                      width: width,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              color.withValues(alpha: 0.22),
                              color.withValues(alpha: 0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: color.withValues(alpha: 0.32),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _BadgeIcon(
                              iconS3Key: iconS3Key,
                              badgeId: badgeId,
                              size: 44,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _text(badge['name'], fallback: 'Badge'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _text(badge['description']),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _date(badge['awardedAt'] ?? badge['earnedAt']),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
    );
  }
}

class _CoursesSection extends StatelessWidget {
  const _CoursesSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.courses,
    required this.completed,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<Map<String, dynamic>> courses;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '$title (${courses.length})',
      icon: icon,
      color: color,
      child: courses.isEmpty
          ? Text(
              completed
                  ? 'This user does not have any completed courses yet.'
                  : 'This user is not learning any courses yet.',
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final width = _tileWidth(constraints.maxWidth, minWidth: 260);
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: courses.map((course) {
                    return SizedBox(
                      width: width,
                      child: _CourseCard(
                        course: course,
                        color: color,
                        completed: completed,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
    );
  }
}

class _CertificatesSection extends StatelessWidget {
  const _CertificatesSection({required this.certificates});

  final List<Map<String, dynamic>> certificates;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Certificates (${certificates.length})',
      icon: Icons.workspace_premium_outlined,
      color: Colors.yellow.shade700,
      child: certificates.isEmpty
          ? const Text('This user does not have any certificates yet.')
          : LayoutBuilder(
              builder: (context, constraints) {
                final width = _tileWidth(constraints.maxWidth, minWidth: 260);
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: certificates.map((cert) {
                    final certId = _text(cert['certificateId'] ?? cert['id']);
                    return SizedBox(
                      width: width,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: certId.isEmpty
                            ? null
                            : () =>
                                  context.push('/student/certificates/$certId'),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.military_tech,
                                color: Colors.amber,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _text(
                                  cert['courseName'],
                                  fallback: 'Certificate',
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _text(cert['certificateCode'], fallback: '-'),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _date(cert['issuedAt']),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({
    required this.course,
    required this.color,
    required this.completed,
  });

  final Map<String, dynamic> course;
  final Color color;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final progress = _map(course['progress']);
    final courseId = _text(course['courseId'] ?? course['id']);
    final percent = _number(
      progress['progressPercent'],
    ).clamp(0, 100).toDouble();
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: courseId.isEmpty
          ? null
          : () => context.push('/student/courses/$courseId'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: completed ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.30)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _text(
                course['courseTitle'] ?? course['title'],
                fallback: 'Course',
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              _text(
                course['courseLevel'] ?? course['level'],
                fallback: 'Level n/a',
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            if (completed)
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Chip(
                    avatar: const Icon(Icons.check, size: 16),
                    label: const Text('Completed'),
                    backgroundColor: Colors.green.withValues(alpha: 0.16),
                  ),
                  Text(
                    '${_number(progress['totalUnits']).toInt()} units',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              )
            else ...[
              Row(
                children: [
                  const Text(
                    'Progress',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  Text(
                    '${percent.toInt()}%',
                    style: TextStyle(color: color, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: percent / 100,
                  backgroundColor: color.withValues(alpha: 0.14),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_number(progress['completedUnits']).toInt()} / '
                '${_number(progress['totalUnits']).toInt()} units',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final List<_StatData> stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = _tileWidth(constraints.maxWidth, minWidth: 96);
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: stats
              .map(
                (stat) => SizedBox(
                  width: width,
                  child: _StatCard(stat: stat),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.stat});

  final _StatData stat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: stat.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: stat.color.withValues(alpha: 0.30)),
      ),
      child: Column(
        children: [
          Icon(stat.icon, color: stat.color),
          const SizedBox(height: 6),
          Text(
            stat.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: stat.color,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            stat.label.toUpperCase(),
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (stat.helper != null) ...[
            const SizedBox(height: 2),
            Text(stat.helper!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.avatarS3Key,
    required this.seed,
    required this.size,
  });

  final String? avatarS3Key;
  final String seed;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url =
        AssetUrls.avatarUrl(avatarS3Key) ?? AssetUrls.dicebearAvatarUrl(seed);
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _NetworkAsset(url: url, fit: BoxFit.cover),
      ),
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  const _BadgeIcon({
    required this.iconS3Key,
    required this.badgeId,
    required this.size,
  });

  final String iconS3Key;
  final String badgeId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = AssetUrls.courseThumbnailUrl(iconS3Key);
    if (url == null) {
      return Text(
        _badgeEmoji(badgeId),
        style: TextStyle(fontSize: size * 0.82),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: size,
        height: size,
        child: _NetworkAsset(url: url, fit: BoxFit.cover),
      ),
    );
  }
}

class _NetworkAsset extends StatelessWidget {
  const _NetworkAsset({required this.url, required this.fit});

  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (AssetUrls.isSvgUrl(url)) {
      return SvgPicture.network(url, fit: fit);
    }
    return Image.network(url, fit: fit);
  }
}

class _StatData {
  const _StatData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.helper,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? helper;
}

class _HeatmapDay {
  const _HeatmapDay({
    required this.date,
    required this.count,
    required this.intensity,
  });

  final String date;
  final int count;
  final int intensity;
}

List<_HeatmapDay> _heatmapDays(List<Map<String, dynamic>> events) {
  final eventsByDate = <String, int>{};
  for (final event in events) {
    final raw = _text(event['createdAt']);
    if (raw.isEmpty) continue;
    final date = _dateKey(raw);
    final count = _number(event['eventCount']).toInt();
    final safeCount = count.clamp(0, 999999).toInt();
    eventsByDate[date] = (eventsByDate[date] ?? 0) + safeCount;
  }

  final today = DateTime.now();
  return List.generate(26 * 7, (index) {
    final date = today.subtract(Duration(days: (26 * 7 - 1) - index));
    final key = _dateKey(date.toIso8601String());
    final count = eventsByDate[key] ?? 0;
    final intensity = count == 0 ? 0 : (count / 2).ceil().clamp(1, 5).toInt();
    return _HeatmapDay(date: key, count: count, intensity: intensity);
  });
}

Color _heatmapColor(BuildContext context, int intensity) {
  final primary = Theme.of(context).colorScheme.primary;
  switch (intensity) {
    case 0:
      return primary.withValues(alpha: 0.12);
    case 1:
      return primary.withValues(alpha: 0.26);
    case 2:
      return primary.withValues(alpha: 0.42);
    case 3:
      return primary.withValues(alpha: 0.62);
    case 4:
      return primary.withValues(alpha: 0.78);
    default:
      return primary;
  }
}

List<Map<String, dynamic>> _mapList(dynamic value) {
  if (value is! List) return const [];
  return value.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map) return value.cast<String, dynamic>();
  return const {};
}

String _text(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value.toString();
  return text.isEmpty ? fallback : text;
}

num _number(dynamic value) {
  if (value is num) return value;
  return num.tryParse(_text(value)) ?? 0;
}

String _formatInt(int value) {
  final raw = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    final remaining = raw.length - i;
    buffer.write(raw[i]);
    if (remaining > 1 && remaining % 3 == 1) buffer.write(',');
  }
  return buffer.toString();
}

String _date(dynamic value) {
  final raw = _text(value, fallback: '-');
  if (raw == '-') return raw;
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;
  return _dateKey(parsed.toIso8601String());
}

String _dateKey(String raw) {
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) {
    return raw.contains('T') ? raw.split('T').first : raw;
  }
  final date = parsed.toLocal();
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
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
    Color(0xFF85C1E2),
    Color(0xFFF8B88B),
    Color(0xFFABEBC6),
  ];

  var hash = 0;
  for (final codeUnit in seed.codeUnits) {
    hash = codeUnit + ((hash << 5) - hash);
  }
  return colors[hash.abs() % colors.length];
}

String _badgeEmoji(String seed) {
  const emojis = ['🏆', '⭐', '🎖️', '🥇', '🥈', '🥉', '🎗️', '✨', '🌟', '💎'];
  if (seed.isEmpty) return emojis.first;
  final hash = seed.codeUnits.fold<int>(0, (total, code) => total + code);
  return emojis[hash % emojis.length];
}

double _tileWidth(double maxWidth, {required double minWidth}) {
  if (maxWidth <= minWidth) return maxWidth;
  final columns = (maxWidth / minWidth).floor().clamp(1, 4).toInt();
  final spacing = 10 * (columns - 1);
  return (maxWidth - spacing) / columns;
}
