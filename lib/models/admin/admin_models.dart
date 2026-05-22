class AdminUser {
  AdminUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.roles,
    required this.isActive,
    required this.createdAt,
    this.lastLoginAt,
  });

  final String id;
  final String email;
  final String displayName;
  final List<String> roles;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      final raw = value?.toString() ?? '';
      return DateTime.tryParse(raw) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }

    final roles = (json['roles'] as List<dynamic>? ?? const [])
        .map((role) => role.toString().toLowerCase())
        .toList();

    return AdminUser(
      id: (json['id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      displayName: (json['displayName'] ?? '').toString(),
      roles: roles,
      isActive: json['isActive'] == true,
      createdAt: parseDate(json['createdAt']),
      lastLoginAt: DateTime.tryParse((json['lastLoginAt'] ?? '').toString()),
    );
  }
}

class AdminUserStats {
  AdminUserStats({
    required this.totalUsers,
    required this.activeUsers,
    required this.inactiveUsers,
    required this.byRole,
  });

  final int totalUsers;
  final int activeUsers;
  final int inactiveUsers;
  final Map<String, int> byRole;

  factory AdminUserStats.fromJson(Map<String, dynamic> json) {
    final roleMap = <String, int>{};
    final rawRoleMap = json['byRole'];
    if (rawRoleMap is Map) {
      for (final entry in rawRoleMap.entries) {
        roleMap[entry.key.toString()] = _asInt(entry.value);
      }
    }
    return AdminUserStats(
      totalUsers: _asInt(json['totalUsers']),
      activeUsers: _asInt(json['activeUsers']),
      inactiveUsers: _asInt(json['inactiveUsers']),
      byRole: roleMap,
    );
  }
}

class AdminLearningPathCourse {
  AdminLearningPathCourse({
    required this.courseId,
    required this.courseName,
    required this.courseSlug,
    required this.courseLevel,
    required this.courseLanguage,
    required this.courseDescription,
    required this.position,
    this.courseThumbnail,
  });

  final String courseId;
  final String courseName;
  final String courseSlug;
  final String courseLevel;
  final String courseLanguage;
  final String courseDescription;
  final String? courseThumbnail;
  final int position;

  factory AdminLearningPathCourse.fromJson(Map<String, dynamic> json) {
    return AdminLearningPathCourse(
      courseId: (json['courseId'] ?? '').toString(),
      courseName: (json['courseName'] ?? '').toString(),
      courseSlug: (json['courseSlug'] ?? '').toString(),
      courseLevel: (json['courseLevel'] ?? '').toString(),
      courseLanguage: (json['courseLanguage'] ?? '').toString(),
      courseDescription: (json['courseDescription'] ?? '').toString(),
      courseThumbnail: json['courseThumbnail']?.toString(),
      position: _asInt(json['position']),
    );
  }
}

class AdminLearningPathCriteria {
  AdminLearningPathCriteria({
    required this.languages,
    required this.alreadyKnow,
    required this.wantToLearn,
  });

  final List<String> languages;
  final List<String> alreadyKnow;
  final List<String> wantToLearn;

  factory AdminLearningPathCriteria.fromJson(Map<String, dynamic> json) {
    List<String> listOf(dynamic value) {
      if (value is! List) return const [];
      return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }

    return AdminLearningPathCriteria(
      languages: listOf(json['languages']),
      alreadyKnow: listOf(json['alreadyKnow']),
      wantToLearn: listOf(json['wantToLearn']),
    );
  }

  AdminLearningPathCriteria copyWith({
    List<String>? languages,
    List<String>? alreadyKnow,
    List<String>? wantToLearn,
  }) {
    return AdminLearningPathCriteria(
      languages: languages ?? this.languages,
      alreadyKnow: alreadyKnow ?? this.alreadyKnow,
      wantToLearn: wantToLearn ?? this.wantToLearn,
    );
  }

  AdminLearningPathCriteria applyPatch(Map<String, dynamic> json) {
    List<String>? listOfIfPresent(String key) {
      if (!json.containsKey(key)) return null;
      final value = json[key];
      if (value is! List) return const [];
      return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }

    return copyWith(
      languages: listOfIfPresent('languages'),
      alreadyKnow: listOfIfPresent('alreadyKnow'),
      wantToLearn: listOfIfPresent('wantToLearn'),
    );
  }
}

class AdminLearningPath {
  AdminLearningPath({
    required this.id,
    required this.slug,
    required this.title,
    required this.description,
    required this.criteria,
    required this.courses,
    required this.createdAt,
    required this.isPublic,
  });

