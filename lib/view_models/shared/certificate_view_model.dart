import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skillforgeapp/providers/app_state.dart';
import 'package:skillforgeapp/providers/infrastructure_providers.dart';

final certificateBundleViewModelProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, certificateId) async {
      final api = ref.read(skillForgeApiProvider);
      final currentUserId = ref.read(sessionProvider).user?.id ?? '';
      final cert = await api.getCertificate(certificateId);
      final ownerId = (cert['user'] is Map)
          ? ((cert['user'] as Map)['id'] ?? '').toString()
          : (cert['userId'] ?? '').toString();
      final isOwner = currentUserId.isNotEmpty && ownerId == currentUserId;
      final download = isOwner
          ? await api.getCertificateDownloadUrl(certificateId)
          : const <String, dynamic>{};
      return {'certificate': cert, 'download': download};
    });

final certificateVerificationViewModelProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, code) {
      return ref.read(skillForgeApiProvider).verifyCertificate(code);
    });
