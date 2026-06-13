import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sponzey_file_sharing/app/theme/app_spacing.dart';
import 'package:sponzey_file_sharing/application/auth/auth_controller.dart';
import 'package:sponzey_file_sharing/application/discovery/discovery_controller.dart';
import 'package:sponzey_file_sharing/application/discovery/discovery_overview_provider.dart';
import 'package:sponzey_file_sharing/application/discovery/discovery_sorting.dart';
import 'package:sponzey_file_sharing/application/network/peer_connection_summary_provider.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_controller.dart';
import 'package:sponzey_file_sharing/core/logger/app_logger.dart';
import 'package:sponzey_file_sharing/domain/entities/peer_node.dart';
import 'package:sponzey_file_sharing/presentation/transfers/transfers_screen.dart';
import 'package:sponzey_file_sharing/presentation/shared/page_header.dart';
import 'package:sponzey_file_sharing/presentation/shared/sponzey_card.dart';
import 'package:sponzey_file_sharing/presentation/shared/sponzey_scroll_cue.dart';
import 'package:sponzey_file_sharing/presentation/shared/status_badge.dart';
import 'package:sponzey_file_sharing/presentation/peers/network_path_summary.dart';

class PeersScreen extends ConsumerStatefulWidget {
  const PeersScreen({super.key});

  static const routeName = 'peers';
  static const routePath = '/peers';

  @override
  ConsumerState<PeersScreen> createState() => _PeersScreenState();
}

