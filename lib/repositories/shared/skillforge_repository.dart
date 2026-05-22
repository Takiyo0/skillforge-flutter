import 'dart:typed_data';

import 'package:skillforgeapp/network/api_client.dart';
import 'package:skillforgeapp/models/admin/admin_models.dart';
import 'package:skillforgeapp/models/shared/api_error.dart';
import 'package:skillforgeapp/models/auth/auth_models.dart';
import 'package:skillforgeapp/models/shared/paginated_response.dart';

class SkillForgeRepository {
  SkillForgeRepository(this._client);

  final ApiClient _client;

  Map<String, dynamic> _expectMap(dynamic value, String endpoint) {
    if (value is Map<String, dynamic>) return value;
    throw ApiError(
      message:
          'Invalid response shape from $endpoint: expected object, got ${value.runtimeType}',
      timestamp: DateTime.now().toIso8601String(),
    );
  }

  List<dynamic> _expectList(dynamic value, String endpoint) {
    if (value is List) return value;
    throw ApiError(
      message:
          'Invalid response shape from $endpoint: expected array, got ${value.runtimeType}',
      timestamp: DateTime.now().toIso8601String(),
    );
  }

  void _requireDataKey(Map<String, dynamic> data, String endpoint) {
    if (!data.containsKey('data') ||
        data['data'] == null ||
        data['data'] is! List) {
      throw ApiError(
        message: 'Invalid response from $endpoint: expected `data` array',
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  Future<AuthResponse> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final data =
        await _client.request(
              'POST',
              '/auth/register',
              body: _client.toJson({
                'email': email,
                'password': password,
                'displayName': displayName,
              }),
            )
            as Map<String, dynamic>;
    return AuthResponse.fromJson(data);
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final data =
        await _client.request(
              'POST',
              '/auth/login',
              body: _client.toJson({'email': email, 'password': password}),
            )
            as Map<String, dynamic>;
    return AuthResponse.fromJson(data);
  }

  Future<User> getProfile() async {
    final data = await _client.request('GET', '/me') as Map<String, dynamic>;
    return User.fromJson(data);
  }

  Future<Map<String, dynamic>> getXpSummary() async =>
      (await _client.request('GET', '/me/xp')) as Map<String, dynamic>;

  Future<Map<String, dynamic>> getStreak() async =>
      (await _client.request('GET', '/me/streak')) as Map<String, dynamic>;

  Future<Map<String, dynamic>> getBadges() async =>
      (await _client.request('GET', '/me/badges')) as Map<String, dynamic>;

  Future<List<dynamic>> getStreakLeaderboard({int? limit}) async {
    final data = await _client.request(
      'GET',
      '/streaks/leaderboard',
      query: limit == null ? null : {'limit': limit},
    );
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      return (data['leaderboard'] as List?) ?? const [];
    }
    return const [];
  }

  Future<PaginatedResponse<Map<String, dynamic>>> listCourses({
    String? search,
    String? level,
    int? page,
    int? limit,
  }) async {
    final raw = await _client.request(
      'GET',
      '/courses',
      query: {
        'search': ?search,
        'level': ?level,
        'page': ?page,
        'limit': ?limit,
      },
    );
    final data = _expectMap(raw, '/courses');
    _requireDataKey(data, '/courses');
    return PaginatedResponse.fromJson(data, (v) => v);
  }

  Future<PaginatedResponse<Map<String, dynamic>>> listEnrolledCourses() async {
    final raw = await _client.request('GET', '/courses/enrolled');
    final data = _expectMap(raw, '/courses/enrolled');
    _requireDataKey(data, '/courses/enrolled');
    return PaginatedResponse.fromJson(data, (v) => v);
  }

  Future<Map<String, dynamic>> getCourseDetail(String courseId) async =>
      (await _client.request('GET', '/courses/$courseId'))
          as Map<String, dynamic>;

  Future<Map<String, dynamic>> getCourseUnits(String courseId) async =>
      (await _client.request('GET', '/courses/$courseId/units'))
          as Map<String, dynamic>;

  Future<Map<String, dynamic>> getCourseProgress(String courseId) async =>
      (await _client.request('GET', '/me/courses/$courseId/progress'))
          as Map<String, dynamic>;

  Future<void> enrollCourse(String courseId) async =>
      _client.request('POST', '/me/courses/$courseId/enroll');

  Future<Map<String, dynamic>> getUnitDetail(String unitId) async =>
      (await _client.request('GET', '/units/$unitId')) as Map<String, dynamic>;

  Future<void> startUnit(String unitId) async =>
      _client.request('POST', '/me/units/$unitId/start');

  Future<void> completeUnit(String unitId) async =>
      _client.request('POST', '/me/units/$unitId/complete');

  Future<List<dynamic>> getExercisesInUnit(String unitId) async => (() async {
    final raw = await _client.request('GET', '/units/$unitId/exercises');
    if (raw is List) return raw;
    if (raw is Map<String, dynamic>) {
      if (raw['exercises'] is List) return raw['exercises'] as List<dynamic>;
      if (raw['data'] is List) return raw['data'] as List<dynamic>;
    }
    throw ApiError(
      message:
          'Invalid response shape from /units/$unitId/exercises: expected array or object with `exercises`/`data` array',
      timestamp: DateTime.now().toIso8601String(),
    );
  })();

  Future<Map<String, dynamic>> submitExerciseCode({
    required String unitId,
    required String exerciseId,
    required String sourceCode,
    required String language,
  }) async =>
      (await _client.request(
            'POST',
            '/units/$unitId/exercises/$exerciseId/submissions',
            body: _client.toJson({
              'exerciseId': exerciseId,
              'language': language,
              'sourceCode': sourceCode,
            }),
          ))
          as Map<String, dynamic>;

  Future<Map<String, dynamic>> submitAdvancedExerciseCode({
    required String unitId,
    required String exerciseId,
    required String sourceCode,
    required String language,
  }) async =>
      (await _client.request(
            'POST',
            '/units/$unitId/exercises/$exerciseId/advanced-submissions',
            body: _client.toJson({
              'exerciseId': exerciseId,
              'language': language,
              'sourceCode': sourceCode,
            }),
          ))
          as Map<String, dynamic>;

  Future<Map<String, dynamic>> getSubmissionStatus(String submissionId) async =>
      (await _client.request('GET', '/submissions/$submissionId'))
          as Map<String, dynamic>;

  Future<Map<String, dynamic>> getSubmissionFeedback(
    String submissionId,
  ) async =>
      (await _client.request('GET', '/submissions/$submissionId/feedback'))
          as Map<String, dynamic>;

  Future<List<dynamic>> getUserUnitSubmissions(String unitId) async {
    final raw = await _client.request('GET', '/submissions/unit/$unitId');
    if (raw is List) return raw;
    if (raw is Map<String, dynamic>) {
      if (raw['submissions'] is List) {
        return raw['submissions'] as List<dynamic>;
      }
      if (raw['data'] is List) return raw['data'] as List<dynamic>;
    }
    throw ApiError(
      message:
          'Invalid response shape from /submissions/unit/$unitId: expected array or object with `submissions`/`data` array',
      timestamp: DateTime.now().toIso8601String(),
    );
  }

  Future<List<dynamic>> getSandboxLanguages({
    bool includeBaseCode = false,
  }) async => _expectList(
    await _client.request(
      'GET',
      '/submissions/languages',
      query: {'includeBaseCode': includeBaseCode},
    ),
    '/submissions/languages',
  );

  Future<Map<String, dynamic>> runCodeSandbox({
    required String code,
    required String language,
    required List<Map<String, String>> testCases,
  }) async =>
      (await _client.request(
            'POST',
            '/submissions/sandbox/run',
            body: _client.toJson({
              'code': code,
              'language': language,
              'testCases': testCases,
            }),
          ))
          as Map<String, dynamic>;

  Future<Map<String, dynamic>> submitQuiz({
    required String unitId,
    required String quizId,
    required List<Map<String, dynamic>> answers,
  }) async =>
      (await _client.request(
            'POST',
            '/units/$unitId/quizzes/$quizId/submissions',
            body: _client.toJson({'answers': answers}),
          ))
          as Map<String, dynamic>;

  Future<Map<String, dynamic>> startFinalExamAttempt({
    required String unitId,
    required String finalExamId,
  }) async =>
      (await _client.request(
            'POST',
            '/units/$unitId/final-exams/$finalExamId/attempts',
          ))
          as Map<String, dynamic>;

  Future<Map<String, dynamic>> submitFinalExam({
    required String unitId,
    required String finalExamId,
    required List<Map<String, dynamic>> answers,
  }) async =>
      (await _client.request(
            'POST',
            '/units/$unitId/final-exams/$finalExamId/attempts/submit',
            body: _client.toJson({'answers': answers}),
          ))
          as Map<String, dynamic>;

  Future<Map<String, dynamic>> getAssessmentAttemptReview({
    required String unitId,
    required String quizId,
    required String attemptId,
  }) async => _expectMap(
    await _client.request(
      'GET',
      '/units/$unitId/quizzes/$quizId/submissions/$attemptId/review',
    ),
    '/units/$unitId/quizzes/$quizId/submissions/$attemptId/review',
  );

  Future<Map<String, dynamic>> getFinalExamAttemptReview({
    required String unitId,
    required String finalExamId,
    required String attemptId,
  }) async => _expectMap(
    await _client.request(
      'GET',
      '/units/$unitId/final-exams/$finalExamId/attempts/$attemptId/review',
    ),
    '/units/$unitId/final-exams/$finalExamId/attempts/$attemptId/review',
  );

  Future<Map<String, dynamic>> askAiSubmissionExplanation(
    String submissionId,
  ) async => _expectMap(
    await _client.request('POST', '/submissions/$submissionId/ai-explanation'),
    '/submissions/$submissionId/ai-explanation',
  );

  Future<PaginatedResponse<Map<String, dynamic>>> getCertificates() async {
    final raw = await _client.request('GET', '/certificates');
    final data = _expectMap(raw, '/certificates');
    _requireDataKey(data, '/certificates');
    return PaginatedResponse.fromJson(data, (v) => v);
  }

  Future<Map<String, dynamic>> getCertificate(String certificateId) async =>
      (await _client.request('GET', '/certificates/$certificateId'))
          as Map<String, dynamic>;

  Future<Map<String, dynamic>> getCertificateDownloadUrl(
    String certificateId,
  ) async =>
      (await _client.request('GET', '/certificates/$certificateId/download'))
          as Map<String, dynamic>;

  Future<Map<String, dynamic>> verifyCertificate(
    String verificationCode,
  ) async =>
      (await _client.request('GET', '/certificates/verify/$verificationCode'))
          as Map<String, dynamic>;

  Future<PaginatedResponse<Map<String, dynamic>>> getLearningPaths() async {
    final data = _expectMap(
      await _client.request('GET', '/learning-paths'),
      '/learning-paths',
    );
    if (data.containsKey('paths')) {
      final paths = (data['paths'] as List?) ?? const [];
      return PaginatedResponse<Map<String, dynamic>>(
        data: paths
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList(),
        pagination: {'total': paths.length, 'page': 1, 'limit': paths.length},
      );
    }
    _requireDataKey(data, '/learning-paths');
    return PaginatedResponse.fromJson(data, (v) => v);
  }

  Future<dynamic> getUserLearningPath() async =>
      _client.request('GET', '/learning-paths/me');

  Future<Map<String, dynamic>> joinLearningPath(String learningPathId) async =>
      _expectMap(
        await _client.request('POST', '/learning-paths/$learningPathId/join'),
        '/learning-paths/$learningPathId/join',
      );

  Future<Map<String, dynamic>> leaveLearningPath(String learningPathId) async =>
      _expectMap(
        await _client.request(
          'DELETE',
          '/learning-paths/$learningPathId/leave',
        ),
        '/learning-paths/$learningPathId/leave',
      );

  Future<Map<String, dynamic>> updatePreferences({
    bool? darkModeEnabled,
    String? preferredLocale,
  }) async =>
      (await _client.request(
            'PATCH',
            '/me/preferences',
            body: _client.toJson({
              'darkModeEnabled': ?darkModeEnabled,
              'preferredLocale': ?preferredLocale,
            }),
          ))
          as Map<String, dynamic>;

  Future<User> updateProfile({
    String? displayName,
    String? email,
    String? bio,
  }) async {
    final data =
        await _client.request(
              'PATCH',
              '/me',
              body: _client.toJson({
                'displayName': ?displayName,
                'email': ?email,
                'bio': ?bio,
              }),
            )
            as Map<String, dynamic>;
    return User.fromJson(data);
  }

  Future<Map<String, dynamic>> updateProfilePatch({
    String? displayName,
    String? email,
    String? bio,
  }) async => _expectMap(
    await _client.request(
      'PATCH',
      '/me',
      body: _client.toJson({
        'displayName': ?displayName,
        'email': ?email,
        'bio': ?bio,
      }),
    ),
    '/me',
  );

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async =>
      (await _client.request(
            'POST',
            '/me/password/change',
            body: _client.toJson({
              'currentPassword': currentPassword,
              'newPassword': newPassword,
            }),
          ))
          as Map<String, dynamic>;

  Future<Map<String, dynamic>> getUserProfile(String userId) async =>
      (await _client.request('GET', '/users/$userId')) as Map<String, dynamic>;

  Future<PaginatedResponse<Map<String, dynamic>>> getUserForums({
    int? page,
    int? limit,
  }) async {
    final data = _expectMap(
      await _client.request(
        'GET',
        '/forums/me',
        query: {'page': ?page, 'limit': ?limit},
      ),
      '/forums/me',
    );
    _requireDataKey(data, '/forums/me');
    return PaginatedResponse.fromJson(data, (v) => v);
  }

  Future<PaginatedResponse<Map<String, dynamic>>> getForumPosts(
    String courseId, {
    int? page,
    int? limit,
  }) async {
    final data = _expectMap(
      await _client.request(
        'GET',
        '/forums/courses/$courseId/posts',
        query: {'page': ?page, 'limit': ?limit},
      ),
      '/forums/courses/$courseId/posts',
    );
    _requireDataKey(data, '/forums/courses/$courseId/posts');
    return PaginatedResponse.fromJson(data, (v) => v);
  }

  Future<Map<String, dynamic>> getForumPost(String postId) async =>
      (await _client.request('GET', '/forums/posts/$postId'))
          as Map<String, dynamic>;

  Future<Map<String, dynamic>> createForumPost({
    required String courseId,
    required String title,
    required String content,
  }) async =>
      (await _client.request(
            'POST',
            '/forums/posts',
            body: _client.toJson({
              'courseId': courseId,
              'title': title,
              'content': content,
            }),
          ))
          as Map<String, dynamic>;

  Future<PaginatedResponse<Map<String, dynamic>>> getForumReplies(
    String postId, {
    int? page,
    int? limit,
  }) async {
    final data = _expectMap(
      await _client.request(
        'GET',
        '/forums/posts/$postId/replies',
        query: {'page': ?page, 'limit': ?limit},
      ),
      '/forums/posts/$postId/replies',
    );
    if (data.containsKey('replies')) {
      final replies = (data['replies'] as List?) ?? const [];
      return PaginatedResponse<Map<String, dynamic>>(
        data: replies
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList(),
        pagination: {
          'total': (data['total'] as num?)?.toInt() ?? replies.length,
          'page': (data['page'] as num?)?.toInt() ?? 1,
          'limit': (data['limit'] as num?)?.toInt() ?? replies.length,
        },
      );
    }
    if (data.containsKey('data') && data['data'] is List) {
      return PaginatedResponse.fromJson(data, (v) => v);
    }
    throw ApiError(
      message:
          'Invalid response from /forums/posts/$postId/replies: expected `replies` or `data` array',
      timestamp: DateTime.now().toIso8601String(),
    );
  }

  Future<Map<String, dynamic>> createForumReply({
    required String postId,
    required String content,
    String? parentReplyId,
  }) async =>
      (await _client.request(
            'POST',
            '/forums/replies',
            body: _client.toJson({
              'postId': postId,
              'content': content,
              'parentReplyId': ?parentReplyId,
            }),
          ))
          as Map<String, dynamic>;

  Future<void> deleteForumPost(String postId) async =>
      _client.request('DELETE', '/forums/posts/$postId');

  Future<Map<String, dynamic>> updateForumPostStatus({
    required String postId,
    required String status,
  }) async => _expectMap(
    await _client.request(
      'PUT',
      '/forums/posts/$postId/status',
      body: _client.toJson({'status': status}),
    ),
    '/forums/posts/$postId/status',
  );

  Future<Map<String, dynamic>> updateForumReplyStatus({
    required String replyId,
    required String status,
  }) async => _expectMap(
    await _client.request(
      'PUT',
      '/forums/replies/$replyId/status',
      body: _client.toJson({'status': status}),
    ),
    '/forums/replies/$replyId/status',
  );

  Future<void> deleteForumReply(String replyId) async =>
      _client.request('DELETE', '/forums/replies/$replyId');

  // ==================== ADMIN: USERS ====================

  Future<PaginatedResponse<AdminUser>> listUsers({
    String? search,
    String? role,
    String? status,
    int? page,
    int? limit,
  }) async {
    final data = _expectMap(
      await _client.request(
        'GET',
        '/admin/users',
        query: {
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
          if (role != null && role.trim().isNotEmpty) 'role': role.trim(),
          if (status != null && status.trim().isNotEmpty)
            'status': status.trim(),
          'page': ?page,
          'limit': ?limit,
        },
      ),
      '/admin/users',
    );
    _requireDataKey(data, '/admin/users');
    return PaginatedResponse.fromJson(data, AdminUser.fromJson);
  }

  Future<AdminUserStats> getUserStats() async {
    final data = _expectMap(
      await _client.request('GET', '/admin/users/stats'),
      '/admin/users/stats',
    );
    return AdminUserStats.fromJson(data);
  }

  Future<void> updateUserRoles(String userId, List<String> roles) async {
    await _client.request(
      'PUT',
      '/admin/users/$userId/roles',
      body: _client.toJson({'roles': roles}),
    );
  }

  Future<void> activateUser(String userId) async {
    await _client.request('POST', '/admin/users/$userId/activate');
  }

  Future<void> deactivateUser(String userId) async {
    await _client.request('POST', '/admin/users/$userId/deactivate');
  }

  Future<void> deleteUser(String userId) async {
    await _client.request('DELETE', '/admin/users/$userId');
  }

  // ==================== ADMIN: LEARNING PATHS ====================

  Future<List<AdminLearningPath>> getAllLearningPathsAdmin() async {
    final raw = await _client.request('GET', '/admin/learning-paths');
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map(AdminLearningPath.fromJson)
          .toList();
    }
    final data = _expectMap(raw, '/admin/learning-paths');
    final list = (data['data'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(AdminLearningPath.fromJson)
        .toList();
    return list;
  }

  Future<AdminLearningPath> getLearningPathAdmin(String pathId) async {
    final data = _expectMap(
      await _client.request('GET', '/admin/learning-paths/$pathId'),
      '/admin/learning-paths/$pathId',
    );
    return AdminLearningPath.fromJson(data);
  }

  Future<AdminLearningPath> createLearningPath({
    required String slug,
    required String title,
    required String description,
    required bool isPublic,
    required List<String> wantToLearn,
    required List<String> languages,
    required List<String> alreadyKnow,
  }) async {
    final data = _expectMap(
      await _client.request(
        'POST',
        '/admin/learning-paths',
        body: _client.toJson({
          'slug': slug,
          'title': title,
          'description': description,
          'isPublic': isPublic,
          'criteria': {
            'wantToLearn': wantToLearn,
            'languages': languages,
            'alreadyKnow': alreadyKnow,
          },
        }),
      ),
      '/admin/learning-paths',
    );
    return AdminLearningPath.fromJson(data);
  }

  Future<Map<String, dynamic>> updateLearningPathPatch({
    required String pathId,
    required String title,
    required String description,
    required List<String> wantToLearn,
    required List<String> languages,
    required List<String> alreadyKnow,
    required bool isPublic,
  }) async {
    return _expectMap(
      await _client.request(
        'PATCH',
        '/admin/learning-paths/$pathId',
        body: _client.toJson({
          'title': title,
          'description': description,
          'criteria': {
            'wantToLearn': wantToLearn,
            'languages': languages,
            'alreadyKnow': alreadyKnow,
          },
          'isPublic': isPublic,
        }),
      ),
      '/admin/learning-paths/$pathId',
    );
  }

  Future<void> deleteLearningPath(String pathId) async {
    await _client.request('DELETE', '/admin/learning-paths/$pathId');
  }

  Future<void> addCoursesToPath(String pathId, List<String> courseIds) async {
    await _client.request(
      'POST',
      '/admin/learning-paths/$pathId/courses',
      body: _client.toJson({'courseIds': courseIds}),
    );
  }

  Future<void> removeCourseFromPath(String pathId, String courseId) async {
    await _client.request(
      'DELETE',
      '/admin/learning-paths/$pathId/courses/$courseId',
    );
  }

  Future<void> reorderCoursesInPath(
    String pathId,
    List<String> courseIds,
  ) async {
    await _client.request(
      'PATCH',
      '/admin/learning-paths/$pathId/courses/reorder',
      body: _client.toJson({'courseIds': courseIds}),
    );
  }

  Future<List<AdminCourseSummary>> getInstructorCourses() async {
    final raw = await _client.request('GET', '/admin/courses');
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map(AdminCourseSummary.fromJson)
          .toList();
    }
    final data = _expectMap(raw, '/admin/courses');
    if (data['data'] is List) {
      return (data['data'] as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(AdminCourseSummary.fromJson)
          .toList();
    }
    throw ApiError(
      message:
          'Invalid response from /admin/courses: expected array or object with `data` array',
      timestamp: DateTime.now().toIso8601String(),
    );
  }

  Future<List<AdminCourse>> getAdminCourses() async {
    final raw = await _client.request('GET', '/admin/courses');
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map(AdminCourse.fromJson)
          .toList();
    }
    final data = _expectMap(raw, '/admin/courses');
    if (data['data'] is List) {
      return (data['data'] as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(AdminCourse.fromJson)
          .toList();
    }
    throw ApiError(
      message:
          'Invalid response from /admin/courses: expected array or object with `data` array',
      timestamp: DateTime.now().toIso8601String(),
    );
  }

  Future<AdminCourse> createAdminCourse({
    required String title,
    required String subtitle,
    required String description,
    required String level,
    required String language,
    required int priceCents,
    required String currencyCode,
    String? trailerUrl,
  }) async {
    final data = _expectMap(
      await _client.request(
        'POST',
        '/admin/courses',
        body: _client.toJson({
          'title': title,
          'subtitle': subtitle,
          'description': description,
          'level': level,
          'language': language,
          'priceCents': priceCents,
          'currencyCode': currencyCode,
          if (trailerUrl != null && trailerUrl.trim().isNotEmpty)
            'trailerUrl': trailerUrl.trim(),
        }),
      ),
      '/admin/courses',
    );
    return AdminCourse.fromJson(data);
  }

  Future<AdminCourse> getAdminCourse(String courseId) async {
    final data = _expectMap(
      await _client.request('GET', '/admin/courses/$courseId'),
      '/admin/courses/$courseId',
    );
    return AdminCourse.fromJson(data);
  }

  Future<Map<String, dynamic>> updateAdminCoursePatch({
    required String courseId,
    required String title,
    required String subtitle,
    required String description,
    required String level,
    required String language,
    required int priceCents,
    required String currencyCode,
    String? trailerUrl,
    bool? isPublished,
  }) async {
    return _expectMap(
      await _client.request(
        'PUT',
        '/admin/courses/$courseId',
        body: _client.toJson({
          'title': title,
          'subtitle': subtitle,
          'description': description,
          'level': level,
          'language': language,
          'priceCents': priceCents,
          'currencyCode': currencyCode,
          'trailerUrl': ?trailerUrl,
          'isPublished': ?isPublished,
        }),
      ),
      '/admin/courses/$courseId',
    );
  }

  Future<void> deleteAdminCourse(String courseId) async {
    await _client.request('DELETE', '/admin/courses/$courseId');
  }

  Future<void> publishAdminCourse(String courseId) async {
    await _client.request('POST', '/admin/courses/$courseId/publish');
  }

  Future<void> unpublishAdminCourse(String courseId) async {
    await _client.request('POST', '/admin/courses/$courseId/unpublish');
  }

  Future<AdminCourse> uploadAdminCourseThumbnail({
    required String courseId,
    required String fileName,
    required List<int> bytes,
    String? contentType,
  }) async {
    final data = _expectMap(
      await _client.requestMultipart(
        'POST',
        '/admin/courses/$courseId/thumbnail/upload',
        fileField: 'file',
        fileName: fileName,
        fileBytes: bytes is Uint8List ? bytes : Uint8List.fromList(bytes),
        contentType: contentType,
      ),
      '/admin/courses/$courseId/thumbnail/upload',
    );
    return AdminCourse.fromJson(data);
  }

  Future<List<SandboxLanguageSummary>> getSandboxLanguageCatalog({
    bool includeBaseCode = false,
  }) async {
    final raw = await getSandboxLanguages(includeBaseCode: includeBaseCode);
    return raw
        .whereType<Map<String, dynamic>>()
        .map(SandboxLanguageSummary.fromJson)
        .toList();
  }

  Future<AdminUnit> createAdminUnit({
    required String courseId,
    required String title,
    required String type,
    required String summary,
    int? estimatedMinutes,
  }) async {
    final data = _expectMap(
      await _client.request(
        'POST',
        '/admin/courses/$courseId/units',
        body: _client.toJson({
          'title': title,
          'type': type,
          'summary': summary,
          'estimatedMinutes': estimatedMinutes,
        }),
      ),
      '/admin/courses/$courseId/units',
    );
    return AdminUnit.fromJson(data);
  }

  Future<Map<String, dynamic>> updateAdminUnitPatch({
    required String unitId,
    String? title,
    String? type,
    String? summary,
    int? estimatedMinutes,
    bool? isPublished,
    int? position,
  }) async {
    return _expectMap(
      await _client.request(
        'PUT',
        '/admin/units/$unitId',
        body: _client.toJson({
          'title': ?title,
          'type': ?type,
          'summary': ?summary,
          'estimatedMinutes': ?estimatedMinutes,
          'isPublished': ?isPublished,
          'position': ?position,
        }),
      ),
      '/admin/units/$unitId',
    );
  }

  Future<void> deleteAdminUnit(String unitId) async {
    await _client.request('DELETE', '/admin/units/$unitId');
  }

  Future<void> addAdminUnitPrerequisite({
    required String unitId,
    required String prerequisiteUnitId,
  }) async {
    await _client.request(
      'POST',
      '/admin/units/$unitId/prerequisites',
      body: _client.toJson({'prerequisiteUnitId': prerequisiteUnitId}),
    );
  }

  Future<void> removeAdminUnitPrerequisite({
    required String unitId,
    required String prerequisiteUnitId,
  }) async {
    await _client.request(
      'DELETE',
      '/admin/units/$unitId/prerequisites/$prerequisiteUnitId',
    );
  }

  Future<AdminUnitDetail> getAdminUnitById(String unitId) async {
    final data = _expectMap(
      await _client.request('GET', '/admin/units/$unitId'),
      '/admin/units/$unitId',
    );
    return AdminUnitDetail.fromJson(data);
  }

  Future<AdminModuleContent?> getAdminModuleContent(String unitId) async {
    final data = await _client.request('GET', '/admin/units/$unitId/content');
    if (data == null) return null;
    return AdminModuleContent.fromJson(
      _expectMap(data, '/admin/units/$unitId/content'),
    );
  }

  Future<AdminModuleContent> createAdminModuleContent({
    required String unitId,
    required String contentKind,
    String? videoUrl,
    String? articleMarkdown,
    String? subtitle,
    String? subtitleS3Key,
    List<double>? playbackSpeeds,
    bool? supportsPip,
  }) async {
    final data = _expectMap(
      await _client.request(
        'POST',
        '/admin/units/$unitId/content',
        body: _client.toJson({
          'contentKind': contentKind,
          'videoUrl': ?videoUrl,
          'articleMarkdown': ?articleMarkdown,
          'subtitle': ?subtitle,
          'subtitleS3Key': ?subtitleS3Key,
          'playbackSpeeds': ?playbackSpeeds,
          'supportsPip': ?supportsPip,
        }),
      ),
      '/admin/units/$unitId/content',
    );
    return AdminModuleContent.fromJson(data);
  }

  Future<AdminModuleContent> updateAdminModuleContent({
    required String unitId,
    String? contentKind,
    String? videoUrl,
    String? articleMarkdown,
    String? subtitle,
    String? subtitleS3Key,
    List<double>? playbackSpeeds,
    bool? supportsPip,
  }) async {
    final data = _expectMap(
      await _client.request(
        'PUT',
        '/admin/units/$unitId/content',
        body: _client.toJson({
          'contentKind': ?contentKind,
          'videoUrl': ?videoUrl,
          'articleMarkdown': ?articleMarkdown,
          'subtitle': ?subtitle,
          'subtitleS3Key': ?subtitleS3Key,
          'playbackSpeeds': ?playbackSpeeds,
          'supportsPip': ?supportsPip,
        }),
      ),
      '/admin/units/$unitId/content',
    );
    return AdminModuleContent.fromJson(data);
  }

  Future<void> deleteAdminModuleContent(String unitId) async {
    await _client.request('DELETE', '/admin/units/$unitId/content');
  }

  Future<Map<String, dynamic>> uploadAdminModuleVideo({
    required String unitId,
    required String fileName,
    required List<int> bytes,
    String? contentType,
  }) async {
    return _expectMap(
      await _client.requestMultipart(
        'POST',
        '/admin/units/$unitId/content/video/upload',
        fileField: 'file',
        fileName: fileName,
        fileBytes: bytes is Uint8List ? bytes : Uint8List.fromList(bytes),
        contentType: contentType,
      ),
      '/admin/units/$unitId/content/video/upload',
    );
  }

  Future<List<AdminModuleResource>> listAdminModuleResources(
    String unitId,
  ) async {
    final raw = await _client.request('GET', '/admin/units/$unitId/resources');
    return _expectList(raw, '/admin/units/$unitId/resources')
        .whereType<Map<String, dynamic>>()
        .map(AdminModuleResource.fromJson)
        .toList();
  }

  Future<AdminModuleResource> createAdminModuleResource({
    required String unitId,
    required String label,
    required String resourceType,
    required String s3Key,
  }) async {
    final data = _expectMap(
      await _client.request(
        'POST',
        '/admin/units/$unitId/resources',
        body: _client.toJson({
          'label': label,
          'resourceType': resourceType,
          's3Key': s3Key,
        }),
      ),
      '/admin/units/$unitId/resources',
    );
    return AdminModuleResource.fromJson(data);
  }

  Future<AdminModuleResource> updateAdminModuleResource({
    required String resourceId,
    String? label,
    String? resourceType,
    String? s3Key,
  }) async {
    final data = _expectMap(
      await _client.request(
        'PUT',
        '/admin/module-resources/$resourceId',
        body: _client.toJson({
          'label': ?label,
          'resourceType': ?resourceType,
          's3Key': ?s3Key,
        }),
      ),
      '/admin/module-resources/$resourceId',
    );
    return AdminModuleResource.fromJson(data);
  }

  Future<void> deleteAdminModuleResource(String resourceId) async {
    await _client.request('DELETE', '/admin/module-resources/$resourceId');
  }

  Future<Map<String, dynamic>> uploadAdminModuleResource({
    required String unitId,
    required String fileName,
    required List<int> bytes,
    required String label,
    required String resourceType,
    String? contentType,
  }) async {
    return _expectMap(
      await _client.requestMultipart(
        'POST',
        '/admin/units/$unitId/resources/upload',
        fileField: 'file',
        fileName: fileName,
        fileBytes: bytes is Uint8List ? bytes : Uint8List.fromList(bytes),
        contentType: contentType,
        fields: {'label': label, 'resourceType': resourceType},
      ),
      '/admin/units/$unitId/resources/upload',
    );
  }

  Future<AdminExerciseDetail> createAdminExercise({
    required String unitId,
    required String title,
    required String promptMarkdown,
    required String difficulty,
    required String language,
    String? starterCode,
    int? maxCpuMs,
    int? maxMemoryKb,
  }) async {
    final data = _expectMap(
      await _client.request(
        'POST',
        '/admin/units/$unitId/exercises',
        body: _client.toJson({
          'title': title,
          'promptMarkdown': promptMarkdown,
          'difficulty': difficulty,
          'language': language,
          'starterCode': ?starterCode,
          'maxCpuMs': ?maxCpuMs,
          'maxMemoryKb': ?maxMemoryKb,
        }),
      ),
      '/admin/units/$unitId/exercises',
    );
    return AdminExerciseDetail.fromJson(data);
  }

  Future<AdminExerciseDetail> getAdminExerciseById(String exerciseId) async {
    final data = _expectMap(
      await _client.request('GET', '/admin/exercises/$exerciseId'),
      '/admin/exercises/$exerciseId',
    );
    return AdminExerciseDetail.fromJson(data);
  }

  Future<AdminExerciseDetail> updateAdminExercise({
    required String exerciseId,
    String? title,
    String? promptMarkdown,
    String? difficulty,
    String? language,
    String? starterCode,
    int? maxCpuMs,
    int? maxMemoryKb,
  }) async {
    final data = _expectMap(
      await _client.request(
        'PUT',
        '/admin/exercises/$exerciseId',
        body: _client.toJson({
          'title': ?title,
          'promptMarkdown': ?promptMarkdown,
          'difficulty': ?difficulty,
          'language': ?language,
          'starterCode': ?starterCode,
          'maxCpuMs': ?maxCpuMs,
          'maxMemoryKb': ?maxMemoryKb,
        }),
      ),
      '/admin/exercises/$exerciseId',
    );
    return AdminExerciseDetail.fromJson(data);
  }

  Future<void> deleteAdminExercise(String exerciseId) async {
    await _client.request('DELETE', '/admin/exercises/$exerciseId');
  }

  Future<AdminExerciseTestCase> addAdminExerciseTestCase({
    required String exerciseId,
    required String inputText,
    required String expectedOutput,
    bool? isHidden,
    String? description,
  }) async {
    final data = _expectMap(
      await _client.request(
        'POST',
        '/admin/exercises/$exerciseId/test-cases',
        body: _client.toJson({
          'inputText': inputText,
          'expectedOutput': expectedOutput,
          'description': ?description,
          'isHidden': ?isHidden,
        }),
      ),
      '/admin/exercises/$exerciseId/test-cases',
    );
    return AdminExerciseTestCase.fromJson(data);
  }

  Future<AdminExerciseTestCase> updateAdminExerciseTestCase({
    required String testCaseId,
    String? inputText,
    String? expectedOutput,
    bool? isHidden,
    String? description,
  }) async {
    final data = _expectMap(
      await _client.request(
        'PUT',
        '/admin/test-cases/$testCaseId',
        body: _client.toJson({
          'inputText': ?inputText,
          'expectedOutput': ?expectedOutput,
          'description': ?description,
          'isHidden': ?isHidden,
        }),
      ),
      '/admin/test-cases/$testCaseId',
    );
    return AdminExerciseTestCase.fromJson(data);
  }

  Future<void> deleteAdminExerciseTestCase(String testCaseId) async {
    await _client.request('DELETE', '/admin/test-cases/$testCaseId');
  }

  Future<AdminExerciseHint> addAdminExerciseHint({
    required String exerciseId,
    required String content,
    int? requiredFailedAttempts,
  }) async {
    final data = _expectMap(
      await _client.request(
        'POST',
        '/admin/exercises/$exerciseId/hints',
        body: _client.toJson({
          'content': content,
          'requiredFailedAttempts': ?requiredFailedAttempts,
        }),
      ),
      '/admin/exercises/$exerciseId/hints',
    );
    return AdminExerciseHint.fromJson(data);
  }

  Future<AdminExerciseHint> updateAdminExerciseHint({
    required String hintId,
    String? content,
    int? requiredFailedAttempts,
  }) async {
    final data = _expectMap(
      await _client.request(
        'PUT',
        '/admin/hints/$hintId',
        body: _client.toJson({
          'content': ?content,
          'requiredFailedAttempts': ?requiredFailedAttempts,
        }),
      ),
      '/admin/hints/$hintId',
    );
    return AdminExerciseHint.fromJson(data);
  }

  Future<void> deleteAdminExerciseHint(String hintId) async {
    await _client.request('DELETE', '/admin/hints/$hintId');
  }

  Future<AdminQuiz> createAdminQuiz({
    required String unitId,
    required String title,
    String? instructions,
    int? passingScore,
    int? timeLimitSeconds,
    bool? randomizeQuestions,
    bool? randomizeOptions,
  }) async {
    final data = _expectMap(
      await _client.request(
        'POST',
        '/admin/units/$unitId/quizzes',
        body: _client.toJson({
          'title': title,
          'instructions': ?instructions,
          'passingScore': ?passingScore,
          'timeLimitSeconds': ?timeLimitSeconds,
          'randomizeQuestions': ?randomizeQuestions,
          'randomizeOptions': ?randomizeOptions,
        }),
      ),
      '/admin/units/$unitId/quizzes',
    );
    return AdminQuiz.fromJson(data);
  }

  Future<AdminQuiz> getAdminQuizById(String quizId) async {
    final data = _expectMap(
      await _client.request('GET', '/admin/quizzes/$quizId'),
      '/admin/quizzes/$quizId',
    );
    return AdminQuiz.fromJson(data);
  }

  Future<AdminQuiz> updateAdminQuiz({
    required String quizId,
    String? title,
    String? instructions,
    int? passingScore,
    int? timeLimitSeconds,
    bool? randomizeQuestions,
    bool? randomizeOptions,
  }) async {
    final data = _expectMap(
      await _client.request(
        'PUT',
        '/admin/quizzes/$quizId',
        body: _client.toJson({
          'title': ?title,
          'instructions': ?instructions,
          'passingScore': ?passingScore,
          'timeLimitSeconds': ?timeLimitSeconds,
          'randomizeQuestions': ?randomizeQuestions,
          'randomizeOptions': ?randomizeOptions,
        }),
      ),
      '/admin/quizzes/$quizId',
    );
    return AdminQuiz.fromJson(data);
  }

  Future<void> deleteAdminQuiz(String quizId) async {
    await _client.request('DELETE', '/admin/quizzes/$quizId');
  }

  Future<AdminQuizQuestion> addAdminQuizQuestion({
    required String quizId,
    required String prompt,
    required int points,
    String? explanation,
    required List<Map<String, dynamic>> options,
  }) async {
    final data = _expectMap(
      await _client.request(
        'POST',
        '/admin/quizzes/$quizId/questions',
        body: _client.toJson({
          'prompt': prompt,
          'points': points,
          'explanation': ?explanation,
          'options': options,
        }),
      ),
      '/admin/quizzes/$quizId/questions',
    );
    return AdminQuizQuestion.fromJson(data);
  }

  Future<AdminQuizQuestion> updateAdminQuizQuestion({
    required String questionId,
    String? prompt,
    int? points,
    String? explanation,
  }) async {
    final data = _expectMap(
      await _client.request(
        'PUT',
        '/admin/questions/$questionId',
        body: _client.toJson({
          'prompt': ?prompt,
          'points': ?points,
          'explanation': ?explanation,
        }),
      ),
      '/admin/questions/$questionId',
    );
    return AdminQuizQuestion.fromJson(data);
  }

  Future<void> deleteAdminQuizQuestion(String questionId) async {
    await _client.request('DELETE', '/admin/questions/$questionId');
  }

  Future<AdminQuizOption> createAdminQuizOption({
    required String questionId,
    required String label,
    required bool isCorrect,
  }) async {
    final data = _expectMap(
      await _client.request(
        'POST',
        '/admin/questions/$questionId/options',
        body: _client.toJson({'label': label, 'isCorrect': isCorrect}),
      ),
      '/admin/questions/$questionId/options',
    );
    return AdminQuizOption.fromJson(data);
  }

  Future<AdminQuizOption> updateAdminQuizOption({
    required String optionId,
    String? label,
    bool? isCorrect,
  }) async {
    final data = _expectMap(
      await _client.request(
        'PUT',
        '/admin/options/$optionId',
        body: _client.toJson({'label': ?label, 'isCorrect': ?isCorrect}),
      ),
      '/admin/options/$optionId',
    );
    return AdminQuizOption.fromJson(data);
  }

  Future<void> deleteAdminQuizOption(String optionId) async {
    await _client.request('DELETE', '/admin/options/$optionId');
  }

  Future<AdminFinalExamQuestionComponent> createAdminFinalExamQuestion({
    required String unitId,
    required String prompt,
    required int points,
    String? explanation,
    required List<Map<String, dynamic>> options,
  }) async {
    final data = _expectMap(
      await _client.request(
        'POST',
        '/admin/units/$unitId/final-exam/questions',
        body: _client.toJson({
          'prompt': prompt,
          'points': points,
          'explanation': ?explanation,
          'options': options,
        }),
      ),
      '/admin/units/$unitId/final-exam/questions',
    );
    return AdminFinalExamQuestionComponent.fromJson(data);
  }

  Future<AdminFinalExamQuestionComponent> updateAdminFinalExamQuestion({
    required String unitId,
    required String questionId,
    String? prompt,
    int? points,
    String? explanation,
  }) async {
    final data = _expectMap(
      await _client.request(
        'PUT',
        '/admin/units/$unitId/final-exam/questions/$questionId',
        body: _client.toJson({
          'prompt': ?prompt,
          'points': ?points,
          'explanation': ?explanation,
        }),
      ),
      '/admin/units/$unitId/final-exam/questions/$questionId',
    );
    return AdminFinalExamQuestionComponent.fromJson(data);
  }

  Future<void> deleteAdminFinalExamQuestion({
    required String unitId,
    required String questionId,
  }) async {
    await _client.request(
      'DELETE',
      '/admin/units/$unitId/final-exam/questions/$questionId',
    );
  }

  Future<AdminQuizOption> createAdminFinalExamOption({
    required String unitId,
    required String questionId,
    required String label,
    required bool isCorrect,
  }) async {
    final data = _expectMap(
      await _client.request(
        'POST',
        '/admin/units/$unitId/final-exam/questions/$questionId/options',
        body: _client.toJson({'label': label, 'isCorrect': isCorrect}),
      ),
      '/admin/units/$unitId/final-exam/questions/$questionId/options',
    );
    return AdminQuizOption.fromJson(data);
  }

  Future<AdminQuizOption> updateAdminFinalExamOption({
    required String unitId,
    required String questionId,
    required String optionId,
    String? label,
    bool? isCorrect,
  }) async {
    final data = _expectMap(
      await _client.request(
        'PUT',
        '/admin/units/$unitId/final-exam/questions/$questionId/options/$optionId',
        body: _client.toJson({'label': ?label, 'isCorrect': ?isCorrect}),
      ),
      '/admin/units/$unitId/final-exam/questions/$questionId/options/$optionId',
    );
    return AdminQuizOption.fromJson(data);
  }

  Future<void> deleteAdminFinalExamOption({
    required String unitId,
    required String questionId,
    required String optionId,
  }) async {
    await _client.request(
      'DELETE',
      '/admin/units/$unitId/final-exam/questions/$questionId/options/$optionId',
    );
  }

  // ==================== ADMIN: BADGES ====================

  Future<List<AdminBadge>> getAllBadges() async {
    final raw = await _client.request('GET', '/admin/badges');
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map(AdminBadge.fromJson)
          .toList();
    }
    final data = _expectMap(raw, '/admin/badges');
    if (data['data'] is List) {
      return (data['data'] as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(AdminBadge.fromJson)
          .toList();
    }
    throw ApiError(
      message:
          'Invalid response from /admin/badges: expected array or object with `data` array',
      timestamp: DateTime.now().toIso8601String(),
    );
  }

  Future<List<BadgeCriteriaMetadata>> getBadgeCriteriaMetadata() async {
    final raw = await _client.request('GET', '/admin/badges/criteria');
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map(BadgeCriteriaMetadata.fromJson)
          .toList();
    }
    final data = _expectMap(raw, '/admin/badges/criteria');
    if (data['data'] is List) {
      return (data['data'] as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(BadgeCriteriaMetadata.fromJson)
          .toList();
    }
    throw ApiError(
      message:
          'Invalid response from /admin/badges/criteria: expected array or object with `data` array',
      timestamp: DateTime.now().toIso8601String(),
    );
  }

  Future<AdminBadge> createBadge({
    required String code,
    required String name,
    required String description,
    String? iconS3Key,
    required String criteriaType,
    String? language,
    int? xp,
  }) async {
    final data = _expectMap(
      await _client.request(
        'POST',
        '/admin/badges',
        body: _client.toJson({
          'code': code,
          'name': name,
          'description': description,
          'iconS3Key': iconS3Key,
          'criteriaType': criteriaType,
          'language': ?language,
          'xp': ?xp,
        }),
      ),
      '/admin/badges',
    );
    return AdminBadge.fromJson(data);
  }

  Future<AdminBadge> updateBadge({
    required String badgeId,
    required String code,
    required String name,
    required String description,
    String? iconS3Key,
    required String criteriaType,
    String? language,
    int? xp,
  }) async {
    final data = _expectMap(
      await _client.request(
        'PUT',
        '/admin/badges/$badgeId',
        body: _client.toJson({
          'code': code,
          'name': name,
          'description': description,
          'iconS3Key': iconS3Key,
          'criteriaType': criteriaType,
          'language': ?language,
          'xp': ?xp,
        }),
      ),
      '/admin/badges/$badgeId',
    );
    return AdminBadge.fromJson(data);
  }

  Future<void> deleteBadge(String badgeId) async {
    await _client.request('DELETE', '/admin/badges/$badgeId');
  }

  Future<AdminBadge> uploadBadgeIcon({
    required String badgeId,
    required String fileName,
    required List<int> bytes,
    String? contentType,
  }) async {
    final data = _expectMap(
      await _client.requestMultipart(
        'POST',
        '/admin/badges/$badgeId/icon/upload',
        fileField: 'file',
        fileName: fileName,
        fileBytes: bytes is Uint8List ? bytes : Uint8List.fromList(bytes),
        contentType: contentType,
      ),
      '/admin/badges/$badgeId/icon/upload',
    );
    return AdminBadge.fromJson(data);
  }
}
