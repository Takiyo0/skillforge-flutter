import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skillforgeapp/models/shared/paginated_response.dart';
import 'package:skillforgeapp/providers/infrastructure_providers.dart';

const browseCoursesPageSize = 12;

typedef BrowseCoursesQuery = ({String search, int page, int limit});

final browseCoursesViewModelProvider = FutureProvider.autoDispose
    .family<PaginatedResponse<Map<String, dynamic>>, BrowseCoursesQuery>((
      ref,
      query,
    ) {
      final search = query.search.trim();
      return ref
          .read(skillForgeApiProvider)
          .listCourses(
            search: search.isEmpty ? null : search,
            page: query.page,
            limit: query.limit,
          );
    });
