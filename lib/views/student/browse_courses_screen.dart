import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skillforgeapp/ui/design_system.dart';
import 'package:skillforgeapp/view_models/student/browse_courses_view_model.dart';
import 'package:skillforgeapp/widgets/student/student_course_card.dart';

class BrowseCoursesPage extends ConsumerWidget {
  const BrowseCoursesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(browseCoursesViewModelProvider);
    return AppPage(
      title: 'Browse Courses',
      subtitle: 'Pick your next quest',
      child: state.when(
        data: (response) => LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth > 980
                ? 4
                : constraints.maxWidth > 680
                ? 2
                : 1;
            return GridView.count(
              crossAxisCount: columns,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: columns == 1 ? 1.22 : 1.06,
              children: response.data
                  .whereType<Map>()
                  .map((e) => e.cast<String, dynamic>())
                  .map(
                    (course) => StudentCourseCard(
                      course: course,
                      accent: const Color(0xFF2563EB),
                      completed: false,
                      actionLabel: 'Explore',
                    ),
                  )
                  .toList(),
            );
          },
        ),
        loading: AppAsyncState.loading,
        error: (e, _) => AppAsyncState.error('Failed to load courses: $e'),
      ),
    );
  }
}
