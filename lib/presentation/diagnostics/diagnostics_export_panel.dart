import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponzey_file_sharing/app/theme/app_spacing.dart';
import 'package:sponzey_file_sharing/application/diagnostics/diagnostics_export_controller.dart';
import 'package:sponzey_file_sharing/application/diagnostics/diagnostics_export_provider.dart';
import 'package:sponzey_file_sharing/core/diagnostics/diagnostics_redactor.dart';

class DiagnosticsExportPanel extends ConsumerWidget {
  const DiagnosticsExportPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bundle = ref.watch(diagnosticsExportBundleProvider);
    final exportState = ref.watch(diagnosticsExportControllerProvider);
    final json = bundle.toPrettyJson();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: AppSpacing.xl),
        Text(
          'Diagnostics Export',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '민감정보가 제거된 product/debug/environment/development 스냅샷입니다.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: exportState.isSaving
                  ? null
                  : () => ref
                        .read(diagnosticsExportControllerProvider.notifier)
                        .saveCurrentBundle(),
              icon: const Icon(Icons.file_download_rounded),
              label: Text(exportState.isSaving ? '저장 중...' : 'Export 파일 저장'),
            ),
            if (exportState.lastSavedPath != null)
              Text(
                '저장됨: ${DiagnosticsRedactor.safePath(exportState.lastSavedPath)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (exportState.errorMessage != null)
              Text(
                exportState.errorMessage!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.red),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFFAF7EB),
            border: Border.all(color: const Color(0xFF1E1E1E), width: 1),
            borderRadius: BorderRadius.circular(18),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 260,
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: SelectableText(
                  json,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    height: 1.35,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
