import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skillforgeapp/ui/design_system.dart';
import 'package:skillforgeapp/view_models/student/code_playground_view_model.dart';

class CodePlaygroundPage extends ConsumerStatefulWidget {
  const CodePlaygroundPage({super.key});

  @override
  ConsumerState<CodePlaygroundPage> createState() => _CodePlaygroundPageState();
}

class _SandboxCase {
  _SandboxCase({required this.id, String? input, String? output})
    : input = TextEditingController(text: input ?? ''),
      output = TextEditingController(text: output ?? '');

  final String id;
  final TextEditingController input;
  final TextEditingController output;

  void dispose() {
    input.dispose();
    output.dispose();
  }
}

class _CodePlaygroundPageState extends ConsumerState<CodePlaygroundPage> {
  String _language = 'javascript';
  final _code = TextEditingController();
  final List<_SandboxCase> _cases = [_SandboxCase(id: 'case-0')];
  Map<String, dynamic>? _result;
  bool _running = false;
  String? _error;

  void _handleTapOutside(PointerDownEvent _) {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  void dispose() {
    _code.dispose();
    for (final c in _cases) {
      c.dispose();
    }
    super.dispose();
  }

  String _monacoLikeLanguageLabel(String id) {
    if (id == 'gcc') return 'c';
    return id;
  }

  void _addCase() {
    setState(() {
      _cases.add(
        _SandboxCase(id: 'case-${DateTime.now().microsecondsSinceEpoch}'),
      );
    });
  }

  void _removeCase(String id) {
    if (_cases.length == 1) return;
    final index = _cases.indexWhere((c) => c.id == id);
    if (index < 0) return;
    setState(() {
      final c = _cases.removeAt(index);
      c.dispose();
    });
  }

  Future<void> _runCode() async {
    if (_code.text.trim().isEmpty) {
      setState(() => _error = 'Code is required.');
      return;
    }

    setState(() {
      _running = true;
      _error = null;
    });

    try {
      final testCases = _cases
          .map(
            (c) => {
              'input': c.input.text,
              if (c.output.text.trim().isNotEmpty) 'output': c.output.text,
            },
          )
          .toList();

      final res = await ref
          .read(codePlaygroundActionsProvider.notifier)
          .runCode(code: _code.text, language: _language, testCases: testCases);

      if (!mounted) return;
      setState(() => _result = res);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Failed to run code: $e');
    } finally {
      if (mounted) {
        setState(() => _running = false);
      }
    }
  }

  List<Map<String, dynamic>> _resultItems() {
    final r = _result;
    if (r == null) return const [];
    final items = r['results'];
    if (items is List) {
      return items
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
    }
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sandboxLanguagesViewModelProvider);

    return AppPage(
      title: 'Code Sandbox',
      subtitle: 'Run quick experiments',
      child: state.when(
        loading: AppAsyncState.loading,
        error: (e, _) => AppAsyncState.error('Failed to load languages: $e'),
        data: (langs) {
          final languageIds = langs
              .map((e) => (e['id'] ?? '').toString())
              .where((id) => id.isNotEmpty)
              .toList();

          if (languageIds.isNotEmpty && !languageIds.contains(_language)) {
            _language = languageIds.first;
          }

          final selected = langs
              .where((e) => (e['id'] ?? '').toString() == _language)
              .toList();
          final selectedLanguage = selected.isNotEmpty ? selected.first : null;
          final baseCode = (selectedLanguage?['baseCode'] ?? '').toString();
          if (_code.text.isEmpty && baseCode.isNotEmpty) {
            _code.text = baseCode;
          }

          final results = _resultItems();

          return ListView(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: languageIds.isEmpty ? null : _language,
                              decoration: const InputDecoration(
                                labelText: 'Language',
                              ),
                              items: languageIds
                                  .map(
                                    (id) => DropdownMenuItem(
                                      value: id,
                                      child: Text(id),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                if (v == null) return;
                                setState(() {
                                  _language = v;
                                  final found = langs.firstWhere(
                                    (x) => (x['id'] ?? '').toString() == v,
                                    orElse: () => const <String, dynamic>{},
                                  );
                                  final code = (found['baseCode'] ?? '')
                                      .toString();
                                  if (code.isNotEmpty) {
                                    _code.text = code;
                                  }
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Editor · ${_monacoLikeLanguageLabel(_language)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _code,
                        minLines: 14,
                        maxLines: 22,
                        onTapOutside: _handleTapOutside,
                        decoration: const InputDecoration(labelText: 'Code'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Test Cases',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Spacer(),
                          FilledButton.tonalIcon(
                            onPressed: _addCase,
                            icon: const Icon(Icons.add),
                            label: const Text('Add'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ..._cases.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final tc = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Case ${idx + 1}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        onPressed: () => _removeCase(tc.id),
                                        icon: const Icon(Icons.delete_outline),
                                      ),
                                    ],
                                  ),
                                  TextField(
                                    controller: tc.input,
                                    minLines: 2,
                                    maxLines: 4,
                                    onTapOutside: _handleTapOutside,
                                    decoration: const InputDecoration(
                                      labelText: 'Input',
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: tc.output,
                                    minLines: 2,
                                    maxLines: 4,
                                    onTapOutside: _handleTapOutside,
                                    decoration: const InputDecoration(
                                      labelText: 'Expected output (optional)',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: _running ? null : _runCode,
                        icon: const Icon(Icons.play_arrow),
                        label: Text(_running ? 'Running...' : 'Run Code'),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Results',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (_result == null)
                        const Text('No run yet.')
                      else if (results.isEmpty)
                        SelectableText(_result.toString())
                      else
                        ...results.map((item) {
                          final passed = item['passed'] == true;
                          final actual =
                              (item['actualOutput'] ??
                                      item['actual'] ??
                                      item['output'] ??
                                      '')
                                  .toString();
                          final expected = (item['expectedOutput'] ?? '')
                              .toString();
                          final stderr = (item['stderr'] ?? '').toString();
                          final compileOutput = (item['compileOutput'] ?? '')
                              .toString();
                          final idx =
                              ((item['index'] as num?)?.toInt() ?? 0) + 1;
                          final isCorrect = item['isCorrect'];

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Card(
                              color: passed
                                  ? Colors.green.withValues(alpha: 0.12)
                                  : Colors.red.withValues(alpha: 0.12),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Case $idx',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const Spacer(),
                                        Row(
                                          children: [
                                            Icon(
                                              passed
                                                  ? Icons.check_circle
                                                  : Icons.cancel,
                                              size: 16,
                                              color: passed
                                                  ? Colors.green
                                                  : Colors.red,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(passed ? 'Passed' : 'Failed'),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    SelectableText(
                                      'Actual Output:\n${actual.isEmpty ? '(no output)' : actual}',
                                    ),
                                    if (expected.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      SelectableText(
                                        'Expected Output:\n$expected',
                                      ),
                                    ],
                                    if (isCorrect != null) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        isCorrect == true
                                            ? 'Output matches expected'
                                            : 'Output does not match expected',
                                        style: TextStyle(
                                          color: isCorrect == true
                                              ? Colors.green
                                              : Colors.orange,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                    if (stderr.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      SelectableText(
                                        'stderr:\n$stderr',
                                        style: const TextStyle(
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                    if (compileOutput.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      SelectableText(
                                        'compileOutput:\n$compileOutput',
                                        style: const TextStyle(
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
