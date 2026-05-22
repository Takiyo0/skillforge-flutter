import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skillforgeapp/models/shared/paginated_response.dart';
import 'package:skillforgeapp/providers/infrastructure_providers.dart';

typedef LearningPathsData = ({
  PaginatedResponse<Map<String, dynamic>> allPaths,
  dynamic userPath,
});

final learningPathsViewModelProvider =
    FutureProvider.autoDispose<LearningPathsData>((ref) async {
      final api = ref.read(skillForgeApiProvider);
      final userPath = await api.getUserLearningPath();
      final allPaths = await api.getLearningPaths();
      return (allPaths: allPaths, userPath: userPath);
    });

final learningPathViewModelProvider = FutureProvider.autoDispose((ref) {
  return ref.read(skillForgeApiProvider).getUserLearningPath();
});

final learningPathActionsProvider = Provider<LearningPathActions>((ref) {
  return LearningPathActions(ref);
});

class LearningPathActions {
  LearningPathActions(this._ref);

  final Ref _ref;

  Future<Map<String, dynamic>> join(String learningPathId) {
    return _ref.read(skillForgeApiProvider).joinLearningPath(learningPathId);
  }

  Future<Map<String, dynamic>> leave(String learningPathId) {
    return _ref.read(skillForgeApiProvider).leaveLearningPath(learningPathId);
  }
}
