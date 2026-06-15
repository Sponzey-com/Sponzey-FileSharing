import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:sponzey_file_sharing/app/theme/app_colors.dart';
import 'package:sponzey_file_sharing/app/theme/app_spacing.dart';
import 'package:sponzey_file_sharing/application/auth/peer_auth_controller.dart';
import 'package:sponzey_file_sharing/application/settings/settings_controller.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_controller.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_overview_provider.dart';
import 'package:sponzey_file_sharing/domain/entities/peer_node.dart';
import 'package:sponzey_file_sharing/domain/entities/transfer_job.dart';
import 'package:sponzey_file_sharing/domain/transfer/transfer_failure_policy.dart';
import 'package:sponzey_file_sharing/domain/transfer/transfer_route_snapshot.dart';
import 'package:sponzey_file_sharing/infrastructure/platform/file_location_opener.dart';
import 'package:sponzey_file_sharing/presentation/shared/page_header.dart';
import 'package:sponzey_file_sharing/presentation/shared/sponzey_card.dart';
import 'package:sponzey_file_sharing/presentation/shared/sponzey_scroll_cue.dart';
import 'package:sponzey_file_sharing/presentation/shared/status_badge.dart';

class TransfersScreen extends ConsumerStatefulWidget {
  const TransfersScreen({super.key});

  static const routeName = 'transfers';
  static const routePath = '/transfers';

  @override
  ConsumerState<TransfersScreen> createState() => _TransfersScreenState();
}

class _TransfersScreenState extends ConsumerState<TransfersScreen> {
  final ScrollController _scrollController = ScrollController();
  final ScrollController _formScrollController = ScrollController();
  final TextEditingController _filePathController = TextEditingController();
  List<String> _selectedFilePaths = const [];
  String? _selectedPeerId;
  bool _isDraggingFiles = false;

