import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import '../services/storage/token_storage.dart';
import '../repositories/shared/skillforge_repository.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(() => ref.read(tokenStorageProvider).getToken()),
);

final skillForgeRepositoryProvider = Provider<SkillForgeRepository>(
  (ref) => SkillForgeRepository(ref.read(apiClientProvider)),
);

// Compatibility alias for existing views.
final skillForgeApiProvider = skillForgeRepositoryProvider;
