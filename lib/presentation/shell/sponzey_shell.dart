import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sponzey_file_sharing/app/theme/app_colors.dart';
import 'package:sponzey_file_sharing/app/theme/app_spacing.dart';
import 'package:sponzey_file_sharing/application/auth/auth_controller.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_overview_provider.dart';
import 'package:sponzey_file_sharing/presentation/dashboard/dashboard_screen.dart';
import 'package:sponzey_file_sharing/presentation/history/history_screen.dart';
import 'package:sponzey_file_sharing/presentation/peers/peers_screen.dart';
import 'package:sponzey_file_sharing/presentation/settings/settings_screen.dart';
import 'package:sponzey_file_sharing/presentation/shared/sponzey_card.dart';
import 'package:sponzey_file_sharing/presentation/shared/sponzey_scroll_cue.dart';
import 'package:sponzey_file_sharing/presentation/shared/status_badge.dart';
import 'package:sponzey_file_sharing/presentation/transfers/transfers_screen.dart';

import 'app_navigation_item.dart';

class SponzeyShell extends ConsumerWidget {
  const SponzeyShell({super.key, required this.child});

  final Widget child;

  static const _navigationItems = [
    AppNavigationItem(
      label: 'Dashboard',
      route: DashboardScreen.routePath,
      icon: Icons.space_dashboard_rounded,
    ),
    AppNavigationItem(
      label: 'Peers',
      route: PeersScreen.routePath,
      icon: Icons.hub_rounded,
    ),
    AppNavigationItem(
      label: 'Transfers',
      route: TransfersScreen.routePath,
      icon: Icons.send_rounded,
    ),
    AppNavigationItem(
      label: 'History',
      route: HistoryScreen.routePath,
      icon: Icons.history_rounded,
    ),
    AppNavigationItem(
      label: 'Settings',
      route: SettingsScreen.routePath,
      icon: Icons.settings_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routerState = GoRouterState.of(context);
    final activeTransfers = ref.watch(transferJobsProvider);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.pageGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      _NavigationRail(
                        currentLocation: routerState.matchedLocation,
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: ShellContentPane(
                          currentLocation: routerState.matchedLocation,
                          child: child,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _TransferDock(activeCount: activeTransfers.length),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ShellContentPane extends StatelessWidget {
  const ShellContentPane({
    super.key,
    required this.currentLocation,
    required this.child,
  });

  final String currentLocation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final currentKey = ValueKey(currentLocation);

    return ClipRect(
      child: DecoratedBox(
        decoration: const BoxDecoration(color: AppColors.techBackground),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 360),
          switchInCurve: Curves.easeInOutCubic,
          switchOutCurve: Curves.easeInOutCubic,
          layoutBuilder: (currentChild, previousChildren) {
            return Stack(
              fit: StackFit.expand,
              children: [
                for (final previousChild in previousChildren)
                  IgnorePointer(child: previousChild),
                ?currentChild,
              ],
            );
          },
          transitionBuilder: (transitionChild, animation) {
            final isIncoming = transitionChild.key == currentKey;
            final offsetAnimation =
                Tween<Offset>(
                  begin: isIncoming
                      ? const Offset(0.08, 0)
                      : const Offset(-0.08, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                );

            return IgnorePointer(
              ignoring: !isIncoming,
              child: SlideTransition(
                position: offsetAnimation,
                child: FadeTransition(
                  opacity: animation,
                  child: transitionChild,
                ),
              ),
            );
          },
          child: KeyedSubtree(key: currentKey, child: child),
        ),
      ),
    );
  }
}

class _NavigationRail extends ConsumerStatefulWidget {
  const _NavigationRail({required this.currentLocation});

  final String currentLocation;

  @override
  ConsumerState<_NavigationRail> createState() => _NavigationRailState();
}

class _NavigationRailState extends ConsumerState<_NavigationRail> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 248,
      child: SponzeyCard(
        child: SponzeyScrollCue(
          controller: _scrollController,
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Workspace',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '로컬 네트워크 파일 전송 워크스페이스',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.techTextMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                for (final item in SponzeyShell._navigationItems) ...[
                  _NavButton(
                    item: item,
                    selected: widget.currentLocation == item.route,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: () {
                    ref.read(authControllerProvider.notifier).signOut();
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('로그아웃'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.item, required this.selected});

  final AppNavigationItem item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final background = selected ? AppColors.brandYellow : AppColors.paper;
    final foreground = selected ? AppColors.paper : AppColors.ink;

    return InkWell(
      onTap: () => context.go(item.route),
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.techBlue : AppColors.techBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(item.icon, color: foreground),
            const SizedBox(width: AppSpacing.sm),
            Text(
              item.label,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: foreground),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransferDock extends StatelessWidget {
  const _TransferDock({required this.activeCount});

  final int activeCount;

  @override
  Widget build(BuildContext context) {
    return SponzeyCard(
      backgroundColor: AppColors.paper,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Icon(Icons.local_shipping_rounded, color: AppColors.techBlue),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '$activeCount개의 전송 작업을 확인 중입니다.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          StatusBadge(label: 'Global Transfer Dock'),
        ],
      ),
    );
  }
}
