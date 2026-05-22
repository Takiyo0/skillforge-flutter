import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:skillforgeapp/providers/app_state.dart';
import 'package:skillforgeapp/config/app_config.dart';
import 'package:skillforgeapp/ui/design_system.dart';
import 'package:skillforgeapp/view_models/shared/certificate_view_model.dart';
import 'package:url_launcher/url_launcher.dart';

class CertificatePage extends ConsumerStatefulWidget {
  const CertificatePage({super.key, required this.certificateId});

  final String certificateId;

  @override
  ConsumerState<CertificatePage> createState() => _CertificatePageState();
}

class _CertificatePageState extends ConsumerState<CertificatePage> {
  bool _downloading = false;

  String _formatDate(dynamic iso) {
    final raw = (iso ?? '').toString();
    if (raw.isEmpty) return '-';
    final d = DateTime.tryParse(raw);
    if (d == null) return raw;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _openUrl(String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      certificateBundleViewModelProvider(widget.certificateId),
    );
    final currentUserId = ref.watch(sessionProvider).user?.id ?? '';

    return AppPage(
      title: 'Certificate',
      subtitle: widget.certificateId,
      child: state.when(
        loading: AppAsyncState.loading,
        error: (e, _) => AppAsyncState.error('Failed certificate: $e'),
        data: (value) {
          final certificate =
              (value['certificate'] as Map<String, dynamic>?) ?? const {};
          final download =
              (value['download'] as Map<String, dynamic>?) ?? const {};

          final completion = (certificate['completionSnapshot'] is Map)
              ? (certificate['completionSnapshot'] as Map)
                    .cast<String, dynamic>()
              : const <String, dynamic>{};
          final user = (certificate['user'] is Map)
              ? (certificate['user'] as Map).cast<String, dynamic>()
              : const <String, dynamic>{};
          final course = (certificate['course'] is Map)
              ? (certificate['course'] as Map).cast<String, dynamic>()
              : const <String, dynamic>{};

          final courseName =
              (completion['courseName'] ?? course['title'] ?? '-').toString();
          final learner = (completion['userName'] ?? user['displayName'] ?? '-')
              .toString();
          final level = (completion['courseLevel'] ?? course['level'] ?? '-')
              .toString();
          final code = (certificate['certificateCode'] ?? '-').toString();
          final verificationCode = (certificate['verificationCode'] ?? '-')
              .toString();
          final issuedAt = _formatDate(certificate['issuedAt']);
          final completedAt = _formatDate(completion['completedAt']);
          final isRevoked = certificate['isRevoked'] == true;
          final downloadUrl = (download['downloadUrl'] ?? '').toString();
          final userId = (user['id'] ?? '').toString();
          final canDownload = userId.isNotEmpty && userId == currentUserId;

          final qrPayload =
              "${AppConfig.baseUrl}/student/certificates/verification?payload=${base64.encode(utf8.encode('{"userId":"$userId","verificationCode":"$verificationCode"}'))}";

          return ListView(
            padding: .all(
              0,
            ).add(.only(bottom: AppChromeMetrics.bottomContentInset(context))),
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.24),
                      const Color(0xFF1453A3).withValues(alpha: 0.72),
                    ],
                  ),
                  border: Border.all(
                    color: const Color(0xFF355585).withValues(alpha: 0.36),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x261E3A8A),
                      blurRadius: 36,
                      offset: Offset(0, 16),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -70,
                      left: -40,
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFF60A5FA).withValues(alpha: 0.25),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -80,
                      right: -50,
                      child: Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFF1D4950).withValues(alpha: 0.22),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.workspace_premium,
                            size: 56,
                            color: Color(0xFF5AC6DF),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Certificate of Completion',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 120,
                            height: 4,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2563EB), Color(0xFF287F8C)],
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'This certifies that',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            learner,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: const Color(0xFF5AC6DF),
                                  fontWeight: FontWeight.w900,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'has successfully completed the course',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            courseName,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              Chip(label: Text(level.toUpperCase())),
                              Chip(label: Text('Issued $issuedAt')),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isRevoked
                                  ? Colors.red.withValues(alpha: 0.12)
                                  : Colors.green.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isRevoked
                                    ? Colors.red.withValues(alpha: 0.32)
                                    : Colors.green.withValues(alpha: 0.32),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isRevoked
                                      ? Icons.error_outline
                                      : Icons.check_circle,
                                  color: isRevoked ? Colors.red : Colors.green,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    isRevoked
                                        ? 'Certificate revoked'
                                        : 'Certificate valid',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final stacked = constraints.maxWidth < 860;
                  final details = Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Learner Information',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Name: ${(user['displayName'] ?? learner).toString()}',
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Icon(
                                Icons.menu_book_outlined,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Course Details',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Title: ${(course['title'] ?? courseName).toString()}',
                          ),
                          Text(
                            'Level: ${(course['level'] ?? level).toString()}',
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Certificate Code',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          SelectableText(code),
                          const SizedBox(height: 8),
                          Text(
                            'Verification Code',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          SelectableText(verificationCode),
                        ],
                      ),
                    ),
                  );

                  final qr = Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          const Text(
                            'Verification QR Code',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: QrImageView(
                              data: qrPayload,
                              size: 170,
                              backgroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Scan to verify certificate',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  );

                  if (stacked) {
                    return Column(
                      children: [details, const SizedBox(height: 10), qr],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: details),
                      const SizedBox(width: 10),
                      SizedBox(width: 260, child: qr),
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  if (canDownload) ...[
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: (_downloading || downloadUrl.isEmpty)
                            ? null
                            : () async {
                                setState(() => _downloading = true);
                                try {
                                  await _openUrl(downloadUrl);
                                } finally {
                                  if (mounted)
                                    setState(() => _downloading = false);
                                }
                              },
                        icon: const Icon(Icons.download_rounded),
                        label: Text(
                          _downloading ? 'Downloading...' : 'Download PDF',
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: () async {
                        final link =
                            'https://skillforge.takiyo.us/certificates/${widget.certificateId}';
                        final text =
                            'I completed "$courseName" and earned a certificate. Code: $code\n$link';
                        await Share.share(
                          text,
                          subject: 'Certificate Achievement',
                        );
                      },
                      icon: const Icon(Icons.share_rounded),
                      label: const Text('Share'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.arrow_back_ios),
                label: const Text('Back'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
