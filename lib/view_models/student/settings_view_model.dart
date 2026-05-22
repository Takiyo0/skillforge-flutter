import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skillforgeapp/providers/app_state.dart';
import 'package:skillforgeapp/providers/infrastructure_providers.dart';
import 'package:skillforgeapp/ui/design_system.dart';

class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel(this._ref);

  final Ref _ref;
  bool _disposed = false;

  bool busy = false;
  String message = '';

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> saveProfile({
    required String displayName,
    required String email,
    required String bio,
  }) async {
    busy = true;
    message = '';
    _safeNotify();
    try {
      final updatedPatch = await _ref
          .read(skillForgeApiProvider)
          .updateProfilePatch(displayName: displayName, email: email, bio: bio);
      _ref.read(sessionProvider.notifier).mergeUserPatch(updatedPatch);
      await _ref.read(sessionProvider.notifier).refreshProfile();
      message = 'Updated profile successfully.';
    } catch (e) {
      message = AppToast.errorMessage(e);
    } finally {
      busy = false;
      _safeNotify();
    }
  }

  Future<void> savePreferences({
    required bool? darkModeEnabled,
    required String preferredLocale,
  }) async {
    busy = true;
    message = '';
    _safeNotify();
    try {
      await _ref
          .read(skillForgeApiProvider)
          .updatePreferences(
            darkModeEnabled: darkModeEnabled,
            preferredLocale: preferredLocale,
          );
      await _ref.read(sessionProvider.notifier).refreshProfile();
      message = 'Updated preferences successfully.';
    } catch (e) {
      message = AppToast.errorMessage(e);
    } finally {
      busy = false;
      _safeNotify();
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    busy = true;
    message = '';
    _safeNotify();
    try {
      await _ref
          .read(skillForgeApiProvider)
          .changePassword(
            currentPassword: currentPassword,
            newPassword: newPassword,
          );
      message = 'Password changed successfully.';
    } catch (e) {
      message = AppToast.errorMessage(e);
    } finally {
      busy = false;
      _safeNotify();
    }
  }

  Future<void> logout() async {
    await _ref.read(sessionProvider.notifier).logout();
  }
}

final settingsViewModelProvider =
    ChangeNotifierProvider.autoDispose<SettingsViewModel>(
      (ref) => SettingsViewModel(ref),
    );
