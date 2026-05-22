import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skillforgeapp/ui/design_system.dart';
import 'package:skillforgeapp/view_models/auth/auth_view_model.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authViewModel = ref.watch(authViewModelProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackdrop(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Padding(
                padding: .symmetric(
                  horizontal: AppChromeMetrics.mobileOverlayMargin,
                ),
                child: GlassPanel(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Image.asset(
                          'assets/icons/icon@1240.png',
                          width: 72,
                          height: 72,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Create Account',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Start your SkillForge journey.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: authViewModel.error == null
                            ? const SizedBox.shrink()
                            : Container(
                                key: ValueKey(authViewModel.error),
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.all(12),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.red.withOpacity(0.35),
                                  ),
                                ),
                                child: Text(
                                  authViewModel.error!,
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _name,
                        onChanged: (_) => authViewModel.clearError(),
                        decoration: const InputDecoration(
                          labelText: 'Display Name',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _email,
                        onChanged: (_) => authViewModel.clearError(),
                        decoration: const InputDecoration(labelText: 'Email'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _password,
                        onChanged: (_) => authViewModel.clearError(),
                        decoration: const InputDecoration(
                          labelText: 'Password',
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: authViewModel.isLoading
                            ? null
                            : () async {
                                final ok = await authViewModel.register(
                                  _name.text.trim(),
                                  _email.text.trim(),
                                  _password.text,
                                );
                                if (!mounted) return;
                                if (ok) context.go('/student/dashboard');
                              },
                        icon: authViewModel.isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.person_add_alt_1),
                        label: Text(
                          authViewModel.isLoading
                              ? 'Creating...'
                              : 'Create account',
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: const Text('Back to login'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
