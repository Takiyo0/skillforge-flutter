import 'package:flutter/material.dart';

class ForumComposePostCard extends StatelessWidget {
  const ForumComposePostCard({
    super.key,
    required this.titleLabel,
    required this.contentLabel,
    required this.submitLabel,
    required this.submittingLabel,
    required this.titleController,
    required this.contentController,
    required this.isSubmitting,
    required this.onSubmit,
    this.courseOptions = const [],
    this.selectedCourseId,
    this.onCourseChanged,
  });

  final String titleLabel;
  final String contentLabel;
  final String submitLabel;
  final String submittingLabel;
  final TextEditingController titleController;
  final TextEditingController contentController;
  final bool isSubmitting;
  final VoidCallback onSubmit;
  final List<({String id, String label})> courseOptions;
  final String? selectedCourseId;
  final ValueChanged<String>? onCourseChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              submitLabel == 'Post Thread'
                  ? 'Create New Thread'
                  : 'Create New Post',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (courseOptions.isNotEmpty) ...[
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedCourseId,
                items: courseOptions
                    .map(
                      (course) => DropdownMenuItem(
                        value: course.id,
                        child: Text(course.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null && onCourseChanged != null) {
                    onCourseChanged!(value);
                  }
                },
                decoration: const InputDecoration(labelText: 'Course'),
              ),
            ],
            const SizedBox(height: 10),
            TextField(
              controller: titleController,
              maxLength: 200,
              decoration: InputDecoration(labelText: titleLabel),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: contentController,
              minLines: 4,
              maxLines: 8,
              decoration: InputDecoration(labelText: contentLabel),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: isSubmitting ? null : onSubmit,
              icon: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(isSubmitting ? submittingLabel : submitLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class ForumPaginationControls extends StatelessWidget {
  const ForumPaginationControls({
    super.key,
    required this.page,
    required this.totalPages,
    required this.onPrevious,
    required this.onNext,
  });

  final int page;
  final int totalPages;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        OutlinedButton(onPressed: onPrevious, child: const Text('Previous')),
        const SizedBox(width: 10),
        Text('Page $page of $totalPages'),
        const SizedBox(width: 10),
        OutlinedButton(onPressed: onNext, child: const Text('Next')),
      ],
    );
  }
}

class ForumEmptyStateCard extends StatelessWidget {
  const ForumEmptyStateCard({
    super.key,
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.forum_outlined,
              size: 42,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 10),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(body, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
