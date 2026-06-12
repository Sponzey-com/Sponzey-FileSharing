import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sponzey_file_sharing/application/auth/auth_controller.dart';
import 'package:sponzey_file_sharing/presentation/auth/login_screen.dart';
import 'package:sponzey_file_sharing/presentation/dashboard/dashboard_screen.dart';
import 'package:sponzey_file_sharing/presentation/history/history_screen.dart';
import 'package:sponzey_file_sharing/presentation/peers/peers_screen.dart';
import 'package:sponzey_file_sharing/presentation/settings/settings_screen.dart';
import 'package:sponzey_file_sharing/presentation/shell/sponzey_shell.dart';
import 'package:sponzey_file_sharing/presentation/transfers/transfers_screen.dart';

final navigatorKeyProvider = Provider<GlobalKey<NavigatorState>>((ref) {
  return GlobalKey<NavigatorState>();
});

final goRouterProvider = Provider<GoRouter>((ref) {
  final navigatorKey = ref.watch(navigatorKeyProvider);
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: LoginScreen.routePath,
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isAtLogin = state.matchedLocation == LoginScreen.routePath;

      if (!isLoggedIn && !isAtLogin) {
        return LoginScreen.routePath;
      }

      if (isLoggedIn && isAtLogin) {
        return DashboardScreen.routePath;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: LoginScreen.routePath,
        name: LoginScreen.routeName,
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => SponzeyShell(child: child),
        routes: [
          GoRoute(
            path: DashboardScreen.routePath,
            name: DashboardScreen.routeName,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DashboardScreen()),
          ),
          GoRoute(
            path: PeersScreen.routePath,
            name: PeersScreen.routeName,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: PeersScreen()),
          ),
          GoRoute(
            path: TransfersScreen.routePath,
            name: TransfersScreen.routeName,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: TransfersScreen()),
          ),
          GoRoute(
            path: HistoryScreen.routePath,
            name: HistoryScreen.routeName,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HistoryScreen()),
          ),
          GoRoute(
            path: SettingsScreen.routePath,
            name: SettingsScreen.routeName,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SettingsScreen()),
          ),
        ],
      ),
    ],
  );
});
