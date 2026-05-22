import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skillforgeapp/view_models/admin/admin_assessment_final_exam_view_model.dart';
import 'package:skillforgeapp/models/admin/admin_models.dart';
import 'package:skillforgeapp/ui/design_system.dart';

class AdminAssessmentFinalExamSection extends StatelessWidget {
  const AdminAssessmentFinalExamSection({
    super.key,
    required this.unit,
    required this.onToast,
    required this.refreshUnit,
  });

  final AdminUnitDetail unit;
  final void Function(String message) onToast;
  final Future<AdminUnitDetail> Function() refreshUnit;

  @override
  Widget build(BuildContext context) {
    if (unit.type == 'assessment') {
      return _AdminQuizEditor(
        unit: unit,
        onToast: onToast,
        refreshUnit: refreshUnit,
      );
    }
    if (unit.type == 'final_exam') {
      return _AdminFinalExamEditor(
        unit: unit,
        onToast: onToast,
        refreshUnit: refreshUnit,
      );
    }
    return const SizedBox.shrink();
  }
}

class _AdminQuizEditor extends ConsumerStatefulWidget {
  const _AdminQuizEditor({
    required this.unit,
    required this.onToast,
    required this.refreshUnit,
  });

  final AdminUnitDetail unit;
  final void Function(String message) onToast;
  final Future<AdminUnitDetail> Function() refreshUnit;

  @override
  ConsumerState<_AdminQuizEditor> createState() => _AdminQuizEditorState();
}

class _AdminQuizEditorState extends ConsumerState<_AdminQuizEditor> {
  bool _busy = false;
  String? _expandedQuestionId;

  AdminQuiz? get _quiz => widget.unit.quiz;

  Future<void> _createQuiz() async {
    final result = await showAppDialog<_QuizFormResult>(
      context: context,
      useRootNavigator: true,
      builder: (context) => const _QuizFormDialog(),
    );
    if (result == null) return;
    await _run(
      action: () async {
        await ref
            .read(adminAssessmentFinalExamActionsProvider.notifier)
            .createAdminQuiz(
              unitId: widget.unit.id,
              title: result.title,
              instructions: result.instructions,
              passingScore: result.passingScore,
              timeLimitSeconds: result.timeLimitSeconds,
              randomizeQuestions: result.randomizeQuestions,
              randomizeOptions: result.randomizeOptions,
            );
        await widget.refreshUnit();
        widget.onToast('Quiz created');
      },
    );
  }

  Future<void> _editQuiz(AdminQuiz quiz) async {
    final result = await showAppDialog<_QuizFormResult>(
      context: context,
      useRootNavigator: true,
      builder: (context) => _QuizFormDialog(initial: quiz),
    );
    if (result == null) return;
    await _run(
      action: () async {
        await ref
            .read(adminAssessmentFinalExamActionsProvider.notifier)
            .updateAdminQuiz(
              quizId: quiz.id,
              title: result.title,
              instructions: result.instructions,
              passingScore: result.passingScore,
              timeLimitSeconds: result.timeLimitSeconds,
              randomizeQuestions: result.randomizeQuestions,
              randomizeOptions: result.randomizeOptions,
            );
        await widget.refreshUnit();
        widget.onToast('Quiz updated');
      },
    );
  }

  Future<void> _deleteQuiz(AdminQuiz quiz) async {
    final confirm = await showAppDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quiz'),
        content: Text('Delete "${quiz.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _run(
      action: () async {
        await ref
            .read(adminAssessmentFinalExamActionsProvider.notifier)
            .deleteAdminQuiz(quiz.id);
        await widget.refreshUnit();
        widget.onToast('Quiz deleted');
      },
    );
  }

  Future<void> _createQuestion(AdminQuiz quiz) async {
    final result = await showAppDialog<_QuestionFormResult>(
      context: context,
      useRootNavigator: true,
      builder: (context) =>
          const _QuestionFormDialog(mode: _QuestionFormMode.create),
    );
    if (result == null) return;
    await _run(
      action: () async {
        await ref
            .read(adminAssessmentFinalExamActionsProvider.notifier)
            .addAdminQuizQuestion(
              quizId: quiz.id,
              prompt: result.prompt,
              points: result.points,
              explanation: result.explanation,
              options: result.options
                  .where((option) => option.label.trim().isNotEmpty)
                  .map(
                    (option) => {
                      'label': option.label.trim(),
                      'isCorrect': option.isCorrect,
                    },
                  )
                  .toList(),
            );
        await widget.refreshUnit();
        widget.onToast('Question added');
      },
    );
  }

