import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skillforgeapp/ui/design_system.dart';
import 'package:skillforgeapp/view_models/student/forum_view_models.dart';
import 'package:skillforgeapp/widgets/shared/forum_widgets.dart';

class ForumThreadPage extends ConsumerStatefulWidget {
  const ForumThreadPage({
    super.key,
    required this.courseId,
    required this.forumId,
  });

  final String courseId;
  final String forumId;

  @override
  ConsumerState<ForumThreadPage> createState() => _ForumThreadPageState();
}

class _ForumThreadPageState extends ConsumerState<ForumThreadPage> {
  final _reply = TextEditingController();

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  Future<bool> _confirm(String title, String content) async {
    return await showAppDialog<bool>(
          context: context,
          useRootNavigator: true,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final input = (courseId: widget.courseId, forumId: widget.forumId);
    final vm = ref.watch(forumThreadViewModelProvider(input));
    final post = vm.post;

    return AppPage(
      title: post == null ? 'Thread' : forumText(post, 'title'),
      subtitle: widget.courseId,
      child: RefreshIndicator(
        onRefresh: () => vm.load(),
        child: ListView(
          children: [
            if (vm.error != null) ...[
              ForumErrorPanel(message: vm.error!),
              const SizedBox(height: 10),
            ],
            if (vm.isLoading)
              AppAsyncState.loading()
            else if (post == null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(Icons.forum_outlined, size: 42),
                      const SizedBox(height: 10),
                      Text(
                        'Thread not found',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              _OriginalPostCard(
                post: post,
                vm: vm,
                onDelete: () async {
                  final ok = await _confirm(
                    'Delete thread?',
                    'This thread will be permanently deleted.',
                  );
                  if (!ok) return;
                  await vm.deletePost();
                  if (context.mounted) context.pop(true);
                },
              ),
              const SizedBox(height: 12),
              Text(
                '${vm.replies.length} ${vm.replies.length == 1 ? 'reply' : 'replies'}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (vm.replies.isEmpty)
                const Card(child: ListTile(title: Text('No replies yet.')))
              else
                ...vm.replies.map(
                  (reply) => _ReplyTile(
                    reply: reply,
                    vm: vm,
                    depth: 0,
                    onReplyTo: (target) {
                      vm.setReplyTarget(target);
                      _reply.text = '@${forumAuthorName(target)} ';
                    },
                    onDeleteReply: (target) async {
                      final ok = await _confirm(
                        'Delete reply?',
                        'This reply will be permanently deleted.',
                      );
                      if (ok) {
                        await vm.deleteReply((target['id'] ?? '').toString());
                      }
                    },
                  ),
                ),
              const SizedBox(height: 12),
              if (vm.isLocked)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.lock),
                    title: Text('This thread is locked'),
                    subtitle: Text('New replies are disabled.'),
                  ),
                )
              else
                _ReplyComposer(vm: vm, controller: _reply),
            ],
          ],
        ),
      ),
    );
  }
}

class _OriginalPostCard extends StatelessWidget {
  const _OriginalPostCard({
    required this.post,
    required this.vm,
    required this.onDelete,
  });

