import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:skillforgeapp/config/asset_urls.dart';
import 'package:skillforgeapp/models/student/leaderboard_models.dart';
import 'package:skillforgeapp/providers/app_state.dart';
import 'package:skillforgeapp/ui/design_system.dart';
import 'package:skillforgeapp/view_models/student/leaderboard_view_model.dart';

class LeaderboardPage extends ConsumerWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(leaderboardPeriodProvider);
    final state = ref.watch(leaderboardViewModelProvider(period));
    final me = ref.watch(sessionProvider).user;

    return AppPage(
      title: 'Leaderboard',
      subtitle: period == LeaderboardPeriod.weekly
          ? 'This week\'s climb'
          : 'All-time legends',
      child: state.when(
        loading: AppAsyncState.loading,
        error: (error, _) =>
            AppAsyncState.error('Failed to load leaderboard: $error'),
        data: (data) =>
            RefreshIndicator(
              onRefresh: () =>
                  ref.refresh(
                    leaderboardViewModelProvider(period).future,
                  ),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _LeaderboardHero(
                    data: data,
                    period: period,
                    onPeriodChanged: (next) {
                      ref
                          .read(leaderboardPeriodProvider.notifier)
                          .state = next;
                    },
                  ),
                  const SizedBox(height: 14),
                  _YourRankPanel(entry: data.myRank, currentUserId: me?.id),
                  const SizedBox(height: 14),
                  if (data.leaderboard.isEmpty)
                    _EmptyLeaderboard(period: period)
                  else
                    _Rankings(
                      entries: data.leaderboard,
                      currentUserId: me?.id,
                    ),
                ],
              ),
            ),
      ),
    );
  }
}

class _LeaderboardHero extends StatelessWidget {
  const _LeaderboardHero({
    required this.data,
    required this.period,
    required this.onPeriodChanged,
  });

