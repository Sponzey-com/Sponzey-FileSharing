import 'package:flutter/material.dart';
import 'package:sponzey_file_sharing/app/theme/app_colors.dart';
import 'package:sponzey_file_sharing/app/theme/app_radius.dart';
import 'package:sponzey_file_sharing/app/theme/app_spacing.dart';

class SponzeyCard extends StatelessWidget {
  const SponzeyCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.backgroundColor = AppColors.paper,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.techBorder),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