  Future<void> _editQuestion(AdminQuizQuestion question) async {
    final result = await showAppDialog<_QuestionFormResult>(
      context: context,
      useRootNavigator: true,
      builder: (context) => _QuestionFormDialog(
        mode: _QuestionFormMode.edit,
        initialQuestion: question,
      ),
    );
    if (result == null) return;
    await _run(
      action: () async {
        await ref
            .read(adminAssessmentFinalExamActionsProvider.notifier)
            .updateAdminQuizQuestion(
              questionId: question.id,
              prompt: result.prompt,
              points: result.points,
              explanation: result.explanation,
            );
        await widget.refreshUnit();
        widget.onToast('Question updated');
      },
    );
  }

  Future<void> _deleteQuestion(AdminQuizQuestion question) async {
    final confirm = await showAppDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (context) => AlertDialog(
        title: const Text('Delete Question'),
        content: Text(
          'Delete this question?\n\n${_trimInline(question.prompt)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _run(
      action: () async {
        await ref
            .read(adminAssessmentFinalExamActionsProvider.notifier)
            .deleteAdminQuizQuestion(question.id);
        await widget.refreshUnit();
        widget.onToast('Question deleted');
      },
    );
  }

  Future<void> _createOption(AdminQuizQuestion question) async {
    if (question.questionType == 'short_answer') {
      widget.onToast('Short answer questions do not support options');
      return;
    }
    final result = await showAppDialog<_OptionFormResult>(
      context: context,
      useRootNavigator: true,
      builder: (context) => const _OptionFormDialog(),
    );
    if (result == null) return;
    await _run(
      action: () async {
        await ref
            .read(adminAssessmentFinalExamActionsProvider.notifier)
            .createAdminQuizOption(
              questionId: question.id,
              label: result.label,
              isCorrect: result.isCorrect,
            );
        await widget.refreshUnit();
        widget.onToast('Option added');
      },
    );
  }

  Future<void> _editOption(AdminQuizOption option) async {
    final result = await showAppDialog<_OptionFormResult>(
      context: context,
      useRootNavigator: true,
      builder: (context) => _OptionFormDialog(initial: option),
    );
    if (result == null) return;
    await _run(
      action: () async {
        await ref
            .read(adminAssessmentFinalExamActionsProvider.notifier)
            .updateAdminQuizOption(
              optionId: option.id,
              label: result.label,
              isCorrect: result.isCorrect,
            );
        await widget.refreshUnit();
        widget.onToast('Option updated');
      },
    );
  }

  Future<void> _deleteOption(AdminQuizOption option) async {
    await _run(
      action: () async {
        await ref
            .read(adminAssessmentFinalExamActionsProvider.notifier)
            .deleteAdminQuizOption(option.id);
        await widget.refreshUnit();
        widget.onToast('Option deleted');
      },
    );
  }

  Future<void> _run({required Future<void> Function() action}) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      widget.onToast(AppToast.errorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quiz = _quiz;
    return GlassPanel(
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Assessment Editor',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (quiz == null)
                FilledButton.icon(
                  onPressed: _busy ? null : _createQuiz,
                  icon: const Icon(Icons.add),
                  label: const Text('Create Quiz'),
                )
              else ...[
                PopupMenuButton<String>(
                  enabled: !_busy,
                  useRootNavigator: true,
                  onSelected: (value) {
                    if (value == 'edit') _editQuiz(quiz);
                    if (value == 'delete') _deleteQuiz(quiz);
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit Quiz')),
                    PopupMenuItem(value: 'delete', child: Text('Delete Quiz')),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (quiz == null)
            _EmptyEditorState(
              title: 'No assessment yet',
              message: 'Start by creating the quiz for this assessment unit.',
              actionLabel: 'Create Quiz',
              onPressed: _createQuiz,
            )
          else ...[
            Text(
              'Assessment Info',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quiz.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(label: Text('Passing ${quiz.passingScore}%')),
                        Chip(
                          label: Text(
                            '${(quiz.timeLimitSeconds / 60).round()} min',
                          ),
                        ),
                        Chip(label: Text('${quiz.questions.length} questions')),
                        if (quiz.randomizeQuestions)
                          const Chip(label: Text('Randomize Questions')),
                        if (quiz.randomizeOptions)
                          const Chip(label: Text('Randomize Options')),
                      ],
                    ),
                    if (quiz.instructions.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        quiz.instructions,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Questions',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: _busy ? null : () => _createQuestion(quiz),
                  icon: const Icon(Icons.add),
                  label: Text(
                    quiz.questions.isEmpty ? 'Create Question' : 'Add Question',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (quiz.questions.isEmpty)
              Text(
                'No questions yet',
                style: Theme.of(context).textTheme.titleMedium,
              )
            else
              ...quiz.questions.map((question) {
                final expanded = _expandedQuestionId == question.id;
                return _QuestionCard(
                  title: 'Question ${question.position}',
                  subtitle:
                      '${question.questionType.replaceAll('_', ' ')} • ${question.points} pts',
                  promptMarkdown: question.prompt,
                  explanationMarkdown: question.explanation,
                  expanded: expanded,
                  onToggle: () {
                    setState(() {
                      _expandedQuestionId = expanded ? null : question.id;
                    });
                  },
                  actions: [
                    _CardAction(
                      label: 'Edit',
                      icon: Icons.edit_outlined,
                      onTap: _busy ? null : () => _editQuestion(question),
                    ),
                    _CardAction(
                      label: 'Add Option',
                      icon: Icons.add_circle_outline,
                      onTap: _busy ? null : () => _createOption(question),
                    ),
                    _CardAction(
                      label: 'Delete',
                      icon: Icons.delete_outline,
                      destructive: true,
                      onTap: _busy ? null : () => _deleteQuestion(question),
                    ),
                  ],
                  child: Column(
                    children: question.options.isEmpty
                        ? const [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text('No options yet.'),
                            ),
                          ]
                        : question.options.map((option) {
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                option.isCorrect
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: option.isCorrect ? Colors.green : null,
                              ),
                              title: MarkdownBody(
                                data: option.label,
                                shrinkWrap: true,
                                selectable: true,
                              ),
                              trailing: PopupMenuButton<String>(
                                enabled: !_busy,
                                useRootNavigator: true,
                                onSelected: (value) {
                                  if (value == 'edit') _editOption(option);
                                  if (value == 'delete') _deleteOption(option);
                                },
                                itemBuilder: (context) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit Option'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete Option'),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                  ),
                );
              }),
          ],
        ],
      ),
    );
  }
}

class _AdminFinalExamEditor extends ConsumerStatefulWidget {
  const _AdminFinalExamEditor({
    required this.unit,
    required this.onToast,
    required this.refreshUnit,
  });

  final AdminUnitDetail unit;
  final void Function(String message) onToast;
  final Future<AdminUnitDetail> Function() refreshUnit;

  @override
  ConsumerState<_AdminFinalExamEditor> createState() =>
      _AdminFinalExamEditorState();
}

class _AdminFinalExamEditorState extends ConsumerState<_AdminFinalExamEditor> {
  bool _busy = false;
  String? _expandedQuestionId;

  AdminFinalExam? get _finalExam => widget.unit.finalExam;

  String get _finalExamUnitId => widget.unit.id;

  Future<void> _createQuestion() async {
    final result = await showAppDialog<_QuestionFormResult>(
      context: context,
      useRootNavigator: true,
      builder: (context) =>
          const _QuestionFormDialog(mode: _QuestionFormMode.create),
    );
    if (result == null) return;
    await _run(
      action: () async {
        await ref
            .read(adminAssessmentFinalExamActionsProvider.notifier)
            .createAdminFinalExamQuestion(
              unitId: _finalExamUnitId,
              prompt: result.prompt,
              points: result.points,
              explanation: result.explanation,
              options: result.options
                  .where((option) => option.label.trim().isNotEmpty)
                  .map(
                    (option) => {
                      'label': option.label.trim(),
                      'isCorrect': option.isCorrect,
                    },
                  )
                  .toList(),
            );
        await widget.refreshUnit();
        widget.onToast('Question added');
      },
    );
  }

  Future<void> _editQuestion(AdminFinalExamQuestionComponent question) async {
    final result = await showAppDialog<_QuestionFormResult>(
      context: context,
      useRootNavigator: true,
      builder: (context) => _QuestionFormDialog(
        mode: _QuestionFormMode.edit,
        initialQuestion: question,
      ),
    );
    if (result == null) return;
    await _run(
      action: () async {
        await ref
            .read(adminAssessmentFinalExamActionsProvider.notifier)
            .updateAdminFinalExamQuestion(
              unitId: _finalExamUnitId,
              questionId: question.id,
              prompt: result.prompt,
              points: result.points,
              explanation: result.explanation,
            );
        await widget.refreshUnit();
        widget.onToast('Question updated');
      },
    );
  }

  Future<void> _deleteQuestion(AdminFinalExamQuestionComponent question) async {
    final confirm = await showAppDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (context) => AlertDialog(
        title: const Text('Delete Question'),
        content: Text(
          'Delete this question?\n\n${_trimInline(question.prompt)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _run(
      action: () async {
        await ref
            .read(adminAssessmentFinalExamActionsProvider.notifier)
            .deleteAdminFinalExamQuestion(
              unitId: _finalExamUnitId,
              questionId: question.id,
            );
        await widget.refreshUnit();
        widget.onToast('Question deleted');
      },
    );
  }

  Future<void> _createOption(AdminFinalExamQuestionComponent question) async {
    final result = await showAppDialog<_OptionFormResult>(
      context: context,
      useRootNavigator: true,
      builder: (context) => const _OptionFormDialog(),
    );
    if (result == null) return;
    await _run(
      action: () async {
        await ref
            .read(adminAssessmentFinalExamActionsProvider.notifier)
            .createAdminFinalExamOption(
              unitId: _finalExamUnitId,
              questionId: question.id,
              label: result.label,
              isCorrect: result.isCorrect,
            );
        await widget.refreshUnit();
        widget.onToast('Option added');
      },
    );
  }

  Future<void> _editOption(
    AdminFinalExamQuestionComponent question,
    AdminQuizOption option,
  ) async {
    final result = await showAppDialog<_OptionFormResult>(
      context: context,
      useRootNavigator: true,
      builder: (context) => _OptionFormDialog(initial: option),
    );
    if (result == null) return;
    await _run(
      action: () async {
        await ref
            .read(adminAssessmentFinalExamActionsProvider.notifier)
            .updateAdminFinalExamOption(
              unitId: _finalExamUnitId,
              questionId: question.id,
              optionId: option.id,
              label: result.label,
              isCorrect: result.isCorrect,
            );
        await widget.refreshUnit();
        widget.onToast('Option updated');
      },
    );
  }

  Future<void> _deleteOption(
    AdminFinalExamQuestionComponent question,
    AdminQuizOption option,
  ) async {
    await _run(
      action: () async {
        await ref
            .read(adminAssessmentFinalExamActionsProvider.notifier)
            .deleteAdminFinalExamOption(
              unitId: _finalExamUnitId,
              questionId: question.id,
              optionId: option.id,
            );
        await widget.refreshUnit();
        widget.onToast('Option deleted');
      },
    );
  }

  Future<void> _run({required Future<void> Function() action}) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      widget.onToast(AppToast.errorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final finalExam = _finalExam;
    final questions =
        finalExam?.components ?? const <AdminFinalExamQuestionComponent>[];
    return GlassPanel(
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Final Exam Editor',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (finalExam != null) ...[
            Text(
              'Final Exam Info',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: .infinity,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      _StatBlock(label: 'Title', value: finalExam.title),
                      _StatBlock(
                        label: 'Passing Score',
                        value: '${finalExam.passingScore}%',
                      ),
                      _StatBlock(
                        label: 'Max Attempts',
                        value: '${finalExam.maxAttempts}',
                      ),
                      _StatBlock(
                        label: 'Time Limit',
                        value:
                            '${(finalExam.timeLimitSeconds / 60).round()} min',
                      ),
                      _StatBlock(
                        label: 'Questions',
                        value: '${questions.length}',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: Text(
                  'Questions',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: _busy ? null : _createQuestion,
                icon: const Icon(Icons.add),
                label: Text(
                  questions.isEmpty ? 'Create Question' : 'Add Question',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (questions.isEmpty)
            Text(
              'No questions yet',
              style: Theme.of(context).textTheme.titleMedium,
            )
          else
            ...questions.map((question) {
              final expanded = _expandedQuestionId == question.id;
              return _QuestionCard(
                title: 'Question ${question.position}',
                subtitle:
                    '${question.questionType.replaceAll('_', ' ')} • ${question.points} pts',
                promptMarkdown: question.prompt,
                explanationMarkdown: question.explanation,
                expanded: expanded,
                onToggle: () {
                  setState(() {
                    _expandedQuestionId = expanded ? null : question.id;
                  });
                },
                actions: [
                  _CardAction(
                    label: 'Edit',
                    icon: Icons.edit_outlined,
                    onTap: _busy ? null : () => _editQuestion(question),
                  ),
                  _CardAction(
                    label: 'Add Option',
                    icon: Icons.add_circle_outline,
                    onTap: _busy ? null : () => _createOption(question),
                  ),
                  _CardAction(
                    label: 'Delete',
                    icon: Icons.delete_outline,
                    destructive: true,
                    onTap: _busy ? null : () => _deleteQuestion(question),
                  ),
                ],
                child: Column(
                  children: question.options.isEmpty
                      ? const [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text('No options yet.'),
                          ),
                        ]
                      : question.options.map((option) {
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              option.isCorrect
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: option.isCorrect ? Colors.green : null,
                            ),
                            title: MarkdownBody(
                              data: option.label,
                              shrinkWrap: true,
                              selectable: true,
                            ),
                            trailing: PopupMenuButton<String>(
                              enabled: !_busy,
                              useRootNavigator: true,
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _editOption(question, option);
                                }
                                if (value == 'delete') {
                                  _deleteOption(question, option);
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit Option'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete Option'),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.title,
    required this.subtitle,
    required this.promptMarkdown,
    required this.explanationMarkdown,
    required this.expanded,
    required this.onToggle,
    required this.actions,
    required this.child,
  });

  final String title;
  final String subtitle;
  final String promptMarkdown;
  final String explanationMarkdown;
  final bool expanded;
  final VoidCallback onToggle;
  final List<_CardAction> actions;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onToggle,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(subtitle),
                      ],
                    ),
                  ),
                  Icon(expanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
            const SizedBox(height: 10),
            MarkdownBody(data: promptMarkdown, selectable: true),
            if (explanationMarkdown.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Explanation',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 6),
              MarkdownBody(data: explanationMarkdown, selectable: true),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: actions
                  .map(
                    (action) => action.destructive
                        ? OutlinedButton.icon(
                            onPressed: action.onTap,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            icon: Icon(action.icon, size: 18),
                            label: Text(action.label),
                          )
                        : FilledButton.tonalIcon(
                            onPressed: action.onTap,
                            icon: Icon(action.icon, size: 18),
                            label: Text(action.label),
                          ),
                  )
                  .toList(),
            ),
            if (expanded) ...[const SizedBox(height: 12), child],
          ],
        ),
      ),
    );
  }
}

class _EmptyEditorState extends StatelessWidget {
  const _EmptyEditorState({
    required this.title,
    required this.message,
    this.actionLabel,
    this.onPressed,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(message, style: Theme.of(context).textTheme.bodyMedium),
            if (actionLabel != null && onPressed != null) ...[
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CardAction {
  const _CardAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.destructive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool destructive;
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

enum _QuestionFormMode { create, edit }

class _QuizFormResult {
  const _QuizFormResult({
    required this.title,
    required this.instructions,
    required this.passingScore,
    required this.timeLimitSeconds,
    required this.randomizeQuestions,
    required this.randomizeOptions,
  });

  final String title;
  final String instructions;
  final int passingScore;
  final int timeLimitSeconds;
  final bool randomizeQuestions;
  final bool randomizeOptions;
}

class _QuestionDraftOption {
  const _QuestionDraftOption({required this.label, required this.isCorrect});

  final String label;
  final bool isCorrect;
}

class _QuestionFormResult {
  const _QuestionFormResult({
    required this.prompt,
    required this.explanation,
    required this.points,
    required this.options,
  });

  final String prompt;
  final String explanation;
  final int points;
  final List<_QuestionDraftOption> options;
}

class _OptionFormResult {
  const _OptionFormResult({required this.label, required this.isCorrect});

  final String label;
  final bool isCorrect;
}

class _QuizFormDialog extends StatefulWidget {
  const _QuizFormDialog({this.initial});

  final AdminQuiz? initial;

  @override
  State<_QuizFormDialog> createState() => _QuizFormDialogState();
}

class _QuizFormDialogState extends State<_QuizFormDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _instructionsController;
  late final TextEditingController _passingScoreController;
  late final TextEditingController _timeLimitController;
  late bool _randomizeQuestions;
  late bool _randomizeOptions;
  String? _error;

  @override
  void initState() {
    super.initState();
    final quiz = widget.initial;
    _titleController = TextEditingController(text: quiz?.title ?? '');
    _instructionsController = TextEditingController(
      text: quiz?.instructions ?? '',
    );
    _passingScoreController = TextEditingController(
      text: (quiz?.passingScore ?? 70).toString(),
    );
    _timeLimitController = TextEditingController(
      text: (quiz?.timeLimitSeconds ?? 3600).toString(),
    );
    _randomizeQuestions = quiz?.randomizeQuestions ?? false;
    _randomizeOptions = quiz?.randomizeOptions ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _instructionsController.dispose();
    _passingScoreController.dispose();
    _timeLimitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Create Quiz' : 'Edit Quiz'),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title *'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _instructionsController,
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(labelText: 'Instructions'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passingScoreController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Passing Score *'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _timeLimitController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Time Limit Seconds *',
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                value: _randomizeQuestions,
                onChanged: (value) {
                  setState(() => _randomizeQuestions = value);
                },
                title: const Text('Randomize Questions'),
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                value: _randomizeOptions,
                onChanged: (value) {
                  setState(() => _randomizeOptions = value);
                },
                title: const Text('Randomize Options'),
                contentPadding: EdgeInsets.zero,
              ),
              if (_error != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final title = _titleController.text.trim();
            final passing = int.tryParse(_passingScoreController.text);
            final seconds = int.tryParse(_timeLimitController.text);
            if (title.isEmpty) {
              setState(() => _error = 'Title is required.');
              return;
            }
            if (passing == null || passing < 0 || passing > 100) {
              setState(
                () => _error = 'Passing score must be between 0 and 100.',
              );
              return;
            }
            if (seconds == null || seconds < 1) {
              setState(() => _error = 'Time limit must be greater than 0.');
              return;
            }
            Navigator.of(context).pop(
              _QuizFormResult(
                title: title,
                instructions: _instructionsController.text,
                passingScore: passing,
                timeLimitSeconds: seconds,
                randomizeQuestions: _randomizeQuestions,
                randomizeOptions: _randomizeOptions,
              ),
            );
          },
          child: Text(widget.initial == null ? 'Create' : 'Save'),
        ),
      ],
    );
  }
}

class _QuestionFormDialog extends StatefulWidget {
  const _QuestionFormDialog({required this.mode, this.initialQuestion});

  final _QuestionFormMode mode;
  final dynamic initialQuestion;

  @override
  State<_QuestionFormDialog> createState() => _QuestionFormDialogState();
}

class _QuestionFormDialogState extends State<_QuestionFormDialog> {
  late final TextEditingController _promptController;
  late final TextEditingController _explanationController;
  late final TextEditingController _pointsController;
  final List<_DraftOptionRow> _options = [];
  String? _error;

  bool get _isCreate => widget.mode == _QuestionFormMode.create;

  @override
  void initState() {
    super.initState();
    final question = widget.initialQuestion;
    _promptController = TextEditingController(text: question?.prompt ?? '');
    _explanationController = TextEditingController(
      text: question?.explanation ?? '',
    );
    _pointsController = TextEditingController(
      text: '${question?.points ?? (_isCreate ? 1 : 10)}',
    );
    if (_isCreate) {
      _options.add(_DraftOptionRow());
      _options.add(_DraftOptionRow(isCorrect: true));
    }
  }

  @override
  void dispose() {
    for (final option in _options) {
      option.controller.dispose();
    }
    _promptController.dispose();
    _explanationController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isCreate ? 'Add Question' : 'Edit Question'),
      content: SizedBox(
        width: 720,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _promptController,
                minLines: 8,
                maxLines: 14,
                decoration: const InputDecoration(
                  labelText: 'Prompt (Markdown) *',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _explanationController,
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Explanation (Markdown)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _pointsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Points *'),
              ),
              if (_isCreate) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Draft Options',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () {
                        setState(() => _options.add(_DraftOptionRow()));
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Option'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._options.asMap().entries.map((entry) {
                  final index = entry.key;
                  final option = entry.value;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        children: [
                          TextField(
                            controller: option.controller,
                            minLines: 2,
                            maxLines: 4,
                            decoration: InputDecoration(
                              labelText: 'Option ${index + 1} *',
                            ),
                          ),
                          CheckboxListTile(
                            value: option.isCorrect,
                            onChanged: (value) {
                              setState(() => option.isCorrect = value == true);
                            },
                            title: const Text('Correct'),
                            contentPadding: EdgeInsets.zero,
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: _options.length <= 1
                                  ? null
                                  : () {
                                      setState(() {
                                        option.controller.dispose();
                                        _options.removeAt(index);
                                      });
                                    },
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Remove'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
              if (_error != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final prompt = _promptController.text.trim();
            final points = int.tryParse(_pointsController.text);
            if (prompt.isEmpty) {
              setState(() => _error = 'Prompt is required.');
              return;
            }
            if (points == null || points < 1) {
              setState(() => _error = 'Points must be at least 1.');
              return;
            }
            Navigator.of(context).pop(
              _QuestionFormResult(
                prompt: _promptController.text,
                explanation: _explanationController.text,
                points: points,
                options: _options
                    .map(
                      (option) => _QuestionDraftOption(
                        label: option.controller.text,
                        isCorrect: option.isCorrect,
                      ),
                    )
                    .toList(),
              ),
            );
          },
          child: Text(_isCreate ? 'Create' : 'Save'),
        ),
      ],
    );
  }
}

class _DraftOptionRow {
  _DraftOptionRow({String text = '', this.isCorrect = false})
    : controller = TextEditingController(text: text);

  final TextEditingController controller;
  bool isCorrect;
}

class _OptionFormDialog extends StatefulWidget {
  const _OptionFormDialog({this.initial});

  final AdminQuizOption? initial;

  @override
  State<_OptionFormDialog> createState() => _OptionFormDialogState();
}

class _OptionFormDialogState extends State<_OptionFormDialog> {
  late final TextEditingController _labelController;
  late bool _isCorrect;
  String? _error;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.initial?.label ?? '');
    _isCorrect = widget.initial?.isCorrect ?? false;
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Add Option' : 'Edit Option'),
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _labelController,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Option Label (Markdown) *',
                alignLabelWithHint: true,
              ),
            ),
            CheckboxListTile(
              value: _isCorrect,
              onChanged: (value) {
                setState(() => _isCorrect = value == true);
              },
              title: const Text('Correct'),
              contentPadding: EdgeInsets.zero,
            ),
            if (_error != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final label = _labelController.text.trim();
            if (label.isEmpty) {
              setState(() => _error = 'Label is required.');
              return;
            }
            Navigator.of(context).pop(
              _OptionFormResult(
                label: _labelController.text,
                isCorrect: _isCorrect,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

String _trimInline(String text) {
  final normalized = text.replaceAll('\n', ' ').trim();
  if (normalized.length <= 64) return normalized;
  return '${normalized.substring(0, 64)}...';
}
