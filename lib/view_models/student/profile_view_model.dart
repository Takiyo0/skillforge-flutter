import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skillforgeapp/providers/app_state.dart';
import 'package:skillforgeapp/providers/infrastructure_providers.dart';

final profileViewModelProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, userId) async {
      final api = ref.read(skillForgeApiProvider);
      var targetUserId = userId;
      if (targetUserId == 'me') {
        final currentUser = ref.read(sessionProvider).user;
        if (currentUser == null) {
          throw Exception('Please log in to view your profile');
        }
        targetUserId = currentUser.id;
      }
      return api.getUserProfile(targetUserId);
    });
