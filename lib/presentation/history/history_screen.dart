import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponzey_file_sharing/app/theme/app_spacing.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_overview_provider.dart';
import 'package:sponzey_file_sharing/domain/entities/transfer_job.dart';
import 'package:sponzey_file_sharing/domain/transfer/transfer_failure_policy.dart';
import 'package:sponzey_file_sharing/presentation/shared/page_header.dart';
import 'package:sponzey_file_sharing/presentation/shared/sponzey_card.dart';
import 'package:sponzey_file_sharing/presentation/shared/sponzey_scroll_cue.dart';
import 'package:sponzey_file_sharing/presentation/shared/status_badge.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  static const routeName = 'history';
  static const routePath = '/history';

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final historyJobs = ref.watch(transferHistoryJobsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeader(
          title: 'History',
          description: '완료되거나 실패한 단일 파일 전송 결과를 시간순으로 확인합니다.',
        ),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: SponzeyCard(
            child: SponzeyScrollCue(
              controller: _scrollController,
              child: historyJobs.isEmpty
                  ? ListView(
                      controller: _scrollController,
                      children: const [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.history_rounded),
                          title: Text('완료된 전송 이력이 없습니다'),
                          subtitle: Text('Transfers 화면에서 전송을 시작하면 이력이 쌓입니다.'),
                        ),
                      ],
                    )
                  : ListView.separated(
                      controller: _scrollController,
                      itemBuilder: (context, index) {
                        final job = historyJobs[index];
                        return _HistoryTile(job: job);
                      },
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemCount: historyJobs.length,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.job});

  final TransferJob job;

  @override
  Widget build(BuildContext context) {
    final direction = job.direction == TransferDirection.outgoing
        ? 'To'
        : 'From';
    final failureDecision = const TransferFailurePolicy().classify(job);
    final subtitle = [
      '$direction ${job.peerDisplayName}',
      _formatTime(job.updatedAt),
      if (job.destinationPath != null) job.destinationPath!,
      if (job.message != null) job.message!,
      if (job.isTerminal &&
          job.status != TransferJobStatus.completed &&
          failureDecision.userMessage != job.message)
        failureDecision.userMessage,
    ].join(' • ');

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        job.direction == TransferDirection.outgoing
            ? Icons.north_east_rounded
            : Icons.south_west_rounded,
      ),
      title: Text(job.fileName),
      subtitle: Text(subtitle),
      trailing: StatusBadge(label: job.statusLabel),
    );
  }
}

String _formatTime(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
