import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponzey_file_sharing/app/theme/app_colors.dart';
import 'package:sponzey_file_sharing/app/theme/app_spacing.dart';
import 'package:sponzey_file_sharing/application/auth/peer_auth_controller.dart';
import 'package:sponzey_file_sharing/application/discovery/discovery_controller.dart';
import 'package:sponzey_file_sharing/application/discovery/discovery_overview_provider.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_overview_provider.dart';
import 'package:sponzey_file_sharing/domain/entities/peer_node.dart';
import 'package:sponzey_file_sharing/presentation/shared/page_header.dart';
import 'package:sponzey_file_sharing/presentation/shared/sponzey_card.dart';
import 'package:sponzey_file_sharing/presentation/shared/sponzey_scroll_cue.dart';
import 'package:sponzey_file_sharing/presentation/shared/status_badge.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  static const routeName = 'dashboard';
  static const routePath = '/dashboard';

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final discoveryState = ref.watch(discoveryControllerProvider);
    final overview = ref.watch(discoveryOverviewProvider);
    final authSessions = ref.watch(peerAuthControllerProvider).sessions;
    final jobs = ref.watch(transferJobsProvider);
    final activeJobs = ref.watch(activeTransferJobsProvider);
    final recentPeers = overview.peers.take(4).map((peer) {
      final session = authSessions[peer.id];
      if (session?.isAuthenticated != true) {
        return peer;
      }
      return peer.copyWith(
        address: session!.peerAddress,
        port: session.peerPort,
        presence: PeerPresence.online,
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Dashboard',
          description: '현재 워크스페이스의 discovery 상태와 전송 큐를 한 번에 확인합니다.',
          trailing: StatusBadge(
            label: discoveryState.isRunning ? 'Discovery Live' : 'Idle',
            backgroundColor: discoveryState.isRunning
                ? AppColors.successSoft
                : AppColors.warningSoft,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: SponzeyScrollCue(
            controller: _scrollController,
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                0,
                AppSpacing.xl,
                AppSpacing.xl,
              ),
              children: [
                Wrap(
                  spacing: AppSpacing.lg,
                  runSpacing: AppSpacing.lg,
                  children: [
                    _MetricCard(label: '내 기기', value: '켜짐'),
                    _MetricCard(
                      label: '보낼 기기',
                      value: '${overview.onlineCount}개',
                    ),
                    _MetricCard(label: '전송 중', value: '${activeJobs.length}개'),
                    const _SendShortcutCard(),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SponzeyCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recent Peers',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            if (recentPeers.isEmpty)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.hub_rounded),
                                title: const Text('발견된 피어가 없습니다'),
                                subtitle: Text(
                                  '같은 ID/PW 인스턴스를 기다리는 중 · '
                                  'transport ${discoveryState.discoveryTransportMode ?? '-'} · '
                                  'rx ${discoveryState.discoveryReceivePort ?? '-'} · '
                                  'targets ${discoveryState.discoveryBroadcastTargetCount}',
                                ),
                              ),
                            for (final peer in recentPeers) ...[
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.devices_rounded),
                                title: Text(peer.displayName),
                                subtitle: Text(
                                  '${peer.deviceName} • ${peer.address}',
                                ),
                                trailing: StatusBadge(
                                  label: peer.statusLabel,
                                  backgroundColor: _peerBadgeColor(peer),
                                ),
                              ),
                              const Divider(height: 1),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: SponzeyCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Queue Snapshot',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            if (jobs.isEmpty)
                              const ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(Icons.local_shipping_rounded),
                                title: Text('진행 중인 전송이 없습니다'),
                                subtitle: Text(
                                  'Transfers 화면에서 인증된 피어에게 파일을 보낼 수 있습니다',
                                ),
                              ),
                            for (final job in jobs) ...[
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(
                                  Icons.local_shipping_rounded,
                                ),
                                title: Text(job.title),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: LinearProgressIndicator(
                                    value: job.progress,
                                    minHeight: 10,
                                    color: AppColors.techBlue,
                                    backgroundColor: AppColors.techBorder,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                                trailing: StatusBadge(label: job.statusLabel),
                              ),
                              const Divider(height: 1),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

Color _peerBadgeColor(PeerNode peer) {
  switch (peer.presence) {
    case PeerPresence.online:
      return AppColors.successSoft;
    case PeerPresence.stale:
      return AppColors.warningSoft;
    case PeerPresence.offline:
      return AppColors.dangerSoft;
    case PeerPresence.incompatible:
      return AppColors.infoSoft;
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: SponzeyCard(
        backgroundColor: AppColors.paper,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _metricDotColor(label),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(label, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(value, style: Theme.of(context).textTheme.displayMedium),
          ],
        ),
      ),
    );
  }
}

class _SendShortcutCard extends StatelessWidget {
  const _SendShortcutCard();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: SponzeyCard(
        backgroundColor: AppColors.techDark,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '파일 보내기',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(color: AppColors.paper),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '기기를 고르고 바로 전송',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.techTextOnDark),
            ),
          ],
        ),
      ),
    );
  }
}

Color _metricDotColor(String label) {
  return switch (label) {
    '내 기기' => AppColors.techGreen,
    '보낼 기기' => AppColors.techBlue,
    '전송 중' => AppColors.techCyan,
    _ => AppColors.techTextMuted,
  };
}
