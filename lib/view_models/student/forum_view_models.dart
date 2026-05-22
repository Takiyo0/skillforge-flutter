import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skillforgeapp/utils/permissions.dart';
import 'package:skillforgeapp/models/shared/api_error.dart';
import 'package:skillforgeapp/models/auth/auth_models.dart';
import 'package:skillforgeapp/models/shared/paginated_response.dart';
import 'package:skillforgeapp/providers/app_state.dart';
import 'package:skillforgeapp/providers/infrastructure_providers.dart';

const forumPageSize = 20;

String _forumErrorMessage(Object error) {
  if (error is ApiError) return error.message;
  return error.toString();
}

String forumText(
  Map<String, dynamic> item,
  String primary, [
  String? fallback,
]) {
  return (item[primary] ?? (fallback == null ? null : item[fallback]) ?? '')
      .toString();
}

Map<String, dynamic> forumAuthor(Map<String, dynamic> item) {
  final raw = item['author'];
  if (raw is Map) return raw.cast<String, dynamic>();
  if (raw is String) return {'displayName': raw};
  return const {};
}

String forumAuthorName(Map<String, dynamic> item) {
  final author = forumAuthor(item);
  return (author['displayName'] ??
          author['name'] ??
          author['email'] ??
          item['authorName'] ??
          'Unknown')
      .toString();
}

String forumAuthorId(Map<String, dynamic> item) {
  final author = forumAuthor(item);
  return (author['id'] ?? author['userId'] ?? '').toString();
}

String forumBody(Map<String, dynamic> item) =>
    forumText(item, 'body', 'content');

String forumReplyCount(Map<String, dynamic> item) {
  final count =
      item['replyCount'] ?? item['replies'] ?? item['nestedReplies'] ?? 0;
  return count.toString();
}

String forumLastActivity(Map<String, dynamic> item) {
  return (item['lastActivityAt'] ??
          item['lastActivity'] ??
          item['updatedAt'] ??
          item['createdAt'] ??
          '')
      .toString();
}

int _totalPages(PaginatedResponse<Map<String, dynamic>> response) {
  final p = response.pagination ?? const {};
  final explicit = p['totalPages'];
  if (explicit is num) return explicit.toInt().clamp(1, 999999).toInt();
  final total = p['total'];
  final limit = p['limit'] ?? forumPageSize;
  if (total is num && limit is num && limit > 0) {
    return (total / limit).ceil().clamp(1, 999999).toInt();
  }
  return 1;
}

class _ForumNotifier extends ChangeNotifier {
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void safeNotify() {
    if (!_disposed) notifyListeners();
  }
}

class UserForumsViewModel extends _ForumNotifier {
  UserForumsViewModel(this._ref) {
    load();
  }

  final Ref _ref;
  bool isLoading = true;
  bool isSubmitting = false;
  String? error;
  String search = '';
  int page = 1;
  int totalPages = 1;
  String selectedCourseId = '';
  List<Map<String, dynamic>> posts = const [];
  List<Map<String, dynamic>> courses = const [];

  List<Map<String, dynamic>> get filteredPosts {
    final keyword = search.trim().toLowerCase();
    if (keyword.isEmpty) return posts;
    return posts.where((post) {
      final course = post['course'] is Map
          ? (post['course'] as Map).cast<String, dynamic>()
          : const <String, dynamic>{};
      final haystack = [
        forumText(post, 'title'),
        forumBody(post),
        forumAuthorName(post),
        (course['name'] ?? course['title'] ?? '').toString(),
      ].join(' ').toLowerCase();
      return haystack.contains(keyword);
    }).toList();
  }

  Future<void> load() async {
    isLoading = true;
    error = null;
    safeNotify();
    try {
      final repo = _ref.read(skillForgeRepositoryProvider);
      final results = await Future.wait([
        repo.getUserForums(page: page, limit: forumPageSize),
        repo.listEnrolledCourses(),
      ]);
      final forums = results[0];
      final enrolled = results[1];
      posts = forums.data;
      courses = enrolled.data;
      totalPages = _totalPages(forums);
      if (selectedCourseId.isEmpty && courses.isNotEmpty) {
        selectedCourseId = (courses.first['id'] ?? '').toString();
      }
    } catch (e) {
      error = _forumErrorMessage(e);
    } finally {
      isLoading = false;
      safeNotify();
    }
  }

