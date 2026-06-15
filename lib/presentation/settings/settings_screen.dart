import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponzey_file_sharing/app/theme/app_spacing.dart';
import 'package:sponzey_file_sharing/application/settings/settings_controller.dart';
import 'package:sponzey_file_sharing/core/logger/app_logger.dart';
import 'package:sponzey_file_sharing/domain/entities/app_settings.dart';
import 'package:sponzey_file_sharing/presentation/shared/page_header.dart';
import 'package:sponzey_file_sharing/presentation/shared/sponzey_card.dart';
import 'package:sponzey_file_sharing/presentation/shared/sponzey_scroll_cue.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  static const routeName = 'settings';
  static const routePath = '/settings';

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _savePathController = TextEditingController();

  AppLogLevel _logLevel = AppLogLevel.info;
  bool _didHydrate = false;

  @override
  void dispose() {
    _scrollController.dispose();
    _savePathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsControllerProvider);

    if (!_didHydrate && !settingsState.isLoading) {
      _didHydrate = true;
      _savePathController.text = settingsState.settings.defaultSavePath;
      _logLevel = settingsState.settings.logLevel;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeader(
          title: 'Settings',
          description:
              '로컬 저장소, 수신 정책, 진단 옵션을 관리합니다. 피어 인증은 연결 요청을 수락하면 바로 완료됩니다.',
        ),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: SponzeyScrollCue(
            controller: _scrollController,
            child: ListView(
              controller: _scrollController,
              children: [
                _SettingsCard(
                  title: 'Receive Policy',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '인증된 피어가 보낸 파일은 별도 승인 창 없이 기본 저장 경로에 즉시 저장합니다.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        '수신 전 수동 승인 정책은 현재 제품 범위에서 사용하지 않습니다. 수신 가능 여부는 피어 인증과 저장 경로 준비 상태로만 결정합니다.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _SettingsCard(
                  title: 'Storage',
                  child: TextField(
                    controller: _savePathController,
                    enabled: !settingsState.isSaving,
                    decoration: const InputDecoration(
                      labelText: '기본 저장 경로',
                      hintText: '/Users/you/Downloads/Sponzey FileSharing',
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _SettingsCard(
                  title: 'Diagnostics',
                  child: DropdownButtonFormField<AppLogLevel>(
                    initialValue: _logLevel,
                    items: AppLogLevel.values
                        .map(
                          (level) => DropdownMenuItem(
                            value: level,
                            child: Text(level.name),
                          ),
                        )
                        .toList(),
                    onChanged: settingsState.isSaving
                        ? null
                        : (value) {
                            if (value == null) {
                              return;
                            }
                            setState(() {
                              _logLevel = value;
                            });
                          },
                    decoration: const InputDecoration(labelText: '로그 레벨'),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _SettingsCard(
                  title: 'Peer Access',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '별도의 허용 사용자 등록은 사용하지 않습니다.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '연결 요청을 받은 피어는 별도 검증 없이 바로 인증되고 파일을 주고받을 수 있습니다.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (settingsState.errorMessage != null) ...[
                  _SettingsCard(
                    title: 'Notice',
                    child: Text(settingsState.errorMessage!),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: settingsState.isLoading || settingsState.isSaving
                        ? null
                        : () => _save(settingsState),
                    icon: const Icon(Icons.save_rounded),
                    label: Text(settingsState.isSaving ? '저장 중...' : '설정 저장'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _save(SettingsState currentState) async {
    await ref
        .read(settingsControllerProvider.notifier)
        .save(
          currentState.settings.copyWith(
            defaultSavePath: _savePathController.text.trim(),
            autoReceiveEnabled: true,
            receivePolicy: ReceivePolicy.autoReceiveAll,
            logLevel: _logLevel,
          ),
        );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SponzeyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}