class _PeersScreenState extends ConsumerState<PeersScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  PeerSortMode _sortMode = PeerSortMode.recent;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final discoveryState = ref.watch(discoveryControllerProvider);
    final overview = ref.watch(discoveryOverviewProvider);
    final peers = filterPeers(
      overview.peers,
      query: _searchController.text,
      sortMode: _sortMode,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Peers',
          description:
              '주변 피어를 자동으로 찾고 핸드셰이크까지 진행합니다. 연결이 완료되면 바로 전송 대상으로 사용할 수 있습니다.',
          trailing: StatusBadge(
            label: discoveryState.isRunning
                ? 'Discovery Live'
                : 'Discovery Idle',
            backgroundColor: discoveryState.isRunning
                ? const Color(0xFFE8F7EE)
                : const Color(0xFFFDEBE8),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SponzeyCard(
          child: Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 280,
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: '피어 검색',
                    hintText: '이름, 기기명, user id, device id',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<PeerSortMode>(
                  initialValue: _sortMode,
                  items: const [
                    DropdownMenuItem(
                      value: PeerSortMode.recent,
                      child: Text('상태 + 최근 응답순'),
                    ),
                    DropdownMenuItem(
                      value: PeerSortMode.name,
                      child: Text('이름순'),
                    ),
                    DropdownMenuItem(
                      value: PeerSortMode.status,
                      child: Text('상태순'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _sortMode = value;
                    });
                  },
                  decoration: const InputDecoration(labelText: '정렬'),
                ),
              ),
              _SummaryPill(label: 'Online', value: '${overview.onlineCount}'),
              _SummaryPill(label: 'Stale', value: '${overview.staleCount}'),
              _SummaryPill(label: 'Offline', value: '${overview.offlineCount}'),
              _SummaryPill(
                label: 'Mismatch',
                value: '${overview.incompatibleCount}',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: SponzeyScrollCue(
            controller: _scrollController,
            child: peers.isEmpty
                ? ListView(
                    controller: _scrollController,
                    children: [
                      SponzeyCard(
                        child: Text(
                          discoveryState.isLoading
                              ? '디스커버리 엔진을 시작하는 중입니다.'
                              : '발견된 피어가 없습니다. 같은 ID/PW로 로그인한 다른 앱 인스턴스를 실행해 보세요.',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _DiscoveryDiagnosticsCard(state: discoveryState),
                    ],
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      return GridView.builder(
                        controller: _scrollController,
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: constraints.maxWidth < 720
                              ? 720
                              : 560,
                          mainAxisExtent: 260,
                          mainAxisSpacing: AppSpacing.lg,
                          crossAxisSpacing: AppSpacing.lg,
                        ),
                        itemCount: peers.length,
                        itemBuilder: (context, index) {
                          final peer = peers[index];
                          return _PeerCard(peer: peer);
                        },
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _DiscoveryDiagnosticsCard extends StatelessWidget {
  const _DiscoveryDiagnosticsCard({required this.state});

  final DiscoveryState state;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final authState = ref.watch(authControllerProvider);
        final logger = ref.watch(appLoggerProvider);
        final logFilePath = logger is AppLogFileLocator
            ? (logger as AppLogFileLocator).logFilePath
            : null;
        return SponzeyCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Discovery Diagnostics',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              _DiagnosticsLine(
                label: 'Auth Status',
                value: authState.status.name,
              ),
              _DiagnosticsLine(
                label: 'Auth User',
                value: authState.currentUser?.userId ?? '-',
              ),
              _DiagnosticsLine(
                label: 'Discovery Running',
                value: state.isRunning ? 'true' : 'false',
              ),
              _DiagnosticsLine(
                label: 'Discovery Loading',
                value: state.isLoading ? 'true' : 'false',
              ),
              _DiagnosticsLine(
                label: 'Discovery Error',
                value: state.errorMessage ?? '-',
              ),
              _DiagnosticsLine(
                label: 'Transport Mode',
                value: state.discoveryTransportMode ?? '-',
              ),
              _DiagnosticsLine(
                label: 'Discovery Ports',
                value:
                    'preferred ${state.discoveryPreferredPort ?? '-'} / '
                    'rx ${state.discoveryReceivePort ?? '-'} / '
                    'tx ${state.discoverySendPort ?? '-'} / '
                    'fallback ${state.discoveryReceivePortFallback}',
              ),
              _DiagnosticsLine(
                label: 'Broadcast Targets',
                value:
                    '${state.discoveryBroadcastTargetCount} '
                    '${state.discoveryBroadcastTargetPreview.join(', ')}',
              ),
              _DiagnosticsLine(
                label: 'Transport Error',
                value: state.discoveryTransportError ?? '-',
              ),
              _DiagnosticsLine(label: 'Log File', value: logFilePath ?? '-'),
              _DiagnosticsLine(
                label: 'Pairing User',
                value: state.currentPairingUserId ?? '-',
              ),
              _DiagnosticsLine(
                label: 'Group Tag Preview',
                value: state.currentDiscoveryGroupTagPreview ?? '-',
              ),
              _DiagnosticsLine(
                label: 'Last Broadcast',
                value: state.lastBroadcastAt?.toIso8601String() ?? '-',
              ),
              _DiagnosticsLine(
                label: 'Last Packet',
                value: state.lastPacketAt?.toIso8601String() ?? '-',
              ),
              _DiagnosticsLine(
                label: 'Packet RX Count',
                value: '${state.receivedPacketCount}',
              ),
              _DiagnosticsLine(
                label: 'Local Registry Entries',
                value: '${state.localRegistryEntryCount}',
              ),
              _DiagnosticsLine(
                label: 'Last Decision',
                value: state.lastDecision ?? '-',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DiagnosticsLine extends StatelessWidget {
  const _DiagnosticsLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _PeerCard extends StatelessWidget {
  const _PeerCard({required this.peer});

  final PeerNode peer;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final summary = ref.watch(peerConnectionSummaryProvider(peer));

        return SponzeyCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.computer_rounded),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      peer.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  StatusBadge(
                    label: summary.label,
                    backgroundColor: _statusBackground(summary.status),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                peer.deviceName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                peer.userId,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                summary.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              NetworkPathSummary(peerId: peer.id),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: summary.canSendFiles
                      ? () {
                          ref
                              .read(transferControllerProvider.notifier)
                              .setDraftPeerId(peer.id);
                          context.go(TransfersScreen.routePath);
                        }
                      : null,
                  child: Text(
                    summary.canSendFiles ? '파일 보내기' : '자동 연결 대기 중',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _statusBackground(PeerConnectionProductStatus status) {
    switch (status) {
      case PeerConnectionProductStatus.connected:
        return const Color(0xFFE8F7EE);
      case PeerConnectionProductStatus.checking:
      case PeerConnectionProductStatus.authenticating:
      case PeerConnectionProductStatus.stale:
        return const Color(0xFFFFF4D6);
      case PeerConnectionProductStatus.failed:
      case PeerConnectionProductStatus.offline:
        return const Color(0xFFFDEBE8);
      case PeerConnectionProductStatus.incompatible:
        return const Color(0xFFEAF1FF);
    }
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SponzeyCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(width: AppSpacing.sm),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}
