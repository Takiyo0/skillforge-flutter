import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skillforgeapp/providers/infrastructure_providers.dart';

final certificatesViewModelProvider =
    FutureProvider.autoDispose<Map<String, List<Map<String, dynamic>>>>((
      ref,
    ) async {
      final api = ref.read(skillForgeApiProvider);
      final certs = await api.getCertificates();
      final badgesRaw = await api.getBadges();

      final certificates = certs.data
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
      final badges = ((badgesRaw['badges'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();

      return {'certificates': certificates, 'badges': badges};
    });
