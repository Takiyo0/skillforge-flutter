import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skillforgeapp/providers/infrastructure_providers.dart';

final studentDashboardViewModelProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
      final api = ref.read(skillForgeApiProvider);

      Future<dynamic> safe(Future<dynamic> future, dynamic fallback) async {
        try {
          return await future;
        } catch (_) {
          return fallback;
        }
      }

      final results = await Future.wait<dynamic>([
        safe(api.getProfile(), null),
        safe(api.getXpSummary(), <String, dynamic>{}),
        safe(api.getStreak(), <String, dynamic>{}),
        safe(api.getBadges(), <String, dynamic>{'badges': <dynamic>[]}),
        safe(api.listEnrolledCourses(), null),
      ]);

      return {
        'user': results[0],
        'xp': results[1],
        'streak': results[2],
        'badges': results[3],
        'courses': results[4]?.data ?? const <dynamic>[],
      };
    });
