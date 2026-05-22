import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skillforgeapp/models/shared/paginated_response.dart';
import 'package:skillforgeapp/providers/infrastructure_providers.dart';

final browseCoursesViewModelProvider =
    FutureProvider.autoDispose<PaginatedResponse<Map<String, dynamic>>>((ref) {
      return ref.read(skillForgeApiProvider).listCourses();
    });
