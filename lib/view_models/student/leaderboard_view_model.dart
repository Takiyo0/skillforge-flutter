import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skillforgeapp/providers/infrastructure_providers.dart';

final leaderboardViewModelProvider = FutureProvider.autoDispose<List<dynamic>>((
  ref,
) {
  return ref.read(skillForgeApiProvider).getStreakLeaderboard(limit: 50);
});
