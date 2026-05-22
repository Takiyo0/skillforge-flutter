import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skillforgeapp/ui/design_system.dart';
import 'package:skillforgeapp/view_models/student/assessment_view_model.dart';

class AssessmentPage extends ConsumerStatefulWidget {
  const AssessmentPage({
    super.key,
    required this.courseId,
    required this.unitId,
  });

  final String courseId;
  final String unitId;

  @override
  ConsumerState<AssessmentPage> createState() => _AssessmentPageState();
}

class _AssessmentPageState extends ConsumerState<AssessmentPage> {
  int _currentQuestionIndex = 0;
  final Map<String, Set<String>> _selectedByQuestion = {};
  bool _submitting = false;
  Map<String, dynamic>? _result;

  List<Map<String, dynamic>> _toMapList(dynamic raw) {
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }

  void _toggleAnswer({
    required String questionId,
    required String optionId,
    required bool answerMultiple,
  }) {
    setState(() {
      final current = _selectedByQuestion[questionId] ?? <String>{};
      if (answerMultiple) {
        if (current.contains(optionId)) {
          current.remove(optionId);
        } else {
          current.add(optionId);
        }
      } else {
        current
          ..clear()
          ..add(optionId);
      }
      _selectedByQuestion[questionId] = current;
    });
  }