  void setSearch(String value) {
    search = value;
    safeNotify();
  }

  void setSelectedCourse(String value) {
    selectedCourseId = value;
    safeNotify();
  }

  Future<void> setPage(int value) async {
    page = value.clamp(1, totalPages).toInt();
    await load();
  }

  Future<Map<String, dynamic>?> createPost({
    required String title,
    required String content,
  }) async {
    final cleanTitle = title.trim();
    final cleanContent = content.trim();
    if (selectedCourseId.isEmpty ||
        cleanTitle.isEmpty ||
        cleanContent.isEmpty) {
      error = 'Please fill in all fields';
      safeNotify();
      return null;
    }
    if (cleanTitle.length < 5) {
      error = 'Post title must be at least 5 characters';
      safeNotify();
      return null;
    }

    isSubmitting = true;
    error = null;
    safeNotify();
    try {
      final created = await _ref
          .read(skillForgeRepositoryProvider)
          .createForumPost(
            courseId: selectedCourseId,
            title: cleanTitle,
            content: cleanContent,
          );
      await load();
      return created;
    } catch (e) {
      error = _forumErrorMessage(e);
      return null;
    } finally {
      isSubmitting = false;
      safeNotify();
    }
  }
}

final userForumsViewModelProvider =
    ChangeNotifierProvider.autoDispose<UserForumsViewModel>(
      (ref) => UserForumsViewModel(ref),
    );

class CourseForumsViewModel extends _ForumNotifier {
  CourseForumsViewModel(this._ref, this.courseId) {
    load();
  }

  final Ref _ref;
  final String courseId;
  bool isLoading = true;
  bool isSubmitting = false;
  String? error;
  String search = '';
  int page = 1;
  int totalPages = 1;
  String courseName = '';
  List<Map<String, dynamic>> posts = const [];

  List<Map<String, dynamic>> get filteredPosts {
    final keyword = search.trim().toLowerCase();
    if (keyword.isEmpty) return posts;
    return posts.where((post) {
      final haystack = [
        forumText(post, 'title'),
        forumBody(post),
        forumAuthorName(post),
      ].join(' ').toLowerCase();
      return haystack.contains(keyword);
    }).toList();
  }

  Future<void> load({bool preserveError = false}) async {
    isLoading = true;
    if (!preserveError) error = null;
    safeNotify();
    try {
      final repo = _ref.read(skillForgeRepositoryProvider);
      final detailFuture = repo.getCourseDetail(courseId);
      final forumsFuture = repo.getForumPosts(
        courseId,
        page: page,
        limit: forumPageSize,
      );
      final detail = await detailFuture;
      final forums = await forumsFuture;
      courseName = (detail['title'] ?? courseId).toString();
      posts = forums.data;
      totalPages = _totalPages(forums);
    } catch (e) {
      error = _forumErrorMessage(e);
    } finally {
      isLoading = false;
      safeNotify();
    }
  }

  void setSearch(String value) {
    search = value;
    safeNotify();
  }

  Future<void> setPage(int value) async {
    page = value.clamp(1, totalPages).toInt();
    await load();
  }

  Future<Map<String, dynamic>?> createPost({
    required String title,
    required String content,
  }) async {
    final cleanTitle = title.trim();
    final cleanContent = content.trim();
    if (cleanTitle.isEmpty || cleanContent.isEmpty) {
      error = 'Thread title and content are required';
      safeNotify();
      return null;
    }
    if (cleanTitle.length < 5) {
      error = 'Thread title must be at least 5 characters';
      safeNotify();
      return null;
    }

    isSubmitting = true;
    error = null;
    safeNotify();
    try {
      final created = await _ref
          .read(skillForgeRepositoryProvider)
          .createForumPost(
            courseId: courseId,
            title: cleanTitle,
            content: cleanContent,
          );
      page = 1;
      await load(preserveError: true);
      return created;
    } catch (e) {
      error = _forumErrorMessage(e);
      return null;
    } finally {
      isSubmitting = false;
      safeNotify();
    }
  }
}

