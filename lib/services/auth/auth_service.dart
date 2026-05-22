import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/auth/auth_models.dart';
import '../../providers/infrastructure_providers.dart';

class AuthService {
  AuthService(this._ref);

  final Ref _ref;

  Future<User> bootstrapSession() async {
    final token = await _ref.read(tokenStorageProvider).getToken();
    if (token == null || token.isEmpty) {
      throw StateError('No active session');
    }
    return _ref.read(skillForgeRepositoryProvider).getProfile();
  }

  Future<User> login(String email, String password) async {
    final result = await _ref
        .read(skillForgeRepositoryProvider)
        .login(email: email, password: password);
    await _ref.read(tokenStorageProvider).saveToken(result.accessToken);
    return _ref.read(skillForgeRepositoryProvider).getProfile();
  }

  Future<User> register(
    String displayName,
    String email,
    String password,
  ) async {
    final result = await _ref
        .read(skillForgeRepositoryProvider)
        .register(displayName: displayName, email: email, password: password);
    await _ref.read(tokenStorageProvider).saveToken(result.accessToken);
    return result.user;
  }

  Future<void> logout() => _ref.read(tokenStorageProvider).clearToken();
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService(ref));
