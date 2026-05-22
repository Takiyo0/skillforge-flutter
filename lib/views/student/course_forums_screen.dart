import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skillforgeapp/ui/design_system.dart';
import 'package:skillforgeapp/view_models/student/forum_view_models.dart';
import 'package:skillforgeapp/widgets/shared/forum_widgets.dart';
import 'package:skillforgeapp/widgets/student/forum_common_widgets.dart';

class CourseForumsPage extends ConsumerStatefulWidget {
  const CourseForumsPage({super.key, required this.courseId});

  final String courseId;

  @override
  ConsumerState<CourseForumsPage> createState() => _CourseForumsPageState();
}

class _CourseForumsPageState extends ConsumerState<CourseForumsPage> {
  final _title = TextEditingController();
  final _content = TextEditingController();
  bool _showCreate = false;

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(courseForumsViewModelProvider(widget.courseId));
    final title = vm.courseName.isEmpty
        ? 'Course Forums'
        : '${vm.courseName} Forums';

    return AppPage(
      title: 'Course Forums',
      subtitle: vm.courseName.isEmpty ? widget.courseId : vm.courseName,
      child: RefreshIndicator(
        onRefresh: () => vm.load(),
        child: ListView(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      const Text('Discuss this course with classmates.'),
                    ],
                  ),
                ),
                IconButton.filled(
                  onPressed: () => setState(() => _showCreate = !_showCreate),
                  icon: Icon(_showCreate ? Icons.close : Icons.add),
                  tooltip: _showCreate ? 'Cancel' : 'New thread',
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search threads...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: vm.setSearch,
            ),
            if (vm.error != null) ...[
              const SizedBox(height: 10),
              ForumErrorPanel(message: vm.error!),
            ],
            if (_showCreate) ...[
              const SizedBox(height: 10),
              ForumComposePostCard(
                titleLabel: 'Thread title',
                contentLabel: 'Thread content',
                submitLabel: 'Post Thread',
                submittingLabel: 'Posting...',
                titleController: _title,
                contentController: _content,
                isSubmitting: vm.isSubmitting,
                onSubmit: () async {
                  final created = await vm.createPost(
                    title: _title.text,
                    content: _content.text,
                  );
                  if (created == null || !context.mounted) return;
                  final id = (created['id'] ?? '').toString();
                  setState(() => _showCreate = false);
                  _title.clear();
                  _content.clear();
                  if (id.isNotEmpty) {
                    context.push(
                      '/student/courses/${widget.courseId}/forums/$id',
                    );
                  }
                },
              ),
            ],
            const SizedBox(height: 12),
            if (vm.isLoading)
              AppAsyncState.loading()
            else if (vm.filteredPosts.isEmpty)
              const ForumEmptyStateCard(
                title: 'No threads yet',
                body: 'Start the first discussion for this course.',
              )
            else
              ...vm.filteredPosts.map((post) {
                final id = (post['id'] ?? '').toString();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ForumPostCard(
                    post: post,
                    onTap: id.isEmpty
                        ? () {}
                        : () => context.push(
                            '/student/courses/${widget.courseId}/forums/$id',
                          ),
                  ),
                );
              }),
            if (!vm.isLoading && vm.totalPages > 1) ...[
              const SizedBox(height: 8),
              ForumPaginationControls(
                page: vm.page,
                totalPages: vm.totalPages,
                onPrevious: vm.page <= 1 ? null : () => vm.setPage(vm.page - 1),
                onNext: vm.page >= vm.totalPages
                    ? null
                    : () => vm.setPage(vm.page + 1),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