  final Map<String, dynamic> post;
  final ForumThreadViewModel vm;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final author = forumAuthor(post);
    final status = (post['status'] ?? '').toString();
    final hasBadge =
        post['isPinned'] == true ||
        status == 'locked' ||
        status == 'hidden' ||
        status == 'deleted';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      forumText(post, 'title'),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                ),
                if (vm.isModerator || vm.canDelete(post))
                  PopupMenuButton<String>(
                    useRootNavigator: true,
                    onSelected: (value) async {
                      if (value == 'delete') {
                        await onDelete();
                      } else {
                        await vm.updatePostStatus(value);
                      }
                    },
                    itemBuilder: (context) => [
                      if (vm.isModerator)
                        PopupMenuItem(
                          value: (post['status'] ?? '') == 'hidden'
                              ? 'visible'
                              : 'hidden',
                          child: Text(
                            (post['status'] ?? '') == 'hidden'
                                ? 'Unhide Thread'
                                : 'Hide Thread',
                          ),
                        ),
                      if (vm.isModerator)
                        PopupMenuItem(
                          value: (post['status'] ?? '') == 'locked'
                              ? 'visible'
                              : 'locked',
                          child: Text(
                            (post['status'] ?? '') == 'locked'
                                ? 'Unlock Thread'
                                : 'Lock Thread',
                          ),
                        ),
                      if (vm.canDelete(post))
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete Thread'),
                        ),
                    ],
                  ),
              ],
            ),
            if (hasBadge) ...[
              const SizedBox(height: 8),
              ForumStatusBadges(item: post),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    final authorId = forumAuthorId(post);
                    if (authorId.isEmpty) return;
                    context.push('/student/profile/$authorId');
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 2,
                    ),
                    child: Row(
                      children: [
                        ForumAuthorAvatar(author: author, size: 36),
                        const SizedBox(width: 8),
                        Text(
                          forumAuthorName(post),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    (post['createdAt'] ?? '').toString(),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(forumBody(post)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _Meta(
                  icon: Icons.chat_bubble_outline,
                  label: '${forumReplyCount(post)} replies',
                ),
                _Meta(icon: Icons.schedule, label: forumLastActivity(post)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReplyTile extends StatelessWidget {
  const _ReplyTile({
    required this.reply,
    required this.vm,
    required this.depth,
    required this.onReplyTo,
    required this.onDeleteReply,
  });

  final Map<String, dynamic> reply;
  final ForumThreadViewModel vm;
  final int depth;
  final ValueChanged<Map<String, dynamic>> onReplyTo;
  final Future<void> Function(Map<String, dynamic> reply) onDeleteReply;

  List<Map<String, dynamic>> get children {
    final raw = reply['childReplies'];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
    }
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    final author = forumAuthor(reply);
    final status = (reply['status'] ?? '').toString();
    final hasDepth = depth > 0;
    final lineColor = Theme.of(
      context,
    ).colorScheme.primary.withValues(alpha: hasDepth ? 0.32 : 0);
    return Container(
      margin: EdgeInsets.only(
        left: hasDepth ? 14 : 0,
        top: hasDepth ? 8 : 0,
        bottom: 10,
      ),
      decoration: hasDepth
          ? BoxDecoration(
              border: Border(left: BorderSide(color: lineColor, width: 2)),
            )
          : null,
      padding: EdgeInsets.only(left: hasDepth ? 12 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: status == 'hidden'
                ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.55)
                : null,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ForumAuthorAvatar(author: author, size: 30),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                final authorId = forumAuthorId(reply);
                                if (authorId.isEmpty) return;
                                context.push('/student/profile/$authorId');
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                  vertical: 2,
                                ),
                                child: Text(
                                  forumAuthorName(reply),
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                              ),
                            ),
                            Text(
                              (reply['createdAt'] ?? '').toString(),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      if (status == 'hidden') const Chip(label: Text('Hidden')),
                      if (vm.isModerator || vm.canDelete(reply))
                        PopupMenuButton<String>(
                          useRootNavigator: true,
                          onSelected: (value) async {
                            final id = (reply['id'] ?? '').toString();
                            if (value == 'delete') {
                              await onDeleteReply(reply);
                            } else {
                              await vm.updateReplyStatus(id, value);
                            }
                          },
                          itemBuilder: (context) => [
                            if (vm.isModerator)
                              PopupMenuItem(
                                value: status == 'hidden'
                                    ? 'visible'
                                    : 'hidden',
                                child: Text(
                                  status == 'hidden' ? 'Unhide' : 'Hide',
                                ),
                              ),
                            if (vm.canDelete(reply))
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(forumBody(reply)),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => onReplyTo(reply),
                    icon: const Icon(Icons.subdirectory_arrow_right),
                    label: const Text('Reply'),
                  ),
                ],
              ),
            ),
          ),
          if (children.isNotEmpty) ...[
            const SizedBox(height: 2),
            ...children.map(
              (child) => _ReplyTile(
                reply: child,
                vm: vm,
                depth: depth + 1,
                onReplyTo: onReplyTo,
                onDeleteReply: onDeleteReply,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReplyComposer extends StatelessWidget {
  const _ReplyComposer({required this.vm, required this.controller});

  final ForumThreadViewModel vm;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final target = vm.replyTarget;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (target != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Replying to ${forumAuthorName(target)}'),
                    ),
                    IconButton(
                      onPressed: () => vm.setReplyTarget(null),
                      icon: const Icon(Icons.close),
                      tooltip: 'Cancel reply target',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
            TextField(
              controller: controller,
              minLines: 3,
              maxLines: 7,
              decoration: const InputDecoration(labelText: 'Write a reply...'),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: vm.isSubmittingReply
                  ? null
                  : () async {
                      await vm.createReply(controller.text);
                      controller.clear();
                    },
              icon: vm.isSubmittingReply
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(vm.isSubmittingReply ? 'Posting...' : 'Post Reply'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
