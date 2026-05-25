import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skillforgeapp/ui/design_system.dart';
import 'package:skillforgeapp/view_models/student/unit_view_model.dart';
import 'package:video_player/video_player.dart';

class UnitViewPage extends ConsumerStatefulWidget {
  const UnitViewPage({super.key, required this.courseId, required this.unitId});

  final String courseId;
  final String unitId;

  @override
  ConsumerState<UnitViewPage> createState() => _UnitViewPageState();
}

class _UnitViewPageState extends ConsumerState<UnitViewPage> {
  final _code = TextEditingController();
  Map<String, dynamic>? _submissionResult;
  Timer? _pollTimer;
  bool _completingModule = false;
  String? _seededStarterCodeUnitId;

  @override
  void dispose() {
    _pollTimer?.cancel();
    _code.dispose();
    super.dispose();
  }

  Future<void> _pollSubmission(String submissionId) async {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      try {
        final status = await ref
            .read(
              unitViewActionsProvider((
                courseId: widget.courseId,
                unitId: widget.unitId,
              )).notifier,
            )
            .getSubmissionStatus(submissionId);
        if (!mounted) return;
        setState(() => _submissionResult = status);
        final state = (status['status'] ?? '').toString();
        if (state == 'finished' || state == 'failed' || state == 'passed') {
          timer.cancel();
          await ref
              .read(
                unitViewActionsProvider((
                  courseId: widget.courseId,
                  unitId: widget.unitId,
                )).notifier,
              )
              .refreshBundle();
        }
      } catch (_) {
        timer.cancel();
      }
    });
  }

  List<Map<String, dynamic>> _toMapList(dynamic raw) {
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      unitBundleProvider((courseId: widget.courseId, unitId: widget.unitId)),
    );

    return AppPage(
      title: 'Unit View',
      subtitle: widget.unitId,
      child: state.when(
        loading: AppAsyncState.loading,
        error: (e, _) => AppAsyncState.error('Failed to load unit: $e'),
        data: (value) {
          final unit = (value['unit'] as Map<String, dynamic>?) ?? const {};
          final progress =
              (value['progress'] as Map<String, dynamic>?) ?? const {};
          final submissions = _toMapList(value['submissions']);
          final unitType = (unit['type'] ?? '').toString();

          final unitProgressItems = _toMapList(progress['unitProgress']);
          final selfProgress = unitProgressItems.where(
            (p) => (p['unitId'] ?? '').toString() == widget.unitId,
          );
          final unitStatus = selfProgress.isNotEmpty
              ? (selfProgress.first['status'] ?? '').toString()
              : 'locked';

          final isLocked = unitStatus == 'locked';
          final isCompleted = unitStatus == 'completed';

          final moduleContent = (unit['moduleContent'] is Map<String, dynamic>)
              ? unit['moduleContent'] as Map<String, dynamic>
              : const <String, dynamic>{};
          final exercise = (unit['exercise'] is Map<String, dynamic>)
              ? unit['exercise'] as Map<String, dynamic>
              : const <String, dynamic>{};
          final testCases = _toMapList(exercise['testCases']);
          final quiz = (unit['quiz'] is Map<String, dynamic>)
              ? unit['quiz'] as Map<String, dynamic>
              : const <String, dynamic>{};
          final finalExam =
              ((unit['finalExam'] ?? unit['final_exam'])
                  is Map<String, dynamic>)
              ? (unit['finalExam'] ?? unit['final_exam'])
                    as Map<String, dynamic>
              : const <String, dynamic>{};

          if (unitType == 'exercise' &&
              _seededStarterCodeUnitId != widget.unitId &&
              _code.text.isEmpty) {
            _code.text = (exercise['starterCode'] ?? '').toString();
            _seededStarterCodeUnitId = widget.unitId;
          }

          return ListView(
            children: [
              Text(
                (unit['title'] ?? '-').toString(),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              if ((unit['summary'] ?? '') != '')
                Text((unit['summary'] ?? '').toString()),
              if ((unit['summary'] ?? '') != '') const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text('Type: ${unitType.replaceAll('_', ' ')}')),
                  Chip(label: Text('Status: $unitStatus')),
                ],
              ),
              const SizedBox(height: 12),

              if (unitType == 'module') ...[
                if (moduleContent['articleMarkdown'] != null &&
                    (moduleContent['articleMarkdown'] as String).isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: MarkdownBody(
                        data: (moduleContent['articleMarkdown'] ?? '')
                            .toString(),
                        selectable: true,
                      ),
                    ),
                  ),
                if ((moduleContent['videoUrl'] ?? '').toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _ModuleVideoPlayer(
                      url: (moduleContent['videoUrl'] ?? '').toString(),
                    ),
                  ),
                const SizedBox(height: 12),
                if (!isLocked && !isCompleted)
                  FilledButton.icon(
                    onPressed: _completingModule
                        ? null
                        : () async {
                            setState(() => _completingModule = true);
                            try {
                              await ref
                                  .read(
                                    unitViewActionsProvider((
                                      courseId: widget.courseId,
                                      unitId: widget.unitId,
                                    )).notifier,
                                  )
                                  .completeUnit();
                            } finally {
                              if (mounted) {
                                setState(() => _completingModule = false);
                              }
                            }
                          },
                    icon: _completingModule
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(
                      _completingModule ? 'Completing...' : 'Mark as Complete',
                    ),
                  ),
                if (isCompleted)
                  const Card(
                    child: ListTile(
                      leading: Icon(Icons.check_circle, color: Colors.green),
                      title: Text('Unit Completed'),
                    ),
                  ),
              ],

              if (unitType == 'exercise') ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Problem',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        MarkdownBody(
                          data: (exercise['promptMarkdown'] ?? '-').toString(),
                          selectable: true,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (testCases.isNotEmpty) ...[
                  _ExerciseTestCasesCard(testCases: testCases),
                  const SizedBox(height: 10),
                ],
                TextField(
                  controller: _code,
                  minLines: 8,
                  maxLines: 14,
                  decoration: const InputDecoration(labelText: 'Exercise Code'),
                ),
                const SizedBox(height: 10),
                if (!isCompleted)
                  FilledButton(
                    onPressed: isLocked
                        ? null
                        : () async {
                            final exerciseId = (exercise['id'] ?? '')
                                .toString();
                            if (exerciseId.isEmpty) return;
                            final difficulty =
                                (exercise['difficulty'] ?? 'normal').toString();
                            final lang = (exercise['language'] ?? 'javascript')
                                .toString();
                            final result = await ref
                                .read(
                                  unitViewActionsProvider((
                                    courseId: widget.courseId,
                                    unitId: widget.unitId,
                                  )).notifier,
                                )
                                .submitExerciseCode(
                                  exerciseId: exerciseId,
                                  sourceCode: _code.text,
                                  language: lang,
                                  difficulty: difficulty,
                                );
                            if (!mounted) return;
                            setState(() => _submissionResult = result);
                            final id =
                                (result['submissionId'] ?? result['id'] ?? '')
                                    .toString();
                            if (id.isNotEmpty) {
                              await _pollSubmission(id);
                            } else {
                              await ref
                                  .read(
                                    unitViewActionsProvider((
                                      courseId: widget.courseId,
                                      unitId: widget.unitId,
                                    )).notifier,
                                  )
                                  .refreshBundle();
                            }
                          },
                    child: const Text('Submit Code'),
                  ),
                if (isCompleted)
                  Card(
                    color: Colors.green.withValues(alpha: 0.12),
                    child: const ListTile(
                      leading: Icon(Icons.lock_outline, color: Colors.green),
                      title: Text('Exercise already completed'),
                      subtitle: Text(
                        'Submission is disabled for completed exercises.',
                      ),
                    ),
                  ),
                if (_submissionResult != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Card(
                      child: ListTile(
                        title: const Text('Latest Submission'),
                        subtitle: Text(
                          'Status: ${_submissionResult!['status'] ?? '-'}\n'
                          'Tests: ${_submissionResult!['testsPassed'] ?? '-'} / ${_submissionResult!['totalTests'] ?? '-'}',
                        ),
                        trailing: TextButton(
                          onPressed: () => showAppBottomSheet<void>(
                            context: context,
                            initialChildSize: 0.78,
                            minChildSize: 0.42,
                            builder: (_, scrollController) =>
                                _SubmissionDetailSheet(
                                  courseId: widget.courseId,
                                  unitId: widget.unitId,
                                  submission: _submissionResult!,
                                  scrollController: scrollController,
                                ),
                          ),
                          child: const Text('View Detail'),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                if (submissions.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Previous Submissions (${submissions.length})',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      ...submissions.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final sub = entry.value;
                        final status = (sub['status'] ?? '').toString();
                        final passed = status == 'passed';
                        final failed = status == 'failed';
                        final t = (sub['finishedAt'] ?? sub['queuedAt'] ?? '')
                            .toString();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Card(
                            color: passed
                                ? Colors.green.withValues(alpha: 0.12)
                                : failed
                                ? Colors.red.withValues(alpha: 0.12)
                                : null,
                            child: ListTile(
                              title: Text(
                                'Submission #${submissions.length - idx} • ${status.toUpperCase()}',
                              ),
                              subtitle: Text(
                                '${t.isEmpty ? '-' : t}\n'
                                'Tests: ${sub['testsPassed'] ?? '-'} / ${sub['totalTests'] ?? '-'}',
                              ),
                              trailing: TextButton(
                                onPressed: () => showAppBottomSheet<void>(
                                  context: context,
                                  initialChildSize: 0.78,
                                  minChildSize: 0.42,
                                  builder: (_, scrollController) =>
                                      _SubmissionDetailSheet(
                                        courseId: widget.courseId,
                                        unitId: widget.unitId,
                                        submission: sub,
                                        scrollController: scrollController,
                                      ),
                                ),
                                child: const Text('View Code'),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
              ],

              if (unitType == 'assessment') ...[
                Card(
                  child: ListTile(
                    title: Text((quiz['title'] ?? 'Assessment').toString()),
                    subtitle: Text(
                      'Passing score: ${quiz['passingScore'] ?? '-'}% • '
                      '${((quiz['timeLimitSeconds'] as num?)?.toInt() ?? 0) ~/ 60} min',
                    ),
                  ),
                ),
                if (isCompleted)
                  Card(
                    color: Colors.green.withValues(alpha: 0.12),
                    child: const ListTile(
                      leading: Icon(Icons.check_circle, color: Colors.green),
                      title: Text('Assessment already completed'),
                      subtitle: Text('Starting this assessment is disabled.'),
                    ),
                  ),
                FilledButton(
                  onPressed: (isLocked || isCompleted)
                      ? null
                      : () async {
                          await context.push(
                            '/student/courses/${widget.courseId}/units/${widget.unitId}/assessment',
                          );
                          if (!mounted) return;
                          await ref
                              .read(
                                unitViewActionsProvider((
                                  courseId: widget.courseId,
                                  unitId: widget.unitId,
                                )).notifier,
                              )
                              .refreshBundle();
                        },
                  child: const Text('Start Assessment'),
                ),
                const SizedBox(height: 12),
                if (_toMapList(quiz['submissions']).isNotEmpty) ...[
                  Text(
                    'Previous Attempts',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ..._toMapList(quiz['submissions']).map((submission) {
                    final passed = submission['isPassed'] == true;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Card(
                        color: passed
                            ? Colors.green.withValues(alpha: 0.12)
                            : Colors.orange.withValues(alpha: 0.12),
                        child: ListTile(
                          title: Text(
                            'Attempt ${submission['attemptNumber'] ?? '-'}'
                            ' • ${passed ? 'PASSED' : 'FAILED'}',
                          ),
                          subtitle: Text(
                            'Score: ${submission['scorePercent'] ?? '-'}%\n'
                            'Submitted: ${(submission['submittedAt'] ?? '-').toString()}',
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ],

              if (unitType == 'final_exam') ...[
                Card(
                  child: ListTile(
                    title: Text(
                      (finalExam['title'] ?? 'Final Exam').toString(),
                    ),
                    subtitle: Text(
                      'Passing score: ${finalExam['passingScore'] ?? '-'}% • '
                      '${((finalExam['timeLimitSeconds'] as num?)?.toInt() ?? 0) ~/ 60} min',
                    ),
                  ),
                ),
                if (isCompleted)
                  Card(
                    color: Colors.green.withValues(alpha: 0.12),
                    child: const ListTile(
                      leading: Icon(Icons.check_circle, color: Colors.green),
                      title: Text('Final exam already completed'),
                      subtitle: Text('Starting this final exam is disabled.'),
                    ),
                  ),
                FilledButton(
                  onPressed: (isLocked || isCompleted)
                      ? null
                      : () async {
                          await context.push(
                            '/student/courses/${widget.courseId}/units/${widget.unitId}/assessment',
                          );
                          if (!mounted) return;
                          await ref
                              .read(
                                unitViewActionsProvider((
                                  courseId: widget.courseId,
                                  unitId: widget.unitId,
                                )).notifier,
                              )
                              .refreshBundle();
                        },
                  child: const Text('Start Final Exam'),
                ),
                const SizedBox(height: 12),
                ...() {
                  final finalExamSubmissions = _toMapList(
                    unit['finalExamSubmissions'],
                  );
                  final nestedSubmissions = _toMapList(
                    finalExam['submissions'],
                  );
                  final source = finalExamSubmissions.isNotEmpty
                      ? finalExamSubmissions
                      : nestedSubmissions;
                  if (source.isEmpty) return const <Widget>[];
                  return <Widget>[
                    Text(
                      'Submission History',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ...source.map((submission) {
                      final passed = submission['isPassed'] == true;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Card(
                          color: passed
                              ? Colors.green.withValues(alpha: 0.12)
                              : Colors.orange.withValues(alpha: 0.12),
                          child: ListTile(
                            title: Text(
                              'Attempt ${submission['attemptNumber'] ?? '-'}'
                              ' • ${passed ? 'PASSED' : 'FAILED'}',
                            ),
                            subtitle: Text(
                              'Score: ${submission['scorePercent'] ?? '-'}%\n'
                              'Submitted: ${(submission['submittedAt'] ?? '-').toString()}',
                            ),
                          ),
                        ),
                      );
                    }),
                  ];
                }(),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ExerciseTestCasesCard extends StatelessWidget {
  const _ExerciseTestCasesCard({required this.testCases});

  final List<Map<String, dynamic>> testCases;

  @override
  Widget build(BuildContext context) {
    final visibleCount = testCases
        .where((testCase) => testCase['isHidden'] != true)
        .length;
    final hiddenCount = testCases.length - visibleCount;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Test Cases',
                    style: Theme
                        .of(context)
                        .textTheme
                        .titleMedium,
                  ),
                ),
                Chip(
                  label: Text(
                    hiddenCount > 0
                        ? '$visibleCount visible • $hiddenCount hidden'
                        : '$visibleCount visible',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...testCases.indexed.map((entry) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: entry.$1 == testCases.length - 1 ? 0 : 8,
                ),
                child: _ExerciseTestCaseTile(
                  index: entry.$1 + 1,
                  testCase: entry.$2,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _ExerciseTestCaseTile extends StatelessWidget {
  const _ExerciseTestCaseTile({required this.index, required this.testCase});

  final int index;
  final Map<String, dynamic> testCase;

  @override
  Widget build(BuildContext context) {
    final hidden = testCase['isHidden'] == true;
    final input = (testCase['inputText'] ?? '').toString();
    final expected = (testCase['expectedOutput'] ?? '').toString();
    final weight = (testCase['weight'] as num?)?.toInt();
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hidden ? Icons.lock_outline : Icons.fact_check_outlined,
                size: 18,
                color: hidden ? theme.colorScheme.outline : Colors.green,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Case $index',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (weight != null) Chip(label: Text('Weight $weight')),
            ],
          ),
          const SizedBox(height: 8),
          if (hidden)
            Text(
              'Hidden test case. Input and expected output are not shown.',
              style: theme.textTheme.bodyMedium,
            )
          else
            ...[
              _TestCaseField(label: 'Input', value: input),
              const SizedBox(height: 8),
              _TestCaseField(label: 'Expected Output', value: expected),
            ],
        ],
      ),
    );
  }
}

class _TestCaseField extends StatelessWidget {
  const _TestCaseField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = value
        .trim()
        .isEmpty ? '(empty)' : value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark
                ? const Color(0xFF020617)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
            ),
          ),
          child: SelectableText(
            text,
            style: const TextStyle(fontFamily: 'monospace', height: 1.45),
          ),
        ),
      ],
    );
  }
}

class _SubmissionDetailSheet extends ConsumerStatefulWidget {
  const _SubmissionDetailSheet({
    required this.courseId,
    required this.unitId,
    required this.submission,
    required this.scrollController,
  });

  final String courseId;
  final String unitId;
  final Map<String, dynamic> submission;
  final ScrollController scrollController;

  @override
  ConsumerState<_SubmissionDetailSheet> createState() =>
      _SubmissionDetailSheetState();
}

class _SubmissionDetailSheetState
    extends ConsumerState<_SubmissionDetailSheet> {
  late Map<String, dynamic> _submission;
  bool _askingAiExplanation = false;
  String? _aiExplanationError;

  @override
  void initState() {
    super.initState();
    _submission = Map<String, dynamic>.from(widget.submission);
  }

  Future<void> _askAiExplanation() async {
    final submissionId = (_submission['id'] ?? '').toString();
    if (submissionId.isEmpty) return;
    setState(() {
      _askingAiExplanation = true;
      _aiExplanationError = null;
    });
    try {
      final result = await ref
          .read(
            unitViewActionsProvider((
              courseId: widget.courseId,
              unitId: widget.unitId,
            )).notifier,
          )
          .askAiSubmissionExplanation(submissionId);
      if (!mounted) return;
      setState(() {
        _submission = {
          ..._submission,
          'aiCodeExplanation': (result['aiCodeExplanation'] ?? '').toString(),
        };
      });
      await ref
          .read(
            unitViewActionsProvider((
              courseId: widget.courseId,
              unitId: widget.unitId,
            )).notifier,
          )
          .refreshBundle();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _aiExplanationError =
            'Failed to get AI explanation: ${AppToast.errorMessage(e)}';
      });
    } finally {
      if (mounted) setState(() => _askingAiExplanation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = (_submission['status'] ?? '-').toString();
    final upperStatus = status.toUpperCase();
    final testsPassed = (_submission['testsPassed'] ?? '-').toString();
    final totalTests = (_submission['totalTests'] ?? '-').toString();
    final queuedAt = (_submission['queuedAt'] ?? '').toString();
    final finishedAt = (_submission['finishedAt'] ?? '').toString();
    final sourceCode = (_submission['sourceCode'] ?? '').toString();
    final aiCodeExplanation = (_submission['aiCodeExplanation'] ?? '')
        .toString();
    final stdout = (_submission['stdout'] ?? '').toString();
    final stderr = (_submission['stderr'] ?? '').toString();
    final compileOutput = (_submission['compileOutput'] ?? '').toString();
    final statusColor = switch (status) {
      'passed' => const Color(0xFF16A34A),
      'finished' => const Color(0xFF2563EB),
      'failed' => const Color(0xFFDC2626),
      _ => const Color(0xFFF59E0B),
    };

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: SingleChildScrollView(
          controller: widget.scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Submission Detail',
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Review the code and execution result for this attempt.',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.28),
                          ),
                        ),
                        child: Text(
                          upperStatus,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _SubmissionMetaCard(
                          label: 'Submitted',
                          value: queuedAt.isEmpty ? '-' : queuedAt,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SubmissionMetaCard(
                          label: 'Finished',
                          value: finishedAt.isEmpty ? '-' : finishedAt,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _SubmissionMetaCard(
                          label: 'Tests Passed',
                          value: '$testsPassed / $totalTests',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'AI Code Explanation',
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      FilledButton.tonalIcon(
                        onPressed:
                            _askingAiExplanation || aiCodeExplanation.isNotEmpty
                            ? null
                            : _askAiExplanation,
                        icon: const Icon(Icons.smart_toy_outlined),
                        label: Text(
                          aiCodeExplanation.isNotEmpty
                              ? 'Already Used'
                              : _askingAiExplanation
                              ? 'Analyzing...'
                              : 'Ask AI What\'s Wrong',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_aiExplanationError != null)
                    Text(
                      _aiExplanationError!,
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else if (aiCodeExplanation.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withValues(
                            alpha: 0.45,
                          ),
                        ),
                      ),
                      child: MarkdownBody(
                        data: aiCodeExplanation,
                        selectable: true,
                      ),
                    )
                  else
                    Text(
                      'You can ask AI for explanation once for this submission.',
                      style: theme.textTheme.bodyMedium,
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text('Source Code', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 220),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.dark
                      ? const Color(0xFF020617)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.7,
                    ),
                  ),
                ),
                child: SelectableText(
                  sourceCode.isEmpty
                      ? '// No source code captured'
                      : sourceCode,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
              if (stdout.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text('Output', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                _SubmissionCodeSurface(text: stdout),
              ],
              if (stderr.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text('Error Output', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                _SubmissionCodeSurface(text: stderr),
              ],
              if (compileOutput.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text('Compile Output', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                _SubmissionCodeSurface(text: compileOutput),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SubmissionCodeSurface extends StatelessWidget {
  const _SubmissionCodeSurface({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 100),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? const Color(0xFF020617)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: SelectableText(
        text,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          height: 1.5,
        ),
      ),
    );
  }
}

class _SubmissionMetaCard extends StatelessWidget {
  const _SubmissionMetaCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(value, style: theme.textTheme.titleSmall),
        ],
      ),
    );
  }
}

class _ModuleVideoPlayer extends StatefulWidget {
  const _ModuleVideoPlayer({required this.url});

  final String url;

  @override
  State<_ModuleVideoPlayer> createState() => _ModuleVideoPlayerState();
}

class _ModuleVideoPlayerState extends State<_ModuleVideoPlayer> {
  VideoPlayerController? _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(covariant _ModuleVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _disposeController();
      _init();
    }
  }

  Future<void> _init() async {
    if (widget.url.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Video URL is empty.';
      });
      return;
    }
    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.url),
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Failed to load video: ${AppToast.errorMessage(e)}';
      });
    }
  }

  Future<void> _disposeController() async {
    final c = _controller;
    _controller = null;
    if (c != null) {
      await c.dispose();
    }
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (_error != null) {
      return Card(
        child: ListTile(
          title: const Text('Video unavailable'),
          subtitle: Text(_error!),
        ),
      );
    }
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Card(
        child: ListTile(
          title: Text('Video unavailable'),
          subtitle: Text('Video controller is not initialized.'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Module Video',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            AspectRatio(
              aspectRatio: controller.value.aspectRatio == 0
                  ? 16 / 9
                  : controller.value.aspectRatio,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: VideoPlayer(controller),
              ),
            ),
            const SizedBox(height: 8),
            VideoProgressIndicator(controller, allowScrubbing: true),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    if (controller.value.isPlaying) {
                      controller.pause();
                    } else {
                      controller.play();
                    }
                    setState(() {});
                  },
                  icon: Icon(
                    controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  ),
                ),
                Text(controller.value.isPlaying ? 'Playing' : 'Paused'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
