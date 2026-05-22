import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skillforgeapp/providers/infrastructure_providers.dart';

final forumPageViewModelProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final forums = await ref.read(skillForgeApiProvider).getUserForums();
      return forums.data;
    });
