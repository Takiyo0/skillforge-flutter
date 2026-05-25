import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skillforgeapp/models/student/leaderboard_models.dart';
import 'package:skillforgeapp/providers/infrastructure_providers.dart';

final leaderboardPeriodProvider = StateProvider.autoDispose<LeaderboardPeriod>(
      (_) => LeaderboardPeriod.weekly,
);

final leaderboardViewModelProvider =
FutureProvider.autoDispose.family<LeaderboardResponse, LeaderboardPeriod>((ref,
    period,) {
  return ref
      .read(skillForgeRepositoryProvider)
      .getGlobalLeaderboard(period: period, limit: 100);
});
