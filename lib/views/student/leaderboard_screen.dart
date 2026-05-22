import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skillforgeapp/providers/app_state.dart';
import 'package:skillforgeapp/ui/design_system.dart';
import 'package:skillforgeapp/view_models/student/leaderboard_view_model.dart';

class LeaderboardPage extends ConsumerWidget {
  const LeaderboardPage({super.key});

  String? _medal(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(leaderboardViewModelProvider);
    final me = ref.watch(sessionProvider).user;

    return AppPage(
      title: 'Streak Leaderboard',
      subtitle: 'Who is hottest right now?',
      child: state.when(
        data: (rows) {
          if (rows.isEmpty)
            return const Center(
              child: Text('No leaderboard data available yet.'),
            );

          return ListView.separated(
            itemCount: rows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final rank = index + 1;
              final row =
                  (rows[index] as Map?)?.cast<String, dynamic>() ?? const {};
              final userId = (row['userId'] ?? '').toString();
              final displayName = (row['displayName'] ?? 'Unknown').toString();
              final currentStreak =
                  (row['currentStreakDays'] as num?)?.toInt() ?? 0;
              final longestStreak =
                  (row['longestStreakDays'] as num?)?.toInt() ?? 0;
              final isMe = me?.id == userId;

              return Card(
                color: isMe
                    ? Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withValues(alpha: 0.55)
                    : null,
                child: ListTile(
                  leading: _medal(rank) != null
                      ? Text(
                          _medal(rank)!,
                          style: const TextStyle(fontSize: 20),
                        )
                      : CircleAvatar(child: Text('#$rank')),
                  title: Row(
                    children: [
                      Expanded(child: Text(displayName)),
                      if (isMe) const Chip(label: Text('You')),
                    ],
                  ),
                  subtitle: Text(
                    'Current: $currentStreak days | Longest: $longestStreak days',
                  ),
                ),
              );
            },
          );
        },
        loading: AppAsyncState.loading,
        error: (error, _) =>
            AppAsyncState.error('Failed to load leaderboard: $error'),
      ),
    );
  }
}
