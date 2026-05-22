import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skillforgeapp/config/asset_urls.dart';
import 'package:skillforgeapp/ui/design_system.dart';
import 'package:skillforgeapp/view_models/student/certificates_view_model.dart';

class CertificatesPage extends ConsumerWidget {
  const CertificatesPage({super.key});

  String _date(dynamic iso) {
    final raw = (iso ?? '').toString();
    if (raw.isEmpty) return '-';
    final d = DateTime.tryParse(raw);
    if (d == null) return raw;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Color _seededColor(String seed) {
    final hash = seed.runes.fold<int>(0, (a, b) => (a * 31 + b) & 0x7fffffff);
    final hue = (hash % 360).toDouble();
    return HSVColor.fromAHSV(1, hue, 0.62, 0.86).toColor();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(certificatesViewModelProvider);

    return AppPage(
      title: 'Trophy Room',
      subtitle: 'Certificates and badges',
      child: state.when(
        loading: AppAsyncState.loading,
        error: (e, _) => AppAsyncState.error('Failed to load trophy room: $e'),
        data: (data) {
          final certificates =
              data['certificates'] ?? const <Map<String, dynamic>>[];
          final badges = data['badges'] ?? const <Map<String, dynamic>>[];

          return ListView(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.workspace_premium,
                          color: Colors.amber,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Trophy Room',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            Text(
                              '${certificates.length} certificates • ${badges.length} badges',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Text(
                'Your Certificates',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (certificates.isEmpty)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.emoji_events_outlined),
                    title: Text('No certificates yet'),
                    subtitle: Text(
                      'Complete courses to earn your first trophy.',
                    ),
                  ),
                )
              else
                ...certificates.map((c) {
                  final certId = (c['id'] ?? '').toString();
                  final snap = (c['completionSnapshot'] is Map)
                      ? (c['completionSnapshot'] as Map).cast<String, dynamic>()
                      : const <String, dynamic>{};
                  final courseName =
                      (snap['courseName'] ?? c['courseName'] ?? 'Certificate')
                          .toString();
                  final level = (snap['courseLevel'] ?? '').toString();
                  final issued = _date(snap['completedAt'] ?? c['issuedAt']);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      child: ListTile(
                        leading: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.military_tech,
                            color: Colors.amber,
                          ),
                        ),
                        title: Text(courseName),
                        subtitle: Text(
                          '${level.isEmpty ? 'level n/a' : level} • $issued\n${(c['certificateCode'] ?? '-').toString()}',
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                        ),
                        onTap: certId.isEmpty
                            ? null
                            : () => context.push('/certificates/$certId'),
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 16),
              Text(
                'Your Badges',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (badges.isEmpty)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.lock_outline),
                    title: Text('No badges yet'),
                    subtitle: Text(
                      'Earn badges by completing achievements and milestones.',
                    ),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: badges.map((b) {
                    final badgeId = (b['badgeId'] ?? '').toString();
                    final bg = _seededColor(
                      badgeId.isEmpty
                          ? (b['name'] ?? 'badge').toString()
                          : badgeId,
                    );
                    final iconUrl = AssetUrls.courseThumbnailUrl(
                      (b['iconS3Key'] ?? '').toString(),
                    );
                    return SizedBox(
                      width: MediaQuery.of(context).size.width / 2 - 16 - 8,
                      child: Card(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                bg.withValues(alpha: 0.22),
                                bg.withValues(alpha: 0.10),
                              ],
                            ),
                            border: Border.all(
                              color: bg.withValues(alpha: 0.35),
                            ),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: iconUrl == null
                                    ? Text(
                                        '🏅',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.headlineSmall,
                                      )
                                    : ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          iconUrl,
                                          width: 44,
                                          height: 44,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                (b['name'] ?? 'Badge').toString(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                (b['description'] ?? '').toString(),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _date(b['awardedAt']),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          );
        },
      ),
    );
  }
}
