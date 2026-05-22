import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skillforgeapp/providers/infrastructure_providers.dart';

final sandboxLanguagesViewModelProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final raw = await ref
          .read(skillForgeApiProvider)
          .getSandboxLanguages(includeBaseCode: true);
      return raw
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
    });

class CodePlaygroundActions extends AutoDisposeNotifier<void> {
  @override
  void build() {}

  Future<Map<String, dynamic>> runCode({
    required String code,
    required String language,
    required List<Map<String, String>> testCases,
  }) async {
    return ref
        .read(skillForgeApiProvider)
        .runCodeSandbox(code: code, language: language, testCases: testCases);
  }
}

final codePlaygroundActionsProvider =
    AutoDisposeNotifierProvider<CodePlaygroundActions, void>(
      CodePlaygroundActions.new,
    );