  @override
  void dispose() {
    _scrollController.dispose();
    _formScrollController.dispose();
    _filePathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transferState = ref.watch(transferControllerProvider);
    final jobs = ref.watch(transferJobsProvider);
    final peers = ref.watch(authenticatedTransferPeersProvider);
    final sessions = ref
        .watch(peerAuthControllerProvider)
        .sessions
        .values
        .toList(growable: false);
    final settingsState = ref.watch(settingsControllerProvider);
    _applyDraftPeer(transferState.draftPeerId, peers);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Transfers',
          description: '인증된 피어 하나를 선택해 단일 파일을 UDP 기반 MVP 파이프라인으로 전송합니다.',
          trailing: StatusBadge(
            label: transferState.isListening
                ? 'Transfer Ready'
                : 'Transfer Idle',
            backgroundColor: transferState.isListening
                ? AppColors.successSoft
                : AppColors.warningSoft,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: SponzeyCard(
                  backgroundColor: AppColors.brandYellowMist,
                  child: SponzeyScrollCue(
                    controller: _formScrollController,
                    child: ListView(
                      controller: _formScrollController,
                      padding: EdgeInsets.zero,
                      children: [
                        Text(
                          'New Transfer',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          '드롭한 파일은 인증된 피어로 바로 전송됩니다. 수신 노드는 기본 저장 경로에 즉시 저장합니다.',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          peers.isEmpty
                              ? '자동 연결 완료를 기다리는 중입니다. 같은 ID/PW로 로그인한 피어가 있으면 곧 전송 대상으로 나타납니다.'
                              : '연결된 피어 ${peers.length}개가 전송 대상으로 준비되었습니다.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue:
                              _selectedPeerId != null &&
                                  peers.any(
                                    (peer) => peer.id == _selectedPeerId,
                                  )
                              ? _selectedPeerId
                              : null,
                          decoration: const InputDecoration(labelText: '대상 피어'),
                          items: [
                            for (final peer in peers)
                              DropdownMenuItem(
                                value: peer.id,
                                child: Text(
                                  '${peer.displayName} • ${peer.deviceName}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          selectedItemBuilder: (context) {
                            return peers
                                .map(
                                  (peer) => Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      '${peer.displayName} • ${peer.deviceName}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(growable: false);
                          },
                          onChanged: peers.isEmpty
                              ? null
                              : (value) {
                                  setState(() {
                                    _selectedPeerId = value;
                                  });
                                },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        DropTarget(
                          onDragEntered: (_) {
                            setState(() {
                              _isDraggingFiles = true;
                            });
                          },
                          onDragExited: (_) {
                            setState(() {
                              _isDraggingFiles = false;
                            });
                          },
                          onDragDone: (detail) async {
                            setState(() {
                              _isDraggingFiles = false;
                            });
                            await _applyDroppedFiles(detail.files);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeInOut,
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: _isDraggingFiles
                                  ? AppColors.brandYellowSoft
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: AppColors.ink,
                                width: _isDraggingFiles ? 2.5 : 1.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.file_open_rounded),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Text(
                                        _isDraggingFiles
                                            ? '파일을 놓아서 전송 경로를 지정하세요'
                                            : '파일을 여기로 드래그 앤 드롭',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  '여러 파일을 드롭하면 선택한 피어로 순차 전송합니다.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                if (_selectedFilePaths.isNotEmpty) ...[
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    _selectedFilePaths.length == 1
                                        ? '선택됨: ${p.basename(_selectedFilePaths.first)}'
                                        : '선택됨: ${_selectedFilePaths.length}개 파일, 첫 파일 ${p.basename(_selectedFilePaths.first)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextField(
                          controller: _filePathController,
                          onChanged: (_) {
                            if (_selectedFilePaths.isEmpty) {
                              return;
                            }
                            setState(() {
                              _selectedFilePaths = const [];
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: '파일 경로',
                            hintText: '/Users/me/Desktop/demo.zip',
                            prefixIcon: Icon(Icons.description_rounded),
                          ),
                          minLines: 2,
                          maxLines: 3,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _InfoLine(
                          label: '기본 수신 경로',
                          value:
                              settingsState.settings.defaultSavePath
                                  .trim()
                                  .isEmpty
                              ? '설정 로딩 중'
                              : settingsState.settings.defaultSavePath,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _InfoLine(label: '수신 동작', value: '승인 없이 즉시 저장'),
                        const SizedBox(height: AppSpacing.sm),
                        _InfoLine(
                          label: '연결 세션',
                          value: peers.isEmpty
                              ? '연결 완료 0 / 전체 세션 ${sessions.length}'
                              : '연결 완료 ${peers.length} / 전체 세션 ${sessions.length}',
                        ),
                        if (transferState.errorMessage != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            transferState.errorMessage!,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.danger),
                          ),
                        ],
                        if (transferState.infoMessage != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            transferState.infoMessage!,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.success),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: peers.isEmpty
                                ? null
                                : () async {
                                    final peerId = _selectedPeerId;
                                    if (peerId == null) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('전송 대상을 먼저 선택해 주세요.'),
                                        ),
                                      );
                                      return;
                                    }
                                    final selectedPaths =
                                        _selectedFilePaths.isEmpty
                                        ? [_filePathController.text]
                                        : _selectedFilePaths;
                                    await ref
                                        .read(
                                          transferControllerProvider.notifier,
                                        )
                                        .sendFiles(
                                          peerId: peerId,
                                          filePaths: selectedPaths,
                                        );
                                  },
                            icon: const Icon(Icons.send_rounded),
                            label: const Text('전송 시작'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                flex: 6,
                child: SponzeyCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transfer Queue',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Expanded(
                        child: SponzeyScrollCue(
                          controller: _scrollController,
                          child: jobs.isEmpty
                              ? ListView(
                                  controller: _scrollController,
                                  children: [
                                    ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: const Icon(
                                        Icons.local_shipping_rounded,
                                      ),
                                      title: const Text('진행 중인 전송이 없습니다'),
                                      subtitle: Text(
                                        peers.isEmpty
                                            ? '자동 연결이 완료되면 전송 대상이 여기서 바로 선택됩니다.'
                                            : '피어와 파일 경로를 선택한 뒤 전송을 시작하세요.',
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.separated(
                                  controller: _scrollController,
                                  itemBuilder: (context, index) {
                                    final job = jobs[index];
                                    return _TransferJobTile(job: job);
                                  },
                                  separatorBuilder: (_, _) =>
                                      const Divider(height: 1),
                                  itemCount: jobs.length,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _applyDraftPeer(String? draftPeerId, List<PeerNode> peers) {
    if (peers.isNotEmpty &&
        _selectedPeerId == null &&
        peers.any((peer) => peer.id == draftPeerId) == false) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _selectedPeerId != null || peers.isEmpty) {
          return;
        }
        setState(() {
          _selectedPeerId = peers.first.id;
        });
      });
    }
    if (draftPeerId == null) {
      return;
    }
    if (!peers.any((peer) => peer.id == draftPeerId)) {
      return;
    }
    if (_selectedPeerId == draftPeerId) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedPeerId = draftPeerId;
      });
      ref.read(transferControllerProvider.notifier).setDraftPeerId(null);
    });
  }

  Future<void> _applyDroppedFiles(List<XFile> files) async {
    if (files.isEmpty) {
      return;
    }

    final filePaths = files
        .map((file) => file.path.trim())
        .where((path) => path.isNotEmpty)
        .toList(growable: false);
    if (filePaths.isEmpty) {
      return;
    }

    String? invalidPath;
    for (final path in filePaths) {
      if (!FileSystemEntity.isFileSync(path)) {
        invalidPath = path;
        break;
      }
    }
    if (invalidPath != null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('디렉터리가 아니라 파일 하나를 드롭해 주세요.')),
      );
      return;
    }

    setState(() {
      _selectedFilePaths = filePaths;
      _filePathController.text = filePaths.first;
    });
  }
}

class _TransferJobTile extends ConsumerWidget {
  const _TransferJobTile({required this.job});

  final TransferJob job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = job.progress.clamp(0.0, 1.0);
    final failureDecision = const TransferFailurePolicy().classify(job);
    final canRetry =
        job.isTerminal &&
        failureDecision.retryable &&
        job.direction == TransferDirection.outgoing &&
        job.localFilePath != null;
    final canOpenCompletedFile =
        job.status == TransferJobStatus.completed &&
        job.destinationPath != null;
    final canOpenFolder = canOpenCompletedFile;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        job.direction == TransferDirection.outgoing
            ? Icons.north_east_rounded
            : Icons.south_west_rounded,
      ),
      title: Text(job.fileName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${job.direction == TransferDirection.outgoing ? 'To' : 'From'} ${job.peerDisplayName} • ${_formatBytes(job.bytesTransferred)} / ${_formatBytes(job.fileSize)}',
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              Text('속도 ${_formatRate(job.throughputBytesPerSec)}'),
              Text('Window ${job.windowSize}'),
              Text('Retry ${job.retryCount}'),
              Text('Loss ${(job.lossRate * 100).toStringAsFixed(1)}%'),
              if (job.rttMs != null)
                Text('RTT ${job.rttMs!.toStringAsFixed(0)}ms'),
              if (job.estimatedRemaining != null)
                Text('ETA ${_formatDuration(job.estimatedRemaining!)}'),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          LinearProgressIndicator(
            value: progress,
            minHeight: 12,
            color: AppColors.brandYellow,
            backgroundColor: AppColors.brandYellowMist,
            borderRadius: BorderRadius.circular(999),
          ),
          if (job.message != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(job.message!),
          ],
          if (job.isTerminal &&
              job.status != TransferJobStatus.completed &&
              failureDecision.userMessage != job.message) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(failureDecision.userMessage),
          ],
          if (job.destinationPath != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Path: ${job.destinationPath}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (job.routeSnapshot != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              _formatRouteSnapshot(job.routeSnapshot!),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (!job.isTerminal || canRetry || canOpenCompletedFile) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                if (!job.isTerminal)
                  OutlinedButton(
                    onPressed: () {
                      ref
                          .read(transferControllerProvider.notifier)
                          .cancelTransfer(job.id);
                    },
                    child: const Text('취소'),
                  ),
                if (canRetry)
                  ElevatedButton(
                    onPressed: () {
                      ref
                          .read(transferControllerProvider.notifier)
                          .sendFile(
                            peerId: job.peerId,
                            filePath: job.localFilePath!,
                          );
                    },
                    child: const Text('재시도'),
                  ),
                if (canOpenFolder)
                  OutlinedButton(
                    onPressed: () async {
                      try {
                        await ref
                            .read(fileLocationOpenerProvider)
                            .openPath(job.destinationPath!);
                      } catch (_) {
                        if (!context.mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('파일을 열지 못했습니다.')),
                        );
                      }
                    },
                    child: const Text('파일 열기'),
                  ),
                if (canOpenFolder)
                  OutlinedButton(
                    onPressed: () async {
                      try {
                        await ref
                            .read(fileLocationOpenerProvider)
                            .openFolderForPath(job.destinationPath!);
                      } catch (_) {
                        if (!context.mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('저장 폴더를 열지 못했습니다.')),
                        );
                      }
                    },
                    child: const Text('폴더 열기'),
                  ),
              ],
            ),
          ],
        ],
      ),
      trailing: StatusBadge(label: job.statusLabel),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(value, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

String _formatRouteSnapshot(TransferRouteSnapshot snapshot) {
  final dataRemote =
      snapshot.dataRemoteAddress ?? snapshot.controlRemoteAddress;
  final dataLocal = snapshot.dataLocalAddress ?? snapshot.controlLocalAddress;
  final lease = snapshot.routeLeaseId.length <= 12
      ? snapshot.routeLeaseId
      : snapshot.routeLeaseId.substring(0, 12);
  return 'Route: $dataLocal -> $dataRemote ($lease)';
}

String _formatBytes(int value) {
  if (value < 1024) {
    return '$value B';
  }
  if (value < 1024 * 1024) {
    return '${(value / 1024).toStringAsFixed(1)} KB';
  }
  if (value < 1024 * 1024 * 1024) {
    return '${(value / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(value / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}

String _formatRate(double bytesPerSec) {
  if (bytesPerSec <= 0) {
    return '0 B/s';
  }
  return '${_formatBytes(bytesPerSec.round())}/s';
}

String _formatDuration(Duration value) {
  if (value.inSeconds < 60) {
    return '${value.inSeconds}s';
  }
  if (value.inMinutes < 60) {
    final seconds = value.inSeconds % 60;
    return '${value.inMinutes}m ${seconds}s';
  }
  final minutes = value.inMinutes % 60;
  return '${value.inHours}h ${minutes}m';
}
