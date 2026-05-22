import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/shared/api_error.dart';
import '../models/auth/auth_models.dart';
import '../providers/infrastructure_providers.dart';
import '../services/auth/auth_service.dart';

class AppState {
  const AppState({
    this.user,
    this.isLoading = false,
    this.isBootstrapping = false,
    this.isAuthenticated = false,
    this.error,
  });

  final User? user;
  final bool isLoading;
  final bool isBootstrapping;
  final bool isAuthenticated;
  final String? error;

  AppState copyWith({
    User? user,
    bool? isLoading,
    bool? isBootstrapping,
    bool? isAuthenticated,
    String? error,
  }) {
    return AppState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isBootstrapping: isBootstrapping ?? this.isBootstrapping,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      error: error,
    );
  }
}

class AppStateController extends StateNotifier<AppState> {
  AppStateController(this._ref)
    : super(const AppState(isLoading: false, isBootstrapping: true));

  final Ref _ref;

  String _readableError(Object e) {
    if (e is ApiError) return e.message;
    return e.toString();
  }

  Future<void> bootstrap() async {
    state = state.copyWith(isBootstrapping: true, error: null);
    try {
      final user = await _ref.read(authServiceProvider).bootstrapSession();
      state = AppState(
        user: user,
        isLoading: false,
        isBootstrapping: false,
        isAuthenticated: true,
      );
    } catch (_) {
      await _ref.read(tokenStorageProvider).clearToken();
      state = const AppState(
        isLoading: false,
        isBootstrapping: false,
        isAuthenticated: false,
      );
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final user = await _ref.read(authServiceProvider).login(email, password);
      state = AppState(
        user: user,
        isLoading: false,
        isBootstrapping: false,
        isAuthenticated: true,
      );
      return true;
    } catch (e) {
      state = AppState(
        isLoading: false,
        isBootstrapping: false,
        isAuthenticated: false,
        error: _readableError(e),
      );
      return false;
    }
  }

  Future<bool> register(
    String displayName,
    String email,
    String password,
  ) async {
    try {
      final user = await _ref
          .read(authServiceProvider)
          .register(displayName, email, password);
      state = AppState(
        user: user,
        isLoading: false,
        isBootstrapping: false,
        isAuthenticated: true,
      );
      return true;
    } catch (e) {
      state = AppState(
        isLoading: false,
        isBootstrapping: false,
        isAuthenticated: false,
        error: _readableError(e),
      );
      return false;
    }
  }

  Future<void> refreshProfile() async {
    if (!state.isAuthenticated) return;
    final user = await _ref.read(skillForgeRepositoryProvider).getProfile();
    state = state.copyWith(user: user);
  }

  void setUser(User user) {
    state = state.copyWith(user: user);
  }

  void mergeUserPatch(Map<String, dynamic> patch) {
    final current = state.user;
    if (current == null) return;
    state = state.copyWith(
      user: current.copyWith(
        displayName: patch['displayName']?.toString(),
        email: patch['email']?.toString(),
        bio: patch['bio']?.toString(),
        avatarS3Key: patch['avatarS3Key']?.toString(),
      ),
    );
  }

  Future<void> logout() async {
    await _ref.read(authServiceProvider).logout();
    state = const AppState(
      isAuthenticated: false,
      isLoading: false,
      isBootstrapping: false,
    );
  }
}

final appStateProvider = StateNotifierProvider<AppStateController, AppState>(
  (ref) => AppStateController(ref),
);

// Compatibility aliases for older feature code while migrating to the new structure.
typedef SessionState = AppState;
typedef SessionController = AppStateController;

final sessionProvider = appStateProvider;
