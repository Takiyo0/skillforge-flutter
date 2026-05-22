import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skillforgeapp/ui/design_system.dart';
import 'package:skillforgeapp/view_models/shared/certificate_view_model.dart';

class CertificateVerificationPage extends ConsumerWidget {
  const CertificateVerificationPage({super.key, this.verificationCode});

  final String? verificationCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (verificationCode == null || verificationCode!.isEmpty) {
      return const AppPage(
        title: 'Certificate Verification',
        child: Center(
          child: Text('Missing verification code in query param `code`.'),
        ),
      );
    }

    final state = ref.watch(
      certificateVerificationViewModelProvider(verificationCode!),
    );

    return AppPage(
      title: 'Certificate Verification',
      subtitle: verificationCode,
      child: state.when(
        data: (data) => ListView(
          children: [
            Card(
              child: ListTile(
                title: Text(
                  (data['isValid'] == true || data['valid'] == true)
                      ? 'Certificate is valid'
                      : 'Certificate status unavailable',
                ),
                subtitle: Text(
                  [
                        if (data['certificateCode'] != null)
                          'Code: ${data['certificateCode']}',
                        if (data['displayName'] != null)
                          'Owner: ${data['displayName']}',
                        if (data['courseTitle'] != null)
                          'Course: ${data['courseTitle']}',
                        if (data['issuedAt'] != null)
                          'Issued: ${data['issuedAt']}',
                      ].join('\n').trim().isEmpty
                      ? 'No additional details returned by server.'
                      : [
                          if (data['certificateCode'] != null)
                            'Code: ${data['certificateCode']}',
                          if (data['displayName'] != null)
                            'Owner: ${data['displayName']}',
                          if (data['courseTitle'] != null)
                            'Course: ${data['courseTitle']}',
                          if (data['issuedAt'] != null)
                            'Issued: ${data['issuedAt']}',
                        ].join('\n'),
                ),
              ),
            ),
          ],
        ),
        loading: AppAsyncState.loading,
        error: (e, _) => AppAsyncState.error('Verification failed: $e'),
      ),
    );
  }
}