  final String id;
  final String slug;
  final String title;
  final String description;
  final bool isPublic;
  final AdminLearningPathCriteria criteria;
  final List<AdminLearningPathCourse> courses;
  final DateTime createdAt;

  factory AdminLearningPath.fromJson(Map<String, dynamic> json) {
    final criteriaMap = (json['criteria'] is Map<String, dynamic>)
        ? json['criteria'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final rawCourses = (json['courses'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(AdminLearningPathCourse.fromJson)
        .toList();

    return AdminLearningPath(
      id: (json['id'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      criteria: AdminLearningPathCriteria.fromJson(criteriaMap),
      courses: rawCourses,
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      isPublic: json['isPublic'] == true,
    );
  }

  AdminLearningPath copyWith({
    String? id,
    String? slug,
    String? title,
    String? description,
    bool? isPublic,
    AdminLearningPathCriteria? criteria,
    List<AdminLearningPathCourse>? courses,
    DateTime? createdAt,
  }) {
    return AdminLearningPath(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      title: title ?? this.title,
      description: description ?? this.description,
      criteria: criteria ?? this.criteria,
      courses: courses ?? this.courses,
      createdAt: createdAt ?? this.createdAt,
      isPublic: isPublic ?? this.isPublic,
    );
  }

  AdminLearningPath applyPatch(Map<String, dynamic> json) {
    final rawCriteria = json['criteria'];
    final hasCourses = json.containsKey('courses');
    final parsedCourses = hasCourses
        ? (json['courses'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(AdminLearningPathCourse.fromJson)
              .toList()
        : null;

    return copyWith(
      id: json.containsKey('id') ? (json['id'] ?? '').toString() : null,
      slug: json.containsKey('slug') ? (json['slug'] ?? '').toString() : null,
      title: json.containsKey('title')
          ? (json['title'] ?? '').toString()
          : null,
      description: json.containsKey('description')
          ? (json['description'] ?? '').toString()
          : null,
      isPublic: json.containsKey('isPublic') ? json['isPublic'] == true : null,
      criteria: rawCriteria is Map<String, dynamic>
          ? criteria.applyPatch(rawCriteria)
          : null,
      courses: parsedCourses,
      createdAt: json.containsKey('createdAt')
          ? DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
                DateTime.fromMillisecondsSinceEpoch(0)
          : null,
    );
  }
}

class AdminCourseSummary {
  AdminCourseSummary({
    required this.id,
    required this.title,
    required this.level,
  });

  final String id;
  final String title;
  final String level;

  factory AdminCourseSummary.fromJson(Map<String, dynamic> json) {
    return AdminCourseSummary(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      level: (json['level'] ?? '').toString(),
    );
  }
}

class SandboxLanguageSummary {
  SandboxLanguageSummary({
    required this.id,
    required this.name,
    this.version,
    this.baseCode,
  });

  final String id;
  final String name;
  final String? version;
  final String? baseCode;

  factory SandboxLanguageSummary.fromJson(Map<String, dynamic> json) {
    return SandboxLanguageSummary(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      version: json['version']?.toString(),
      baseCode: json['baseCode']?.toString(),
    );
  }
}

class AdminCourseCreator {
  AdminCourseCreator({required this.id, required this.displayName, this.bio});

  final String id;
  final String displayName;
  final String? bio;

  factory AdminCourseCreator.fromJson(Map<String, dynamic> json) {
    return AdminCourseCreator(
      id: (json['id'] ?? '').toString(),
      displayName: (json['displayName'] ?? '').toString(),
      bio: json['bio']?.toString(),
    );
  }
}

class AdminPrerequisite {
  AdminPrerequisite({
    required this.id,
    required this.title,
    this.type,
    this.position,
  });

  final String id;
  final String title;
  final String? type;
  final int? position;

  factory AdminPrerequisite.fromJson(Map<String, dynamic> json) {
    return AdminPrerequisite(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      type: json['type']?.toString(),
      position: json['position'] == null ? null : _asInt(json['position']),
    );
  }
}

class AdminUnitPreview {
  AdminUnitPreview({
    required this.id,
    required this.title,
    required this.summary,
    required this.type,
    required this.estimatedMinutes,
    required this.position,
    required this.isPublished,
    required this.prerequisites,
    required this.requiredFor,
  });

  final String id;
  final String title;
  final String summary;
  final String type;
  final int estimatedMinutes;
  final int position;
  final bool isPublished;
  final List<AdminPrerequisite> prerequisites;
  final List<AdminPrerequisite> requiredFor;

  factory AdminUnitPreview.fromJson(Map<String, dynamic> json) {
    List<AdminPrerequisite> parsePrerequisites(String key) {
      return (json[key] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AdminPrerequisite.fromJson)
          .toList();
    }

    return AdminUnitPreview(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      summary: (json['summary'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      estimatedMinutes: _asInt(json['estimatedMinutes']),
      position: _asInt(json['position']),
      isPublished: json['isPublished'] == true,
      prerequisites: parsePrerequisites('prerequisites'),
      requiredFor: parsePrerequisites('requiredFor'),
    );
  }

  AdminUnitPreview copyWith({
    String? id,
    String? title,
    String? summary,
    String? type,
    int? estimatedMinutes,
    int? position,
    bool? isPublished,
    List<AdminPrerequisite>? prerequisites,
    List<AdminPrerequisite>? requiredFor,
  }) {
    return AdminUnitPreview(
      id: id ?? this.id,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      type: type ?? this.type,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      position: position ?? this.position,
      isPublished: isPublished ?? this.isPublished,
      prerequisites: prerequisites ?? this.prerequisites,
      requiredFor: requiredFor ?? this.requiredFor,
    );
  }

  AdminUnitPreview applyPatch(Map<String, dynamic> json) {
    List<AdminPrerequisite>? parseOptionalPrerequisites(String key) {
      if (!json.containsKey(key)) return null;
      return (json[key] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AdminPrerequisite.fromJson)
          .toList();
    }

    return copyWith(
      id: json.containsKey('id') ? (json['id'] ?? '').toString() : null,
      title: json.containsKey('title')
          ? (json['title'] ?? '').toString()
          : null,
      summary: json.containsKey('summary')
          ? (json['summary'] ?? '').toString()
          : null,
      type: json.containsKey('type') ? (json['type'] ?? '').toString() : null,
      estimatedMinutes: json.containsKey('estimatedMinutes')
          ? _asInt(json['estimatedMinutes'])
          : null,
      position: json.containsKey('position') ? _asInt(json['position']) : null,
      isPublished: json.containsKey('isPublished')
          ? json['isPublished'] == true
          : null,
      prerequisites: parseOptionalPrerequisites('prerequisites'),
      requiredFor: parseOptionalPrerequisites('requiredFor'),
    );
  }
}

class AdminCourse {
  AdminCourse({
    required this.id,
    required this.slug,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.thumbnailS3Key,
    required this.trailerUrl,
    required this.level,
    required this.language,
    required this.priceCents,
    required this.currencyCode,
    required this.unitCount,
    required this.isPublished,
    required this.creator,
    required this.createdAt,
    required this.updatedAt,
    required this.units,
  });

  final String id;
  final String slug;
  final String title;
  final String subtitle;
  final String description;
  final String? thumbnailS3Key;
  final String? trailerUrl;
  final String level;
  final String language;
  final int priceCents;
  final String currencyCode;
  final int unitCount;
  final bool isPublished;
  final AdminCourseCreator creator;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<AdminUnitPreview> units;

  factory AdminCourse.fromJson(Map<String, dynamic> json) {
    final creatorMap = (json['creator'] is Map<String, dynamic>)
        ? json['creator'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final units = (json['units'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(AdminUnitPreview.fromJson)
        .toList();

    return AdminCourse(
      id: (json['id'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      subtitle: (json['subtitle'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      thumbnailS3Key: json['thumbnailS3Key']?.toString(),
      trailerUrl: json['trailerUrl']?.toString(),
      level: (json['level'] ?? '').toString(),
      language: (json['language'] ?? '').toString(),
      priceCents: _asInt(json['priceCents']),
      currencyCode: (json['currencyCode'] ?? '').toString(),
      unitCount: json['unitCount'] == null
          ? units.length
          : _asInt(json['unitCount']),
      isPublished: json['isPublished'] == true,
      creator: AdminCourseCreator.fromJson(creatorMap),
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          DateTime.tryParse((json['updatedAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      units: units,
    );
  }

  AdminCourse copyWith({
    String? id,
    String? slug,
    String? title,
    String? subtitle,
    String? description,
    String? thumbnailS3Key,
    String? trailerUrl,
    String? level,
    String? language,
    int? priceCents,
    String? currencyCode,
    int? unitCount,
    bool? isPublished,
    AdminCourseCreator? creator,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<AdminUnitPreview>? units,
  }) {
    return AdminCourse(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      thumbnailS3Key: thumbnailS3Key ?? this.thumbnailS3Key,
      trailerUrl: trailerUrl ?? this.trailerUrl,
      level: level ?? this.level,
      language: language ?? this.language,
      priceCents: priceCents ?? this.priceCents,
      currencyCode: currencyCode ?? this.currencyCode,
      unitCount: unitCount ?? this.unitCount,
      isPublished: isPublished ?? this.isPublished,
      creator: creator ?? this.creator,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      units: units ?? this.units,
    );
  }

  AdminCourse applyPatch(Map<String, dynamic> json) {
    List<AdminUnitPreview>? parsedUnits;
    if (json.containsKey('units')) {
      parsedUnits = (json['units'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AdminUnitPreview.fromJson)
          .toList();
    }

    return copyWith(
      id: json.containsKey('id') ? (json['id'] ?? '').toString() : null,
      slug: json.containsKey('slug') ? (json['slug'] ?? '').toString() : null,
      title: json.containsKey('title')
          ? (json['title'] ?? '').toString()
          : null,
      subtitle: json.containsKey('subtitle')
          ? (json['subtitle'] ?? '').toString()
          : null,
      description: json.containsKey('description')
          ? (json['description'] ?? '').toString()
          : null,
      thumbnailS3Key: json.containsKey('thumbnailS3Key')
          ? json['thumbnailS3Key']?.toString()
          : null,
      trailerUrl: json.containsKey('trailerUrl')
          ? json['trailerUrl']?.toString()
          : null,
      level: json.containsKey('level')
          ? (json['level'] ?? '').toString()
          : null,
      language: json.containsKey('language')
          ? (json['language'] ?? '').toString()
          : null,
      priceCents: json.containsKey('priceCents')
          ? _asInt(json['priceCents'])
          : null,
      currencyCode: json.containsKey('currencyCode')
          ? (json['currencyCode'] ?? '').toString()
          : null,
      unitCount: json.containsKey('unitCount')
          ? _asInt(json['unitCount'])
          : null,
      isPublished: json.containsKey('isPublished')
          ? json['isPublished'] == true
          : null,
      creator: json['creator'] is Map<String, dynamic>
          ? AdminCourseCreator.fromJson(json['creator'] as Map<String, dynamic>)
          : null,
      createdAt: json.containsKey('createdAt')
          ? DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
                DateTime.fromMillisecondsSinceEpoch(0)
          : null,
      updatedAt: json.containsKey('updatedAt')
          ? DateTime.tryParse((json['updatedAt'] ?? '').toString()) ??
                DateTime.fromMillisecondsSinceEpoch(0)
          : null,
      units: parsedUnits,
    );
  }
}

class AdminUnit {
  AdminUnit({
    required this.id,
    required this.courseId,
    required this.title,
    required this.summary,
    required this.type,
    required this.position,
    required this.estimatedMinutes,
    required this.isPublished,
    required this.createdAt,
    required this.updatedAt,
    required this.prerequisites,
    required this.requiredFor,
  });

  final String id;
  final String courseId;
  final String title;
  final String summary;
  final String type;
  final int position;
  final int estimatedMinutes;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<AdminPrerequisite> prerequisites;
  final List<AdminPrerequisite> requiredFor;

  factory AdminUnit.fromJson(Map<String, dynamic> json) {
    List<AdminPrerequisite> parse(String key) {
      return (json[key] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AdminPrerequisite.fromJson)
          .toList();
    }

    return AdminUnit(
      id: (json['id'] ?? '').toString(),
      courseId: (json['courseId'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      summary: (json['summary'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      position: _asInt(json['position']),
      estimatedMinutes: _asInt(json['estimatedMinutes']),
      isPublished: json['isPublished'] == true,
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          DateTime.tryParse((json['updatedAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      prerequisites: parse('prerequisites'),
      requiredFor: parse('requiredFor'),
    );
  }
}

class AdminModuleContent {
  AdminModuleContent({
    required this.contentKind,
    this.videoUrl,
    this.articleMarkdown,
    this.subtitle,
    this.subtitleS3Key,
    required this.playbackSpeeds,
    required this.supportsPip,
  });

  final String contentKind;
  final String? videoUrl;
  final String? articleMarkdown;
  final String? subtitle;
  final String? subtitleS3Key;
  final List<double> playbackSpeeds;
  final bool supportsPip;

  factory AdminModuleContent.fromJson(Map<String, dynamic> json) {
    return AdminModuleContent(
      contentKind: (json['contentKind'] ?? '').toString(),
      videoUrl: json['videoUrl']?.toString(),
      articleMarkdown: json['articleMarkdown']?.toString(),
      subtitle: json['subtitle']?.toString(),
      subtitleS3Key: json['subtitleS3Key']?.toString(),
      playbackSpeeds: _asDoubleList(json['playbackSpeeds']),
      supportsPip: json['supportsPip'] != false,
    );
  }
}

class AdminModuleResource {
  AdminModuleResource({
    required this.id,
    required this.unitId,
    required this.label,
    required this.resourceType,
    required this.s3Key,
    this.url,
    required this.createdAt,
  });

  final String id;
  final String unitId;
  final String label;
  final String resourceType;
  final String s3Key;
  final String? url;
  final DateTime createdAt;

  factory AdminModuleResource.fromJson(Map<String, dynamic> json) {
    return AdminModuleResource(
      id: (json['id'] ?? '').toString(),
      unitId: (json['unitId'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      resourceType: (json['resourceType'] ?? '').toString(),
      s3Key: (json['s3Key'] ?? '').toString(),
      url: json['url']?.toString(),
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class AdminExerciseTestCase {
  AdminExerciseTestCase({
    required this.id,
    required this.inputText,
    required this.expectedOutput,
    this.description,
    required this.isHidden,
    required this.weight,
  });

  final String id;
  final String inputText;
  final String expectedOutput;
  final String? description;
  final bool isHidden;
  final int weight;

  factory AdminExerciseTestCase.fromJson(Map<String, dynamic> json) {
    return AdminExerciseTestCase(
      id: (json['id'] ?? '').toString(),
      inputText: (json['inputText'] ?? '').toString(),
      expectedOutput: (json['expectedOutput'] ?? '').toString(),
      description: json['description']?.toString(),
      isHidden: json['isHidden'] == true,
      weight: _asInt(json['weight']),
    );
  }
}

class AdminExerciseHint {
  AdminExerciseHint({
    required this.id,
    required this.hintText,
    required this.unlockAfterFailedAttempts,
    required this.position,
  });

  final String id;
  final String hintText;
  final int unlockAfterFailedAttempts;
  final int position;

  factory AdminExerciseHint.fromJson(Map<String, dynamic> json) {
    return AdminExerciseHint(
      id: (json['id'] ?? '').toString(),
      hintText: (json['hintText'] ?? json['content'] ?? '').toString(),
      unlockAfterFailedAttempts: _asInt(
        json['unlockAfterFailedAttempts'] ?? json['requiredFailedAttempts'],
      ),
      position: _asInt(json['position']),
    );
  }
}

class AdminExerciseDetail {
  AdminExerciseDetail({
    required this.id,
    required this.title,
    required this.promptMarkdown,
    required this.difficulty,
    required this.language,
    required this.starterCode,
    required this.maxCpuMs,
    required this.maxMemoryKb,
    required this.createdAt,
    required this.testCases,
    required this.hints,
  });

  final String id;
  final String title;
  final String promptMarkdown;
  final String difficulty;
  final String language;
  final String starterCode;
  final int maxCpuMs;
  final int maxMemoryKb;
  final DateTime createdAt;
  final List<AdminExerciseTestCase> testCases;
  final List<AdminExerciseHint> hints;

  factory AdminExerciseDetail.fromJson(Map<String, dynamic> json) {
    return AdminExerciseDetail(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      promptMarkdown: (json['promptMarkdown'] ?? '').toString(),
      difficulty: (json['difficulty'] ?? '').toString(),
      language: (json['language'] ?? '').toString(),
      starterCode: (json['starterCode'] ?? '').toString(),
      maxCpuMs: _asInt(json['maxCpuMs']),
      maxMemoryKb: _asInt(json['maxMemoryKb']),
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      testCases: (json['testCases'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AdminExerciseTestCase.fromJson)
          .toList(),
      hints: (json['hints'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AdminExerciseHint.fromJson)
          .toList(),
    );
  }
}

class AdminQuizOption {
  AdminQuizOption({
    required this.id,
    required this.label,
    required this.isCorrect,
    this.position,
  });

  final String id;
  final String label;
  final bool isCorrect;
  final int? position;

  factory AdminQuizOption.fromJson(Map<String, dynamic> json) {
    return AdminQuizOption(
      id: (json['id'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      isCorrect: json['isCorrect'] == true,
      position: json['position'] == null ? null : _asInt(json['position']),
    );
  }
}

class AdminQuizQuestion {
  AdminQuizQuestion({
    required this.id,
    required this.questionType,
    required this.prompt,
    required this.explanation,
    required this.points,
    required this.position,
    required this.answerMultiple,
    required this.options,
  });

  final String id;
  final String questionType;
  final String prompt;
  final String explanation;
  final int points;
  final int position;
  final bool answerMultiple;
  final List<AdminQuizOption> options;

  factory AdminQuizQuestion.fromJson(Map<String, dynamic> json) {
    return AdminQuizQuestion(
      id: (json['id'] ?? '').toString(),
      questionType: (json['questionType'] ?? 'single_choice').toString(),
      prompt: (json['prompt'] ?? '').toString(),
      explanation: (json['explanation'] ?? '').toString(),
      points: _asInt(json['points']),
      position: _asInt(json['position']),
      answerMultiple: json['answerMultiple'] == true,
      options: (json['options'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AdminQuizOption.fromJson)
          .toList(),
    );
  }
}

class AdminQuiz {
  AdminQuiz({
    required this.id,
    required this.title,
    required this.instructions,
    required this.passingScore,
    required this.timeLimitSeconds,
    required this.randomizeQuestions,
    required this.randomizeOptions,
    required this.createdAt,
    required this.questions,
  });

  final String id;
  final String title;
  final String instructions;
  final int passingScore;
  final int timeLimitSeconds;
  final bool randomizeQuestions;
  final bool randomizeOptions;
  final DateTime createdAt;
  final List<AdminQuizQuestion> questions;

  factory AdminQuiz.fromJson(Map<String, dynamic> json) {
    return AdminQuiz(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      instructions: (json['instructions'] ?? '').toString(),
      passingScore: _asInt(json['passingScore']),
      timeLimitSeconds: _asInt(json['timeLimitSeconds']),
      randomizeQuestions: json['randomizeQuestions'] == true,
      randomizeOptions: json['randomizeOptions'] == true,
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      questions: (json['questions'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AdminQuizQuestion.fromJson)
          .toList(),
    );
  }
}

class AdminFinalExamQuestionComponent {
  AdminFinalExamQuestionComponent({
    required this.id,
    required this.type,
    required this.questionType,
    required this.prompt,
    required this.explanation,
    required this.points,
    required this.position,
    required this.answerMultiple,
    required this.options,
  });

  final String id;
  final String type;
  final String questionType;
  final String prompt;
  final String explanation;
  final int points;
  final int position;
  final bool answerMultiple;
  final List<AdminQuizOption> options;

  factory AdminFinalExamQuestionComponent.fromJson(Map<String, dynamic> json) {
    return AdminFinalExamQuestionComponent(
      id: (json['id'] ?? '').toString(),
      type: (json['type'] ?? 'question').toString(),
      questionType: (json['questionType'] ?? 'single_choice').toString(),
      prompt: (json['prompt'] ?? '').toString(),
      explanation: (json['explanation'] ?? '').toString(),
      points: _asInt(json['points']),
      position: _asInt(json['position']),
      answerMultiple: json['answerMultiple'] == true,
      options: (json['options'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AdminQuizOption.fromJson)
          .toList(),
    );
  }
}

class AdminFinalExam {
  AdminFinalExam({
    required this.unitId,
    required this.title,
    required this.passingScore,
    required this.maxAttempts,
    required this.timeLimitSeconds,
    required this.createdAt,
    required this.components,
  });

  final String unitId;
  final String title;
  final int passingScore;
  final int maxAttempts;
  final int timeLimitSeconds;
  final DateTime createdAt;
  final List<AdminFinalExamQuestionComponent> components;

  factory AdminFinalExam.fromJson(Map<String, dynamic> json) {
    return AdminFinalExam(
      unitId: (json['unitId'] ?? json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      passingScore: _asInt(json['passingScore']),
      maxAttempts: _asInt(json['maxAttempts']),
      timeLimitSeconds: _asInt(json['timeLimitSeconds']),
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      components: (json['components'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AdminFinalExamQuestionComponent.fromJson)
          .toList(),
    );
  }
}

class AdminUnitDetail {
  AdminUnitDetail({
    required this.id,
    required this.courseId,
    required this.title,
    required this.summary,
    required this.type,
    required this.position,
    required this.estimatedMinutes,
    required this.isPublished,
    required this.createdAt,
    required this.updatedAt,
    required this.prerequisites,
    required this.requiredFor,
    this.moduleContent,
    required this.moduleResources,
    this.exercise,
    this.quiz,
    this.finalExam,
  });

  final String id;
  final String courseId;
  final String title;
  final String summary;
  final String type;
  final int position;
  final int estimatedMinutes;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<AdminPrerequisite> prerequisites;
  final List<AdminPrerequisite> requiredFor;
  final AdminModuleContent? moduleContent;
  final List<AdminModuleResource> moduleResources;
  final AdminExerciseDetail? exercise;
  final AdminQuiz? quiz;
  final AdminFinalExam? finalExam;

  factory AdminUnitDetail.fromJson(Map<String, dynamic> json) {
    List<AdminPrerequisite> parse(String key) {
      return (json[key] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AdminPrerequisite.fromJson)
          .toList();
    }

    final moduleContentMap = json['moduleContent'] is Map<String, dynamic>
        ? json['moduleContent'] as Map<String, dynamic>
        : null;
    final exerciseMap = json['exercise'] is Map<String, dynamic>
        ? json['exercise'] as Map<String, dynamic>
        : null;
    final quizMap = json['quiz'] is Map<String, dynamic>
        ? json['quiz'] as Map<String, dynamic>
        : null;
    final finalExamMap = json['finalExam'] is Map<String, dynamic>
        ? json['finalExam'] as Map<String, dynamic>
        : null;

    return AdminUnitDetail(
      id: (json['id'] ?? '').toString(),
      courseId: (json['courseId'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      summary: (json['summary'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      position: _asInt(json['position']),
      estimatedMinutes: _asInt(json['estimatedMinutes']),
      isPublished: json['isPublished'] == true,
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          DateTime.tryParse((json['updatedAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      prerequisites: parse('prerequisites'),
      requiredFor: parse('requiredFor'),
      moduleContent: moduleContentMap == null
          ? null
          : AdminModuleContent.fromJson(moduleContentMap),
      moduleResources: (json['moduleResources'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AdminModuleResource.fromJson)
          .toList(),
      exercise: exerciseMap == null
          ? null
          : AdminExerciseDetail.fromJson(exerciseMap),
      quiz: quizMap == null ? null : AdminQuiz.fromJson(quizMap),
      finalExam: finalExamMap == null
          ? null
          : AdminFinalExam.fromJson(finalExamMap),
    );
  }

  AdminUnitDetail copyWith({
    String? title,
    String? summary,
    String? type,
    int? position,
    int? estimatedMinutes,
    bool? isPublished,
    List<AdminPrerequisite>? prerequisites,
    List<AdminPrerequisite>? requiredFor,
    AdminModuleContent? moduleContent,
    bool clearModuleContent = false,
    List<AdminModuleResource>? moduleResources,
    AdminExerciseDetail? exercise,
    bool clearExercise = false,
    AdminQuiz? quiz,
    bool clearQuiz = false,
    AdminFinalExam? finalExam,
    bool clearFinalExam = false,
  }) {
    return AdminUnitDetail(
      id: id,
      courseId: courseId,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      type: type ?? this.type,
      position: position ?? this.position,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt,
      updatedAt: updatedAt,
      prerequisites: prerequisites ?? this.prerequisites,
      requiredFor: requiredFor ?? this.requiredFor,
      moduleContent: clearModuleContent
          ? null
          : (moduleContent ?? this.moduleContent),
      moduleResources: moduleResources ?? this.moduleResources,
      exercise: clearExercise ? null : (exercise ?? this.exercise),
      quiz: clearQuiz ? null : (quiz ?? this.quiz),
      finalExam: clearFinalExam ? null : (finalExam ?? this.finalExam),
    );
  }

  AdminUnitDetail applyPatch(Map<String, dynamic> json) {
    List<AdminPrerequisite>? parseOptional(String key) {
      if (!json.containsKey(key)) return null;
      return (json[key] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AdminPrerequisite.fromJson)
          .toList();
    }

    return copyWith(
      title: json.containsKey('title')
          ? (json['title'] ?? '').toString()
          : null,
      summary: json.containsKey('summary')
          ? (json['summary'] ?? '').toString()
          : null,
      type: json.containsKey('type') ? (json['type'] ?? '').toString() : null,
      position: json.containsKey('position') ? _asInt(json['position']) : null,
      estimatedMinutes: json.containsKey('estimatedMinutes')
          ? _asInt(json['estimatedMinutes'])
          : null,
      isPublished: json.containsKey('isPublished')
          ? json['isPublished'] == true
          : null,
      prerequisites: parseOptional('prerequisites'),
      requiredFor: parseOptional('requiredFor'),
      moduleContent: json['moduleContent'] is Map<String, dynamic>
          ? AdminModuleContent.fromJson(
              json['moduleContent'] as Map<String, dynamic>,
            )
          : null,
      clearModuleContent:
          json.containsKey('moduleContent') && json['moduleContent'] == null,
      moduleResources: json.containsKey('moduleResources')
          ? (json['moduleResources'] as List<dynamic>? ?? const [])
                .whereType<Map<String, dynamic>>()
                .map(AdminModuleResource.fromJson)
                .toList()
          : null,
      exercise: json['exercise'] is Map<String, dynamic>
          ? AdminExerciseDetail.fromJson(
              json['exercise'] as Map<String, dynamic>,
            )
          : null,
      clearExercise: json.containsKey('exercise') && json['exercise'] == null,
      quiz: json['quiz'] is Map<String, dynamic>
          ? AdminQuiz.fromJson(json['quiz'] as Map<String, dynamic>)
          : null,
      clearQuiz: json.containsKey('quiz') && json['quiz'] == null,
      finalExam: json['finalExam'] is Map<String, dynamic>
          ? AdminFinalExam.fromJson(json['finalExam'] as Map<String, dynamic>)
          : null,
      clearFinalExam:
          json.containsKey('finalExam') && json['finalExam'] == null,
    );
  }
}

typedef BadgeCriteriaType = String;

class BadgeCriteriaFieldOption {
  BadgeCriteriaFieldOption({required this.value, required this.label});

  final String value;
  final String label;

  factory BadgeCriteriaFieldOption.fromJson(Map<String, dynamic> json) {
    return BadgeCriteriaFieldOption(
      value: (json['value'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
    );
  }
}

class BadgeCriteriaFieldDefinition {
  BadgeCriteriaFieldDefinition({
    required this.key,
    required this.label,
    required this.type,
    required this.required,
    required this.options,
    this.min,
    this.step,
    this.helperText,
  });

  final String key;
  final String label;
  final String type;
  final bool required;
  final List<BadgeCriteriaFieldOption> options;
  final int? min;
  final int? step;
  final String? helperText;

  factory BadgeCriteriaFieldDefinition.fromJson(Map<String, dynamic> json) {
    final options = (json['options'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(BadgeCriteriaFieldOption.fromJson)
        .toList();

    return BadgeCriteriaFieldDefinition(
      key: (json['key'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      required: json['required'] == true,
      options: options,
      min: json['min'] == null ? null : _asInt(json['min']),
      step: json['step'] == null ? null : _asInt(json['step']),
      helperText: json['helperText']?.toString(),
    );
  }
}

class BadgeCriteriaMetadata {
  BadgeCriteriaMetadata({
    required this.type,
    required this.label,
    required this.description,
    required this.fields,
  });

  final BadgeCriteriaType type;
  final String label;
  final String description;
  final List<BadgeCriteriaFieldDefinition> fields;

  factory BadgeCriteriaMetadata.fromJson(Map<String, dynamic> json) {
    final fields = (json['fields'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(BadgeCriteriaFieldDefinition.fromJson)
        .toList();

    return BadgeCriteriaMetadata(
      type: (json['type'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      fields: fields,
    );
  }
}

class AdminBadgeCriteria {
  AdminBadgeCriteria({required this.type, this.language, this.xp});

  final BadgeCriteriaType type;
  final String? language;
  final int? xp;

  factory AdminBadgeCriteria.fromJson(Map<String, dynamic> json) {
    return AdminBadgeCriteria(
      type: (json['type'] ?? '').toString(),
      language: json['language']?.toString(),
      xp: json['xp'] == null ? null : _asInt(json['xp']),
    );
  }
}

class AdminBadge {
  AdminBadge({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.iconS3Key,
    required this.criteria,
  });

  final String id;
  final String code;
  final String name;
  final String description;
  final String? iconS3Key;
  final AdminBadgeCriteria criteria;

  factory AdminBadge.fromJson(Map<String, dynamic> json) {
    final criteriaMap = (json['criteria'] is Map<String, dynamic>)
        ? json['criteria'] as Map<String, dynamic>
        : const <String, dynamic>{};

    return AdminBadge(
      id: (json['id'] ?? '').toString(),
      code: (json['code'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      iconS3Key: json['iconS3Key']?.toString(),
      criteria: AdminBadgeCriteria.fromJson(criteriaMap),
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

List<double> _asDoubleList(dynamic value) {
  if (value is! List) return const [];
  return value
      .map((item) {
        if (item is num) return item.toDouble();
        return double.tryParse(item?.toString() ?? '');
      })
      .whereType<double>()
      .toList();
}
