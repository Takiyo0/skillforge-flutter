import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skillforgeapp/providers/app_state.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._ref);

  final Ref _ref;
  bool _disposed = false;
  bool isLoading = false;
  String? error;

  void clearError() {
    if (error == null) return;
    error = null;
    _safeNotify();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      error = 'Email and password are required';
      _safeNotify();
      return false;
    }

    isLoading = true;
    error = null;
    _safeNotify();

    try {
      final ok = await _ref
          .read(appStateProvider.notifier)
          .login(email, password);
      if (!ok) {
        error = _ref.read(appStateProvider).error ?? 'Sign in failed';
      }
      return ok;
    } catch (_) {
      error = 'Sign in failed';
      return false;
    } finally {
      isLoading = false;
      _safeNotify();
    }
  }

  Future<bool> register(
    String displayName,
    String email,
    String password,
  ) async {
    if (displayName.isEmpty || email.isEmpty || password.isEmpty) {
      error = 'Display name, email, and password are required';
      _safeNotify();
      return false;
    }

    isLoading = true;
    error = null;
    _safeNotify();

    try {
      final ok = await _ref
          .read(appStateProvider.notifier)
          .register(displayName, email, password);
      if (!ok) {
        error = _ref.read(appStateProvider).error ?? 'Registration failed';
      }
      return ok;
    } catch (_) {
      error = 'Registration failed';
      return false;
    } finally {
      isLoading = false;
      _safeNotify();
    }
  }
}

final authViewModelProvider = ChangeNotifierProvider.autoDispose<AuthViewModel>(
  (ref) => AuthViewModel(ref),
);
