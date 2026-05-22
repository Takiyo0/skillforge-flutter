import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skillforgeapp/ui/design_system.dart';
import 'package:skillforgeapp/view_models/student/forum_view_models.dart';
import 'package:skillforgeapp/widgets/shared/forum_widgets.dart';
import 'package:skillforgeapp/widgets/student/forum_common_widgets.dart';

class UserForumsPage extends ConsumerStatefulWidget {
  const UserForumsPage({super.key});

  @override
  ConsumerState<UserForumsPage> createState() => _UserForumsPageState();
}

class _UserForumsPageState extends ConsumerState<UserForumsPage> {
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
    final vm = ref.watch(userForumsViewModelProvider);

    return AppPage(
      title: 'Forums',
      subtitle: 'Posts and discussions you joined',
      child: RefreshIndicator(
        onRefresh: () => vm.load(),
        child: ListView(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search by title, content, or course...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: vm.setSearch,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: () => setState(() => _showCreate = !_showCreate),
                  icon: Icon(_showCreate ? Icons.close : Icons.add),
                  tooltip: _showCreate ? 'Cancel' : 'Create post',
                ),
              ],
            ),
            if (vm.error != null) ...[
              const SizedBox(height: 10),
              ForumErrorPanel(message: vm.error!),
            ],
            if (_showCreate) ...[
              const SizedBox(height: 10),
              ForumComposePostCard(
                titleLabel: 'Post title',
                contentLabel: 'Post content',
                submitLabel: 'Create Post',
                submittingLabel: 'Creating...',
                titleController: _title,
                contentController: _content,
                isSubmitting: vm.isSubmitting,
                courseOptions: vm.courses
                    .map(
                      (course) => (
                        id: (course['id'] ?? '').toString(),
                        label: (course['title'] ?? course['name'] ?? '')
                            .toString(),
                      ),
                    )
                    .toList(),
                selectedCourseId: vm.selectedCourseId.isEmpty
                    ? null
                    : vm.selectedCourseId,
                onCourseChanged: vm.setSelectedCourse,
                onSubmit: () async {
                  final created = await vm.createPost(
                    title: _title.text,
                    content: _content.text,
                  );
                  if (created == null || !context.mounted) return;
                  final courseId = vm.selectedCourseId;
                  final id = (created['id'] ?? '').toString();
                  setState(() => _showCreate = false);
                  _title.clear();
                  _content.clear();
                  if (courseId.isNotEmpty && id.isNotEmpty) {
                    context.push('/student/courses/$courseId/forums/$id');
                  }
                },
              ),
            ],
            const SizedBox(height: 12),
            if (vm.isLoading)
              AppAsyncState.loading()
            else if (vm.filteredPosts.isEmpty)
              const ForumEmptyStateCard(
                title: 'No forum activity yet',
                body: 'Create a post or reply to a course discussion.',
              )
            else
              ...vm.filteredPosts.map((post) {
                final course = post['course'] is Map
                    ? (post['course'] as Map).cast<String, dynamic>()
                    : const <String, dynamic>{};
                final courseName = (course['name'] ?? course['title'] ?? '')
                    .toString();
                final id = (post['id'] ?? '').toString();
                final courseId = (post['courseId'] ?? course['id'] ?? '')
                    .toString();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ForumPostCard(
                    post: post,
                    courseName: courseName,
                    onTap: id.isEmpty || courseId.isEmpty
                        ? () {}
                        : () => context.push(
                            '/student/courses/$courseId/forums/$id',
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
