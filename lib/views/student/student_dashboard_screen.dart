import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skillforgeapp/ui/design_system.dart';
import 'package:skillforgeapp/view_models/student/student_dashboard_view_model.dart';
import 'package:skillforgeapp/widgets/student/student_course_card.dart';

class StudentDashboardPage extends ConsumerWidget {
  const StudentDashboardPage({super.key});

  double _percent(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse((value ?? '0').toString()) ?? 0;
  }

  List<Map<String, dynamic>> _courseList(dynamic raw) {
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(studentDashboardViewModelProvider);

    return AppPage(
      title: 'Home Base',
      subtitle: 'Pick up where you left off',
      child: data.when(
        loading: AppAsyncState.loading,
        error: (error, _) =>
            AppAsyncState.error('Failed to load dashboard: $error'),
        data: (value) {
          final user = value['user'];
          final xp = (value['xp'] as Map<String, dynamic>? ?? const {});
          final streak = (value['streak'] as Map<String, dynamic>? ?? const {});
          final badges = (value['badges'] as Map<String, dynamic>? ?? const {});
          final courses = _courseList(value['courses']);

          final activeCourses = courses
              .where((course) => _percent(course['progressPercent']) < 100)
              .toList();
          final completedCourses = courses
              .where((course) => _percent(course['progressPercent']) >= 100)
              .toList();

          final displayName = user?.displayName?.toString() ?? '';
          final xpInto = xp['xpIntoCurrentLevel'] ?? 0;
          final currentMaxXp =
              (xp['xpForNextLevel'] ?? 0) - (xp['xpForCurrentLevel'] ?? 0);
          final levelProgress = (_percent(xp['progressPercent']) / 100).clamp(
            0.0,
            1.0,
          );
          final badgeCount = ((badges['badges'] as List?) ?? const []).length;

          return ListView(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2563EB), Color(0xFF0EA5E9)],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x332563EB),
                      blurRadius: 24,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'HOME BASE',
                      style: TextStyle(
                        color: Color(0xFFE0F2FE),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Good to see you${displayName.isEmpty ? '' : ', $displayName'}.',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Pick up where you left off and keep your progress moving.',
                      style: TextStyle(
                        color: Color(0xFFE0F2FE),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.16),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Level Progress',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '$xpInto / $currentMaxXp XP',
                                style: const TextStyle(
                                  color: Color(0xFFE0F2FE),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: LinearProgressIndicator(
                              minHeight: 10,
                              value: levelProgress,
                              backgroundColor: Colors.black.withValues(
                                alpha: 0.32,
                              ),
                              valueColor: const AlwaysStoppedAnimation(
                                Color(0xFFF59E0B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final columns = width > 720 ? 4 : 2;
                        return GridView.count(
                          crossAxisCount: columns,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: columns == 4 ? 1.8 : 2.2,
                          children: [
                            _HeroStat(
                              label: 'Level',
                              value: '${xp['level'] ?? 1}',
                            ),
                            _HeroStat(
                              label: 'Total XP',
                              value: '${xp['totalXp'] ?? 0}',
                            ),
                            _HeroStat(
                              label: 'Streak',
                              value: '${streak['currentStreakDays'] ?? 0}d',
                            ),
                            _HeroStat(label: 'Badges', value: '$badgeCount'),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _CourseSection(
                title: 'Active Courses',
                icon: Icons.track_changes,
                accent: const Color(0xFF2563EB),
                courses: activeCourses,
                completed: false,
              ),
              if (completedCourses.isNotEmpty) ...[
                const SizedBox(height: 18),
                _CourseSection(
                  title: 'Completed Courses',
                  icon: Icons.star_rounded,
                  accent: const Color(0xFF16A34A),
                  courses: completedCourses,
                  completed: true,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFDFF6FF),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseSection extends StatelessWidget {
  const _CourseSection({
    required this.title,
    required this.icon,
    required this.accent,
    required this.courses,
    required this.completed,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final List<Map<String, dynamic>> courses;
  final bool completed;

  double _percent(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse((value ?? '0').toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: accent),
            const SizedBox(width: 8),
            Text(
              '$title (${courses.length})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (courses.isEmpty)
          Card(
            child: ListTile(
              leading: Icon(Icons.menu_book_outlined, color: accent),
              title: const Text('No courses enrolled yet'),
              subtitle: const Text('Browse the catalog to start learning.'),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth > 980
                  ? 4
                  : constraints.maxWidth > 680
                  ? 2
                  : 1;
              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: columns == 1 ? 1.22 : 1.06,
                children: courses.map((course) {
                  return StudentCourseCard(
                    course: course,
                    accent: accent,
                    completed: completed,
                    progressOverride: _percent(course['progressPercent']),
                    actionLabel: completed ? 'Open' : 'Continue',
                  );
                }).toList(),
              );
            },
          ),
      ],
    );
  }
}
