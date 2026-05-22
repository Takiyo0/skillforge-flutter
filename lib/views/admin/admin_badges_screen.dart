import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skillforgeapp/config/asset_urls.dart';
import 'package:skillforgeapp/models/admin/admin_models.dart';
import 'package:skillforgeapp/ui/design_system.dart';
import 'package:skillforgeapp/view_models/admin/admin_badges_view_model.dart';

class AdminBadgesPage extends ConsumerStatefulWidget {
  const AdminBadgesPage({super.key});

  @override
  ConsumerState<AdminBadgesPage> createState() => _AdminBadgesPageState();
}

class _AdminBadgesPageState extends ConsumerState<AdminBadgesPage> {
  List<AdminBadge> _badges = const [];
  List<BadgeCriteriaMetadata> _metadata = const [];
  bool _loading = true;
  bool _busy = false;
  String? _error;

  String _query = '';
  String _criteriaFilter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(adminBadgesActionsProvider.notifier);
      final badges = await repo.getAllBadges();
      final metadata = await repo.getBadgeCriteriaMetadata();
      setState(() {
        _badges = badges;
        _metadata = metadata;
      });
    } catch (e) {
      setState(
        () => _error = 'Failed to load badges: ${AppToast.errorMessage(e)}',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(String message) {
    AppToast.show(context, message);
  }

  List<AdminBadge> get _filtered {
    final q = _query.trim().toLowerCase();
    return _badges.where((badge) {
      final matchesFilter =
          _criteriaFilter == 'all' || badge.criteria.type == _criteriaFilter;
      if (!matchesFilter) return false;
      if (q.isEmpty) return true;
      final criteriaText = badge.criteria.type == 'first_course'
          ? (badge.criteria.language ?? '')
          : '${badge.criteria.xp ?? ''}';
      return badge.name.toLowerCase().contains(q) ||
          badge.code.toLowerCase().contains(q) ||
          badge.description.toLowerCase().contains(q) ||
          criteriaText.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _deleteBadge(AdminBadge badge) async {
    final confirm = await showAppDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (context) => AlertDialog(
        title: const Text('Delete Badge'),
        content: Text('Delete "${badge.name}"? This cannot be undone.'),
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
    setState(() => _busy = true);
    try {
      await ref.read(adminBadgesActionsProvider.notifier).deleteBadge(badge.id);
      if (!mounted) return;
      setState(() => _badges = _badges.where((b) => b.id != badge.id).toList());
      _toast('Badge deleted');
    } catch (e) {
      _toast('Failed to delete badge: ${AppToast.errorMessage(e)}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openBadgeForm([AdminBadge? editing]) async {
    final result = await showAppDialog<_BadgeFormResult>(
      context: context,
      useRootNavigator: true,
      builder: (context) =>
          _BadgeFormDialog(metadata: _metadata, initial: editing),
    );
    if (result == null) return;

    setState(() => _busy = true);
    try {
      final repo = ref.read(adminBadgesActionsProvider.notifier);
      AdminBadge badge;
      if (editing == null) {
        badge = await repo.createBadge(
          code: result.code,
          name: result.name,
          description: result.description,
          criteriaType: result.criteriaType,
          language: result.criteriaType == 'first_course'
              ? result.language
              : null,
          xp: result.criteriaType == 'xp_milestone' ? result.xp : null,
        );
      } else {
        badge = await repo.updateBadge(
          badgeId: editing.id,
          code: result.code,
          name: result.name,
          description: result.description,
          iconS3Key: editing.iconS3Key,
          criteriaType: result.criteriaType,
          language: result.criteriaType == 'first_course'
              ? result.language
              : null,
          xp: result.criteriaType == 'xp_milestone' ? result.xp : null,
        );
      }

      if (result.fileBytes != null && result.fileName != null) {
        badge = await repo.uploadBadgeIcon(
          badgeId: badge.id,
          fileName: result.fileName!,
          bytes: result.fileBytes!,
          contentType: _badgeMimeType(result.fileName!),
        );
      }

      if (!mounted) return;
      if (editing == null) {
        setState(() => _badges = [..._badges, badge]);
      } else {
        setState(() {
          _badges = _badges.map((b) => b.id == editing.id ? badge : b).toList();
        });
      }
      _toast(editing == null ? 'Badge created' : 'Badge updated');
      await _load();
    } catch (e) {
      _toast('Failed to save badge: ${AppToast.errorMessage(e)}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstCourseCount = _badges
        .where((badge) => badge.criteria.type == 'first_course')
        .length;
    final xpCount = _badges
        .where((badge) => badge.criteria.type == 'xp_milestone')
        .length;

    return AppPage(
      title: 'Badges',
      subtitle: 'Badge catalog and criteria',
      child: ListView(
        children: [
          Row(
            spacing: 8,
            children: [
              _BadgeStat(label: 'Total Badges', value: '${_badges.length}'),
              _BadgeStat(label: 'First Course', value: '$firstCourseCount'),
              _BadgeStat(label: 'XP Milestones', value: '$xpCount'),
            ],
          ),
          const SizedBox(height: 10),
          GlassPanel(
            radius: 18,
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search badges',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _criteriaFilter,
                  decoration: const InputDecoration(labelText: 'Criteria'),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All')),
                    DropdownMenuItem(
                      value: 'first_course',
                      child: Text('First course'),
                    ),
                    DropdownMenuItem(
                      value: 'xp_milestone',
                      child: Text('XP milestone'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _criteriaFilter = value ?? 'all'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : _load,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _busy || _metadata.isEmpty
                            ? null
                            : () => _openBadgeForm(),
                        icon: const Icon(Icons.add),
                        label: const Text('New Badge'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (_error != null)
            GlassPanel(
              radius: 18,
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            )
          else if (_loading)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_filtered.isEmpty)
            const GlassPanel(
              radius: 18,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(
                  child: Text('No badges match the current filters'),
                ),
              ),
            )
          else
            ..._filtered.map(
              (badge) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _BadgeCard(
                  badge: badge,
                  disabled: _busy,
                  onEdit: () => _openBadgeForm(badge),
                  onDelete: () => _deleteBadge(badge),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BadgeStat extends StatelessWidget {
  const _BadgeStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassPanel(
        radius: 16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({
    required this.badge,
    required this.disabled,
    required this.onEdit,
    required this.onDelete,
  });

  final AdminBadge badge;
  final bool disabled;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      badge.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      badge.code,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              _BadgeIconPreview(iconS3Key: badge.iconS3Key, id: badge.id),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            badge.description.isEmpty ? 'No description' : badge.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Chip(label: Text(_criteriaText(badge))),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: disabled ? null : onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit'),
              ),
              OutlinedButton.icon(
                onPressed: disabled ? null : onDelete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BadgeIconPreview extends StatelessWidget {
  const _BadgeIconPreview({required this.iconS3Key, required this.id});

  final String? iconS3Key;
  final String id;

  @override
  Widget build(BuildContext context) {
    final url = AssetUrls.courseThumbnailUrl(iconS3Key);
    if (url == null) {
      return Text(_badgeEmoji(id), style: const TextStyle(fontSize: 32));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 44,
        height: 44,
        child: Image.network(url, fit: BoxFit.cover),
      ),
    );
  }
}

String _criteriaText(AdminBadge badge) {
  if (badge.criteria.type == 'first_course') {
    return 'First course • ${badge.criteria.language ?? 'n/a'}';
  }
  if (badge.criteria.type == 'xp_milestone') {
    return 'XP milestone • ${badge.criteria.xp ?? 0}';
  }
  return badge.criteria.type;
}

class _BadgeFormResult {
  const _BadgeFormResult({
    required this.code,
    required this.name,
    required this.description,
    required this.criteriaType,
    required this.language,
    required this.xp,
    this.fileName,
    this.fileBytes,
  });

  final String code;
  final String name;
  final String description;
  final String criteriaType;
  final String language;
  final int xp;
  final String? fileName;
  final List<int>? fileBytes;
}

class _BadgeFormDialog extends StatefulWidget {
  const _BadgeFormDialog({required this.metadata, this.initial});

  final List<BadgeCriteriaMetadata> metadata;
  final AdminBadge? initial;

  @override
  State<_BadgeFormDialog> createState() => _BadgeFormDialogState();
}

class _BadgeFormDialogState extends State<_BadgeFormDialog> {
  late final TextEditingController _code;
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _xp;
  String _criteriaType = 'first_course';
  String _language = 'javascript';
  String? _fileName;
  List<int>? _fileBytes;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    final badge = widget.initial;
    _code = TextEditingController(text: badge?.code ?? '');
    _name = TextEditingController(text: badge?.name ?? '');
    _description = TextEditingController(text: badge?.description ?? '');
    _criteriaType =
        badge?.criteria.type ??
        (widget.metadata.isNotEmpty
            ? widget.metadata.first.type
            : 'first_course');
    _language = badge?.criteria.language ?? 'javascript';
    _xp = TextEditingController(text: '${badge?.criteria.xp ?? 1000}');
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _description.dispose();
    _xp.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg'],
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    setState(() {
      _fileName = file.name;
      _fileBytes = file.bytes!;
    });
  }

  @override
  Widget build(BuildContext context) {
    final codeText = _code.text.trim();
    final nameText = _name.text.trim();
    final xpValue = int.tryParse(_xp.text.trim());

    final criteriaMeta = widget.metadata.firstWhere(
      (item) => item.type == _criteriaType,
      orElse: () => widget.metadata.isEmpty
          ? BadgeCriteriaMetadata(
              type: 'first_course',
              label: 'First course',
              description: '',
              fields: const [],
            )
          : widget.metadata.first,
    );
    final languageOptions = widget.metadata
        .where((item) => item.type == 'first_course')
        .expand((item) => item.fields)
        .where((field) => field.key == 'language')
        .expand((field) => field.options)
        .toList();

    return AlertDialog(
      title: Text(widget.initial == null ? 'Create Badge' : 'Edit Badge'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _code,
                decoration: InputDecoration(
                  labelText: 'Code *',
                  errorText: _submitted && codeText.isEmpty
                      ? 'Code is required'
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _name,
                decoration: InputDecoration(
                  labelText: 'Name *',
                  errorText: _submitted && nameText.isEmpty
                      ? 'Name is required'
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _description,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _criteriaType,
                decoration: const InputDecoration(labelText: 'Criteria Type *'),
                items: widget.metadata
                    .map(
                      (meta) => DropdownMenuItem(
                        value: meta.type,
                        child: Text(meta.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _criteriaType = value);
                },
              ),
              const SizedBox(height: 8),
              if (_criteriaType == 'first_course')
                DropdownButtonFormField<String>(
                  value: _language,
                  decoration: const InputDecoration(labelText: 'Language *'),
                  items: languageOptions.isEmpty
                      ? const [
                          DropdownMenuItem(
                            value: 'javascript',
                            child: Text('javascript'),
                          ),
                        ]
                      : languageOptions
                            .map(
                              (opt) => DropdownMenuItem(
                                value: opt.value,
                                child: Text(opt.label),
                              ),
                            )
                            .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _language = value);
                  },
                ),
              if (_criteriaType == 'xp_milestone')
                TextField(
                  controller: _xp,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'XP threshold *',
                    errorText: _submitted && (xpValue == null || xpValue < 1)
                        ? 'XP threshold must be at least 1'
                        : null,
                  ),
                ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  criteriaMeta.description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 10),
              _BadgeUploadPreview(
                existingIconS3Key: widget.initial?.iconS3Key,
                fileName: _fileName,
                fileBytes: _fileBytes,
                badgeId: widget.initial?.id ?? 'new',
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Choose Icon File'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _fileName ?? 'No file selected',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
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
            setState(() => _submitted = true);
            final code = _code.text.trim();
            final name = _name.text.trim();
            final xp = int.tryParse(_xp.text.trim()) ?? 1000;
            if (code.isEmpty ||
                name.isEmpty ||
                (_criteriaType == 'xp_milestone' && xp < 1)) {
              return;
            }

            Navigator.of(context).pop(
              _BadgeFormResult(
                code: code,
                name: name,
                description: _description.text.trim(),
                criteriaType: _criteriaType,
                language: _language,
                xp: xp < 1 ? 1 : xp,
                fileName: _fileName,
                fileBytes: _fileBytes,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

String _badgeEmoji(String seed) {
  const icons = ['🏅', '🎖️', '⭐', '🏆', '🥇', '🌟', '🔰'];
  final hash = seed.runes.fold<int>(0, (a, b) => (a * 31 + b) & 0x7fffffff);
  return icons[hash % icons.length];
}

String? _badgeMimeType(String fileName) {
  final lower = fileName.toLowerCase();
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.gif')) return 'image/gif';
  if (lower.endsWith('.webp')) return 'image/webp';
  return null;
}

class _BadgeUploadPreview extends StatelessWidget {
  const _BadgeUploadPreview({
    required this.existingIconS3Key,
    required this.fileName,
    required this.fileBytes,
    required this.badgeId,
  });

  final String? existingIconS3Key;
  final String? fileName;
  final List<int>? fileBytes;
  final String badgeId;

  @override
  Widget build(BuildContext context) {
    final existingUrl = AssetUrls.courseThumbnailUrl(existingIconS3Key);
    Widget preview;
    if (fileBytes != null) {
      preview = ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.memory(
          Uint8List.fromList(fileBytes!),
          width: 72,
          height: 72,
          fit: BoxFit.cover,
        ),
      );
    } else if (existingUrl != null) {
      preview = ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          existingUrl,
          width: 72,
          height: 72,
          fit: BoxFit.cover,
        ),
      );
    } else {
      preview = Text(
        _badgeEmoji(badgeId),
        style: const TextStyle(fontSize: 44),
      );
    }

    return Row(
      children: [
        Container(
          width: 84,
          height: 84,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.4),
          ),
          child: preview,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            fileName ??
                'Upload an image. If none is uploaded, the badge falls back to emoji.',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
