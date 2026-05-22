import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:skillforgeapp/config/asset_urls.dart';
import 'package:skillforgeapp/view_models/student/forum_view_models.dart';

class ForumAuthorAvatar extends StatelessWidget {
  const ForumAuthorAvatar({super.key, required this.author, this.size = 32});

  final Map<String, dynamic> author;
  final double size;

  @override
  Widget build(BuildContext context) {
    final name = (author['displayName'] ?? 'U').toString();
    final seed =
        (author['id'] ??
                author['userId'] ??
                author['email'] ??
                author['displayName'] ??
                name)
            .toString();
    final url =
        AssetUrls.avatarUrl(author['avatarS3Key']?.toString()) ??
        AssetUrls.dicebearAvatarUrl(seed);
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: AssetUrls.isSvgUrl(url)
            ? SvgPicture.network(url, fit: BoxFit.cover)
            : Image.network(url, fit: BoxFit.cover),
      ),
    );
  }
}

class ForumStatusBadges extends StatelessWidget {
  const ForumStatusBadges({super.key, required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final status = (item['status'] ?? '').toString();
    final isPinned = item['isPinned'] == true;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        if (isPinned)
          const _ForumBadge(
            icon: Icons.push_pin,
            label: 'Pinned',
            color: Color(0xFF2563EB),
          ),
        if (status == 'locked')
          const _ForumBadge(
            icon: Icons.lock,
            label: 'Locked',
            color: Color(0xFFDC2626),
          ),
        if (status == 'hidden')
          const _ForumBadge(
            icon: Icons.visibility_off,
            label: 'Hidden',
            color: Color(0xFF64748B),
          ),
        if (status == 'deleted')
          const _ForumBadge(
            icon: Icons.delete_outline,
            label: 'Deleted',
            color: Color(0xFF64748B),
          ),
      ],
    );
  }
}

class _ForumBadge extends StatelessWidget {
  const _ForumBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class ForumPostCard extends StatelessWidget {
  const ForumPostCard({
    super.key,
    required this.post,
    this.courseName,
    required this.onTap,
  });

  final Map<String, dynamic> post;
  final String? courseName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final author = forumAuthor(post);
    final title = forumText(post, 'title');
    final body = forumBody(post);
    final replyCount = forumReplyCount(post);
    final lastActivity = forumLastActivity(post);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ForumStatusBadges(item: post),
              if (courseName != null && courseName!.isNotEmpty) ...[
                Chip(
                  avatar: const Icon(Icons.menu_book, size: 16),
                  label: Text(courseName!),
                ),
              ],
              const SizedBox(height: 8),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              if (body.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(body, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
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
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ForumAuthorAvatar(author: author, size: 24),
                          const SizedBox(width: 6),
                          Text(
                            forumAuthorName(post),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                  _MetaIcon(
                    icon: Icons.chat_bubble_outline,
                    label: '$replyCount replies',
                  ),
                  if (lastActivity.isNotEmpty)
                    _MetaIcon(icon: Icons.schedule, label: lastActivity),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaIcon extends StatelessWidget {
  const _MetaIcon({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class ForumErrorPanel extends StatelessWidget {
  const ForumErrorPanel({super.key, required this.message, this.onDismiss});

  final String message;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close),
              tooltip: 'Dismiss',
            ),
        ],
      ),
    );
  }
}
