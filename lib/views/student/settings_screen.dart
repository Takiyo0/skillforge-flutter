import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skillforgeapp/providers/app_state.dart';
import 'package:skillforgeapp/ui/design_system.dart';
import 'package:skillforgeapp/view_models/student/settings_view_model.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool? _dark;
  int _tab = 0;
  final _displayName = TextEditingController();
  final _email = TextEditingController();
  final _bio = TextEditingController();
  final _locale = TextEditingController(text: 'en-US');
  final _current = TextEditingController();
  final _next = TextEditingController();
  String _message = '';

  @override
  Widget build(BuildContext context) {
    final settingsViewModel = ref.watch(settingsViewModelProvider);
    final user = ref.watch(sessionProvider).user;
    _dark ??= user?.preference.darkModeEnabled ?? true;
    if (_displayName.text.isEmpty) _displayName.text = user?.displayName ?? '';
    if (_email.text.isEmpty) _email.text = user?.email ?? '';
    if (_bio.text.isEmpty) _bio.text = user?.bio ?? '';

    return AppPage(
      title: 'Settings',
      subtitle: 'Account and preferences',
      child: ListView(
        children: [
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Profile')),
              ButtonSegment(value: 1, label: Text('Preferences')),
              ButtonSegment(value: 2, label: Text('Account')),
            ],
            selected: {_tab},
            onSelectionChanged: (set) => setState(() => _tab = set.first),
          ),
          const SizedBox(height: 12),
          if (_tab == 0) ...[
            TextField(
              controller: _displayName,
              decoration: const InputDecoration(labelText: 'Display name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _bio,
              decoration: const InputDecoration(labelText: 'Bio'),
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: settingsViewModel.busy
                  ? null
                  : () async {
                      await ref
                          .read(settingsViewModelProvider)
                          .saveProfile(
                            displayName: _displayName.text,
                            email: _email.text,
                            bio: _bio.text,
                          );
                      if (!mounted) return;
                      setState(() => _message = settingsViewModel.message);
                    },
              child: const Text('Save Profile'),
            ),
          ],
          if (_tab == 1) ...[
            SwitchListTile(
              value: _dark ?? true,
              onChanged: (v) => setState(() => _dark = v),
              title: const Text('Dark mode'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _locale.text,
              decoration: const InputDecoration(labelText: 'Preferred locale'),
              items: const [
                DropdownMenuItem(value: 'en-US', child: Text('English (US)')),
                // DropdownMenuItem(
                //   value: 'id-ID',
                //   child: Text('Bahasa Indonesia'),
                // ),
                // DropdownMenuItem(value: 'ja-JP', child: Text('Japanese')),
              ],
              onChanged: (v) {
                if (v != null) _locale.text = v;
              },
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: settingsViewModel.busy
                  ? null
                  : () async {
                      await ref
                          .read(settingsViewModelProvider)
                          .savePreferences(
                            darkModeEnabled: _dark,
                            preferredLocale: _locale.text,
                          );
                      if (!mounted) return;
                      setState(() => _message = settingsViewModel.message);
                    },
              child: const Text('Save Preferences'),
            ),
          ],
          if (_tab == 2) ...[
            TextField(
              controller: _current,
              decoration: const InputDecoration(labelText: 'Current password'),
              obscureText: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _next,
              decoration: const InputDecoration(labelText: 'New password'),
              obscureText: true,
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: settingsViewModel.busy
                  ? null
                  : () async {
                      await ref
                          .read(settingsViewModelProvider)
                          .changePassword(
                            currentPassword: _current.text,
                            newPassword: _next.text,
                          );
                      if (!mounted) return;
                      setState(() => _message = settingsViewModel.message);
                    },
              child: const Text('Change Password'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () async {
                await ref.read(settingsViewModelProvider).logout();
                if (context.mounted) context.go('/login');
              },
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
            ),
          ],
          if (_message.isNotEmpty) ...[
            const SizedBox(height: 12),
            SelectableText(_message),
          ],
        ],
      ),
    );
  }
}
