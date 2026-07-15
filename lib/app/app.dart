import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponzey_file_sharing/app/router.dart';
import 'package:sponzey_file_sharing/app/theme/app_theme.dart';

class SponzeyFileSharingApp extends ConsumerWidget {
  const SponzeyFileSharingApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'Sponzey File Sharing',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}