  final LeaderboardResponse data;
  final LeaderboardPeriod period;
  final ValueChanged<LeaderboardPeriod> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    final isWeekly = period == LeaderboardPeriod.weekly;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF2563EB), Color(0xFF14B8A6)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x332563EB),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SKILLFORGE ARENA',
                      style: TextStyle(
                        color: Color(0xFFCCFBF1),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isWeekly ? 'Weekly Sprint' : 'Hall of Mastery',
                      style: Theme
                          .of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isWeekly
                          ? 'Scores reset every week. Push your rank before the board closes.'
                          : 'Every earned point counts toward the permanent ranking.',
                      style: const TextStyle(
                        color: Color(0xFFE0F2FE),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                isWeekly ? Icons.bolt_rounded : Icons.workspace_premium,
                color: const Color(0xFFFBBF24),
                size: 42,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SegmentedButton<LeaderboardPeriod>(
            style: ButtonStyle(
              foregroundColor: const WidgetStatePropertyAll(Colors.white),
              side: WidgetStatePropertyAll(
                BorderSide(color: Colors.white.withValues(alpha: 0.20)),
              ),
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white.withValues(alpha: 0.18);
                }
                return Colors.black.withValues(alpha: 0.12);
              }),
            ),
            segments: const [
              ButtonSegment(
                value: LeaderboardPeriod.weekly,
                icon: Icon(Icons.flash_on_rounded),
                label: Text('Weekly'),
              ),
              ButtonSegment(
                value: LeaderboardPeriod.allTime,
                icon: Icon(Icons.military_tech_rounded),
                label: Text('All Time'),
              ),
            ],
            selected: {period},
            onSelectionChanged: (value) => onPeriodChanged(value.first),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth > 680 ? 4 : 2;
              final stats = [
                _HeroMetric(
                  icon: Icons.groups_rounded,
                  label: 'Participants',
                  value: _compactNumber(data.totalParticipants),
                ),
                _HeroMetric(
                  icon: Icons.format_list_numbered_rounded,
                  label: 'Entries',
                  value: '${data.count}/${data.maxEntries}',
                ),
                _HeroMetric(
                  icon: Icons.leaderboard_rounded,
                  label: 'Total Ranked',
                  value: _compactNumber(data.total),
                ),
                _HeroMetric(
                  icon: isWeekly
                      ? Icons.hourglass_bottom_rounded
                      : Icons.all_inclusive_rounded,
                  label: isWeekly ? 'Reset In' : 'Season',
                  value: isWeekly ? null : 'Lifetime',
                  countdownSeconds: isWeekly ? data.resetInSeconds : null,
                ),
              ];
              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: columns == 4 ? 1.75 : 2.1,
                children: stats,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.icon,
    required this.label,
    this.value,
    this.countdownSeconds,
  });

  final IconData icon;
  final String label;
  final String? value;
  final int? countdownSeconds;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFBBF24), size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFDFF6FF),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 3),
                countdownSeconds == null
                    ? Text(
                  value ?? '-',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                )
                    : _CountdownText(seconds: countdownSeconds!),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CountdownText extends StatefulWidget {
  const _CountdownText({required this.seconds});

  final int seconds;

  @override
  State<_CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<_CountdownText> {
  late int _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.seconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _remaining <= 0) return;
      setState(() => _remaining -= 1);
    });
  }

  @override
  void didUpdateWidget(covariant _CountdownText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seconds != widget.seconds) {
      _remaining = widget.seconds;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _formatDuration(_remaining),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _YourRankPanel extends StatelessWidget {
  const _YourRankPanel({required this.entry, required this.currentUserId});

  final LeaderboardEntry? entry;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    if (entry == null) {
      return GlassPanel(
        radius: 12,
        child: Row(
          children: [
            const Icon(Icons.flag_circle_rounded, color: Color(0xFFF59E0B)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You are not ranked yet',
                    style: Theme
                        .of(context)
                        .textTheme
                        .titleMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Earn score this period to enter the arena.',
                    style: Theme
                        .of(context)
                        .textTheme
                        .bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return GlassPanel(
      radius: 12,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          _RankBadge(rank: entry!.rank, size: 48),
          const SizedBox(width: 12),
          _LeaderboardAvatar(entry: entry!, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isCurrentUser(entry!, currentUserId)
                      ? 'Your current rank'
                      : entry!.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme
                      .of(context)
                      .textTheme
                      .titleMedium,
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatChip(
                      icon: Icons.stars_rounded,
                      text: '${entry!.score} score',
                    ),
                    _StatChip(
                      icon: Icons.auto_awesome_rounded,
                      text: '${entry!.xpPoints} XP',
                    ),
                    _StatChip(
                      icon: Icons.trending_up_rounded,
                      text: 'Lv ${entry!.level}',
                    ),
                    _StatChip(
                      icon: Icons.local_fire_department_rounded,
                      text: '${entry!.currentStreakDays}d streak',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Rankings extends StatelessWidget {
  const _Rankings({required this.entries, required this.currentUserId});

  final List<LeaderboardEntry> entries;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Rankings', style: Theme
            .of(context)
            .textTheme
            .titleLarge),
        const SizedBox(height: 10),
        ...entries.map(
              (entry) =>
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _LeaderboardRow(
                  entry: entry,
                  currentUserId: currentUserId,
                ),
              ),
        ),
      ],
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({required this.entry, required this.currentUserId});

  final LeaderboardEntry entry;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    final isMe = _isCurrentUser(entry, currentUserId);
    final accent = _rankColor(entry.rank);
    return Card(
      color: isMe
          ? Theme
          .of(
        context,
      )
          .colorScheme
          .primaryContainer
          .withValues(alpha: 0.50)
          : accent.withValues(alpha: entry.rank <= 3 ? 0.08 : 0.03),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: accent.withValues(
              alpha: entry.rank <= 3 || isMe ? 0.45 : 0.16),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _RankBadge(rank: entry.rank, size: 42),
            const SizedBox(width: 10),
            _LeaderboardAvatar(entry: entry, size: 46),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme
                              .of(context)
                              .textTheme
                              .titleMedium,
                        ),
                      ),
                      if (isMe) const _YouBadge(),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _StatChip(
                        icon: Icons.stars_rounded,
                        text: '${entry.score} score',
                      ),
                      _StatChip(
                        icon: Icons.trending_up_rounded,
                        text: 'Lv ${entry.level}',
                      ),
                      _StatChip(
                        icon: Icons.local_fire_department_rounded,
                        text: '${entry.longestStreakDays}d best',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyLeaderboard extends StatelessWidget {
  const _EmptyLeaderboard({required this.period});

  final LeaderboardPeriod period;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      radius: 12,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(
            Icons.emoji_events_outlined,
            size: 54,
            color: Color(0xFFF59E0B),
          ),
          const SizedBox(height: 12),
          Text(
            'No ranks posted yet',
            style: Theme
                .of(context)
                .textTheme
                .titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            period == LeaderboardPeriod.weekly
                ? 'Be the first to put points on this week\'s board.'
                : 'The all-time board is waiting for its first champion.',
            textAlign: TextAlign.center,
            style: Theme
                .of(context)
                .textTheme
                .bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _LeaderboardAvatar extends StatelessWidget {
  const _LeaderboardAvatar({required this.entry, required this.size});

  final LeaderboardEntry entry;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url =
        AssetUrls.avatarUrl(entry.avatarS3Key) ??
            AssetUrls.dicebearAvatarUrl(entry.userId);
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme
              .of(context)
              .colorScheme
              .primary
              .withValues(alpha: 0.45),
        ),
      ),
      child: ClipOval(
        child: AssetUrls.isSvgUrl(url)
            ? SvgPicture.network(url, fit: BoxFit.cover)
            : Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _InitialAvatar(entry: entry),
        ),
      ),
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.entry});

  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final initial = entry.displayName
        .trim()
        .isEmpty
        ? '?'
        : entry.displayName
        .trim()
        .characters
        .first
        .toUpperCase();
    return Container(
      color: Theme
          .of(context)
          .colorScheme
          .primary
          .withValues(alpha: 0.18),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: Theme
            .of(context)
            .textTheme
            .titleMedium
            ?.copyWith(
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank, required this.size});

  final int rank;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = _rankColor(rank);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.18),
        border: Border.all(color: color.withValues(alpha: 0.72)),
      ),
      child: Text(
        '#$rank',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: size < 44 ? 13 : 15,
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Theme
            .of(context)
            .colorScheme
            .primary
            .withValues(alpha: 0.10),
        border: Border.all(
          color: Theme
              .of(context)
              .colorScheme
              .primary
              .withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: Theme
                .of(
              context,
            )
                .textTheme
                .bodySmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _YouBadge extends StatelessWidget {
  const _YouBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Theme
            .of(context)
            .colorScheme
            .primary
            .withValues(alpha: 0.18),
      ),
      child: Text(
        'You',
        style: Theme
            .of(
          context,
        )
            .textTheme
            .bodySmall
            ?.copyWith(fontWeight: FontWeight.w900),
      ),
    );
  }
}

bool _isCurrentUser(LeaderboardEntry entry, String? currentUserId) {
  return currentUserId != null && currentUserId == entry.userId;
}

Color _rankColor(int rank) {
  return switch (rank) {
    1 => const Color(0xFFFBBF24),
    2 => const Color(0xFFCBD5E1),
    3 => const Color(0xFFFB923C),
    _ => const Color(0xFF38BDF8),
  };
}

String _compactNumber(int value) {
  if (value >= 1000000) {
    final next = value / 1000000;
    return '${next.toStringAsFixed(next >= 10 ? 0 : 1)}M';
  }
  if (value >= 1000) {
    final next = value / 1000;
    return '${next.toStringAsFixed(next >= 10 ? 0 : 1)}K';
  }
  return '$value';
}

String _formatDuration(int totalSeconds) {
  final safe = totalSeconds < 0 ? 0 : totalSeconds;
  final duration = Duration(seconds: safe);
  final days = duration.inDays;
  final hours = duration.inHours.remainder(24);
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);
  if (days > 0) return '${days}d ${hours}h';
  if (hours > 0) return '${hours}h ${minutes}m';
  if (minutes > 0) return '${minutes}m ${seconds}s';
  return '${seconds}s';
}
