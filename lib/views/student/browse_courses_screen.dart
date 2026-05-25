import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skillforgeapp/models/shared/paginated_response.dart';
import 'package:skillforgeapp/ui/design_system.dart';
import 'package:skillforgeapp/view_models/student/browse_courses_view_model.dart';
import 'package:skillforgeapp/widgets/student/student_course_card.dart';

class BrowseCoursesPage extends ConsumerStatefulWidget {
  const BrowseCoursesPage({super.key});

  @override
  ConsumerState<BrowseCoursesPage> createState() => _BrowseCoursesPageState();
}

class _BrowseCoursesPageState extends ConsumerState<BrowseCoursesPage> {
  final _searchController = TextEditingController();
  String _search = '';
  int _page = 1;

  BrowseCoursesQuery get _query =>
      (search: _search, page: _page, limit: browseCoursesPageSize);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applySearch() {
    setState(() {
      _search = _searchController.text.trim();
      _page = 1;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _search = '';
      _page = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(browseCoursesViewModelProvider(_query));
    return AppPage(
      title: 'Browse Courses',
      subtitle: 'Pick your next quest',
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ListView(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _applySearch(),
                      decoration: InputDecoration(
                        labelText: 'Search courses',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon:
                            _searchController.text.isEmpty && _search.isEmpty
                            ? null
                            : IconButton(
                                onPressed: _clearSearch,
                                icon: const Icon(Icons.close),
                                tooltip: 'Clear search',
                              ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _applySearch,
                    icon: const Icon(Icons.search),
                    tooltip: 'Search',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              state.when(
                data: (response) => _CourseGrid(
                  response: response,
                  page: _page,
                  maxWidth: constraints.maxWidth,
                  onPrevious: _page <= 1
                      ? null
                      : () => setState(() => _page -= 1),
                  onNext: _hasNextPage(response)
                      ? () => setState(() => _page += 1)
                      : null,
                ),
                loading: () => const SizedBox(
                  height: 320,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => SizedBox(
                  height: 320,
                  child: AppAsyncState.error('Failed to load courses: $e'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CourseGrid extends StatelessWidget {
  const _CourseGrid({
    required this.response,
    required this.page,
    required this.maxWidth,
    required this.onPrevious,
    required this.onNext,
  });

  final PaginatedResponse<Map<String, dynamic>> response;
  final int page;
  final double maxWidth;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final courses = response.data;
    final total = _intValue(response.pagination?['total']);
    final totalPages = _intValue(response.pagination?['totalPages']);
    final countText = total == null
        ? '${courses.length} shown'
        : '$total courses';
    final pageText = totalPages == null
        ? 'Page $page'
        : 'Page $page / $totalPages';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '$countText • $pageText',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            IconButton.outlined(
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Previous page',
            ),
            const SizedBox(width: 6),
            IconButton.outlined(
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Next page',
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (courses.isEmpty)
          const SizedBox(
            height: 260,
            child: Center(child: Text('No courses found.')),
          )
        else
          Builder(
            builder: (context) {
              final columns = maxWidth > 980
                  ? 4
                  : maxWidth > 680
                  ? 2
                  : 1;
              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: columns == 1 ? 1.22 : 1.06,
                children: courses
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
      ],
    );
  }
}

bool _hasNextPage(PaginatedResponse<Map<String, dynamic>> response) {
  final totalPages = _intValue(response.pagination?['totalPages']);
  final page = _intValue(response.pagination?['page']);
  if (totalPages != null && page != null) return page < totalPages;
  return response.data.length >= browseCoursesPageSize;
}

int? _intValue(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse((value ?? '').toString());
}
