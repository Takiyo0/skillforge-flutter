enum LeaderboardPeriod {
  weekly('weekly', 'Weekly'),
  allTime('all_time', 'All Time');

  const LeaderboardPeriod(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static LeaderboardPeriod fromApiValue(String value) {
    return LeaderboardPeriod.values.firstWhere(
      (period) => period.apiValue == value,
      orElse: () => LeaderboardPeriod.weekly,
    );
  }
}

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.displayName,
    required this.score,
    required this.xpPoints,
    required this.currentStreakDays,
    required this.longestStreakDays,
    required this.level,
    this.avatarS3Key,
  });

  final int rank;
  final String userId;
  final String displayName;
  final String? avatarS3Key;
  final int score;
  final int xpPoints;
  final int currentStreakDays;
  final int longestStreakDays;
  final int level;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    int number(String key) => (json[key] as num?)?.toInt() ?? 0;

    return LeaderboardEntry(
      rank: number('rank'),
      userId: (json['userId'] ?? '').toString(),
      displayName: (json['displayName'] ?? 'Unknown Player').toString(),
      avatarS3Key: json['avatarS3Key']?.toString(),
      score: number('score'),
      xpPoints: number('xpPoints'),
      currentStreakDays: number('currentStreakDays'),
      longestStreakDays: number('longestStreakDays'),
      level: number('level'),
    );
  }
}

class LeaderboardResponse {
  const LeaderboardResponse({
    required this.period,
    required this.generatedAt,
    required this.maxEntries,
    required this.limit,
    required this.total,
    required this.totalParticipants,
    required this.count,
    required this.leaderboard,
    this.weekStartUtc,
    this.weekEndUtc,
    this.resetInSeconds,
    this.lastId,
    this.nextLastId,
    this.hasMore = false,
    this.myRank,
  });

  final LeaderboardPeriod period;
  final DateTime? generatedAt;
  final DateTime? weekStartUtc;
  final DateTime? weekEndUtc;
  final int? resetInSeconds;
  final int maxEntries;
  final int limit;
  final String? lastId;
  final String? nextLastId;
  final bool hasMore;
  final int total;
  final int totalParticipants;
  final int count;
  final List<LeaderboardEntry> leaderboard;
  final LeaderboardEntry? myRank;

  factory LeaderboardResponse.fromJson(Map<String, dynamic> json) {
    int number(String key) => (json[key] as num?)?.toInt() ?? 0;
    DateTime? date(String key) =>
        DateTime.tryParse((json[key] ?? '').toString());

    final rows = (json['leaderboard'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(LeaderboardEntry.fromJson)
        .toList();
    final myRankJson = json['myRank'];

    return LeaderboardResponse(
      period: LeaderboardPeriod.fromApiValue((json['period'] ?? '').toString()),
      generatedAt: date('generatedAt'),
      weekStartUtc: date('weekStartUtc'),
      weekEndUtc: date('weekEndUtc'),
      resetInSeconds: json['resetInSeconds'] == null
          ? null
          : number('resetInSeconds'),
      maxEntries: number('maxEntries'),
      limit: number('limit'),
      lastId: json['lastId']?.toString(),
      nextLastId: json['nextLastId']?.toString(),
      hasMore: json['hasMore'] == true,
      total: number('total'),
      totalParticipants: number('totalParticipants'),
      count: number('count'),
      leaderboard: rows,
      myRank: myRankJson is Map<String, dynamic>
          ? LeaderboardEntry.fromJson(myRankJson)
          : null,
    );
  }
}