  Future<void> _submit({
    required String unitType,
    required String quizId,
    required String finalExamId,
  }) async {
    final answers = _selectedByQuestion.entries
        .where((entry) => entry.value.isNotEmpty)
        .map(
          (entry) => {
            'questionId': entry.key,
            'selectedOptionIds': entry.value.toList(),
          },
        )
        .toList();

    if (answers.isEmpty) {
      if (!mounted) return;
      AppToast.show(context, 'Select answers before submitting.');
      return;
    }

    setState(() => _submitting = true);
    try {
      final result = await ref
          .read(assessmentActionsProvider.notifier)
          .submit(
            unitType: unitType,
            unitId: widget.unitId,
            quizId: quizId,
            finalExamId: finalExamId,
            answers: answers,
          );
      if (!mounted) return;
      setState(() => _result = result);
    } catch (e) {
      if (!mounted) return;
      AppToast.show(context, 'Failed to submit: ${AppToast.errorMessage(e)}');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      assessmentViewModelProvider((
        courseId: widget.courseId,
        unitId: widget.unitId,
      )),
    );

    return AppPage(
      title: 'Assessment',
      subtitle: widget.unitId,
      child: state.when(
        loading: AppAsyncState.loading,
        error: (e, _) => AppAsyncState.error('Failed to load assessment: $e'),
        data: (bundle) {
          final blockedCompleted = bundle['blockedCompleted'] == true;
          if (blockedCompleted) {
            return Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('This unit is already completed.'),
                      const SizedBox(height: 8),
                      const Text(
                        'Starting this assessment/final exam is disabled.',
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => context.pop(true),
                        child: const Text('Back to Unit'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final unit = (bundle['unit'] as Map<String, dynamic>?) ?? const {};
          final unitType = (unit['type'] ?? '').toString();
          final quizId = (bundle['quizId'] ?? '').toString();
          final finalExamId = (bundle['finalExamId'] ?? '').toString();

          if (_result != null) {
            final scoreNum =
                ((_result!['scorePercent'] ?? _result!['score']) as num?)
                    ?.toDouble();
            final scoreLabel = scoreNum == null
                ? '-'
                : scoreNum % 1 == 0
                ? scoreNum.toInt().toString()
                : scoreNum.toStringAsFixed(1);
            final passed =
                _result!['isPassed'] == true ||
                _result!['passed'] == true ||
                ((scoreNum ?? 0) >= 70);
            final accent = passed
                ? const Color(0xFF2E7346)
                : const Color(0xFFDC2626);
            return Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      accent.withOpacity(0.18),
                      Theme.of(context).colorScheme.surface,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: accent.withOpacity(0.45)),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.18),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            passed ? Icons.emoji_events : Icons.flag_outlined,
                            color: accent,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            passed
                                ? 'Assessment Passed'
                                : 'Assessment Complete',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$scoreLabel%',
                            style: Theme.of(context).textTheme.displaySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: accent,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Final Score',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => context.pop(true),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back to Unit'),
                    ),
                  ],
                ),
              ),
            );
          }

          final questions = _toMapList(bundle['questions']);
          if (questions.isEmpty) {
            return const Center(child: Text('No questions available.'));
          }

          final current =
              questions[_currentQuestionIndex.clamp(0, questions.length - 1)];
          final questionId = (current['id'] ?? '').toString();
          final options = _toMapList(current['options']);
          final answerMultiple = current['answerMultiple'] == true;
          final selectedSingle =
              _selectedByQuestion[questionId]?.isNotEmpty == true
              ? _selectedByQuestion[questionId]!.first
              : null;
          final isCurrentAnswered =
              _selectedByQuestion[questionId]?.isNotEmpty == true;
          final answeredCount = _selectedByQuestion.values
              .where((e) => e.isNotEmpty)
              .length;
          final allAnswered = questions.every(
            (q) =>
                (_selectedByQuestion[(q['id'] ?? '').toString()]?.isNotEmpty ??
                false),
          );

          return ListView(
            padding: EdgeInsets.only(
              top: AppChromeMetrics.mobileTopBarPanelHeight,
              bottom: MediaQuery.paddingOf(context).bottom + 16,
            ),
            children: [
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Exit'),
                  ),
                  const Spacer(),
                  Text(
                    'Q ${_currentQuestionIndex + 1}/${questions.length} • $answeredCount answered',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (_currentQuestionIndex + 1) / questions.length,
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MarkdownBody(
                        data: (current['prompt'] ?? '-').toString(),
                        selectable: true,
                      ),
                      const SizedBox(height: 10),
                      ...options.map((option) {
                        final optionId = (option['id'] ?? '').toString();
                        final selected =
                            _selectedByQuestion[questionId]?.contains(
                              optionId,
                            ) ??
                            false;
                        return Card(
                          color: selected
                              ? Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.12)
                              : null,
                          child: ListTile(
                            leading: answerMultiple
                                ? Checkbox(
                                    value: selected,
                                    onChanged: (_) => _toggleAnswer(
                                      questionId: questionId,
                                      optionId: optionId,
                                      answerMultiple: answerMultiple,
                                    ),
                                  )
                                : Radio<String>(
                                    value: optionId,
                                    groupValue: selectedSingle,
                                    onChanged: (_) => _toggleAnswer(
                                      questionId: questionId,
                                      optionId: optionId,
                                      answerMultiple: answerMultiple,
                                    ),
                                  ),
                            title: MarkdownBody(
                              data: (option['label'] ?? '-').toString(),
                              selectable: true,
                            ),
                            onTap: () => _toggleAnswer(
                              questionId: questionId,
                              optionId: optionId,
                              answerMultiple: answerMultiple,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: _currentQuestionIndex == 0
                        ? null
                        : () => setState(() => _currentQuestionIndex -= 1),
                    child: const Text('Previous'),
                  ),
                  const SizedBox(width: 8),
                  if (_currentQuestionIndex < questions.length - 1)
                    Expanded(
                      child: isCurrentAnswered
                          ? FilledButton(
                              onPressed: () =>
                                  setState(() => _currentQuestionIndex += 1),
                              child: const Text('Next'),
                            )
                          : FilledButton.tonal(
                              onPressed: () =>
                                  setState(() => _currentQuestionIndex += 1),
                              child: const Text('Next'),
                            ),
                    )
                  else
                    Expanded(
                      child: FilledButton(
                        onPressed: (_submitting || !allAnswered)
                            ? null
                            : () => _submit(
                                unitType: unitType,
                                quizId: quizId,
                                finalExamId: finalExamId,
                              ),
                        child: Text(_submitting ? 'Submitting...' : 'Submit'),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