final courseForumsViewModelProvider = ChangeNotifierProvider.autoDispose
    .family<CourseForumsViewModel, String>(
      (ref, courseId) => CourseForumsViewModel(ref, courseId),
    );

class ForumThreadViewModel extends _ForumNotifier {
  ForumThreadViewModel(this._ref, this.input) {
    load();
  }

  final Ref _ref;
  final ({String courseId, String forumId}) input;
  bool isLoading = true;
  bool isSubmittingReply = false;
  String? error;
  Map<String, dynamic>? post;
  List<Map<String, dynamic>> replies = const [];
  Map<String, dynamic>? replyTarget;

  User? get currentUser => _ref.read(appStateProvider).user;

  bool get isLocked => (post?['status'] ?? '').toString() == 'locked';

  bool get isModerator {
    final user = currentUser;
    return isAdmin(user) || isInstructor(user);
  }

  bool canDelete(Map<String, dynamic> item) {
    final user = currentUser;
    if (user == null) return false;
    if (isModerator) return true;
    return (forumAuthor(item)['id'] ?? '').toString() == user.id;
  }

  Future<void> load() async {
    isLoading = true;
    error = null;
    safeNotify();
    try {
      final repo = _ref.read(skillForgeRepositoryProvider);
      post = await repo.getForumPost(input.forumId);
      final response = await repo.getForumReplies(
        input.forumId,
        page: 1,
        limit: 100,
      );
      replies = response.data;
    } catch (e) {
      error = _forumErrorMessage(e);
    } finally {
      isLoading = false;
      safeNotify();
    }
  }

  void setReplyTarget(Map<String, dynamic>? value) {
    replyTarget = value;
    safeNotify();
  }

  Future<void> createReply(String content) async {
    final cleanContent = content.trim();
    if (cleanContent.isEmpty) return;

    isSubmittingReply = true;
    error = null;
    safeNotify();
    try {
      await _ref
          .read(skillForgeRepositoryProvider)
          .createForumReply(
            postId: input.forumId,
            content: cleanContent,
            parentReplyId: replyTarget == null
                ? null
                : (replyTarget!['id'] ?? '').toString(),
          );
      replyTarget = null;
      await load();
    } catch (e) {
      error = _forumErrorMessage(e);
    } finally {
      isSubmittingReply = false;
      safeNotify();
    }
  }

  Future<void> deletePost() async {
    if (post == null || !canDelete(post!)) return;
    try {
      await _ref
          .read(skillForgeRepositoryProvider)
          .deleteForumPost(input.forumId);
      post = null;
      safeNotify();
    } catch (e) {
      error = _forumErrorMessage(e);
      safeNotify();
    }
  }

  Future<void> deleteReply(String replyId) async {
    try {
      await _ref.read(skillForgeRepositoryProvider).deleteForumReply(replyId);
      await load();
    } catch (e) {
      error = _forumErrorMessage(e);
      safeNotify();
    }
  }

  Future<void> updatePostStatus(String status) async {
    if (!isModerator) return;
    try {
      await _ref
          .read(skillForgeRepositoryProvider)
          .updateForumPostStatus(postId: input.forumId, status: status);
      await load();
    } catch (e) {
      error = _forumErrorMessage(e);
      safeNotify();
    }
  }

  Future<void> updateReplyStatus(String replyId, String status) async {
    if (!isModerator) return;
    try {
      await _ref
          .read(skillForgeRepositoryProvider)
          .updateForumReplyStatus(replyId: replyId, status: status);
      await load();
    } catch (e) {
      error = _forumErrorMessage(e);
      safeNotify();
    }
  }
}

final forumThreadViewModelProvider = ChangeNotifierProvider.autoDispose
    .family<ForumThreadViewModel, ({String courseId, String forumId})>(
      (ref, input) => ForumThreadViewModel(ref, input),
    );
