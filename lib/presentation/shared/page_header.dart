import 'package:flutter/material.dart';
import 'package:sponzey_file_sharing/app/theme/app_colors.dart';
import 'package:sponzey_file_sharing/app/theme/app_spacing.dart';

class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    required this.description,
    this.trailing,
  });

  final String title;
  final String description;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(bottom: BorderSide(color: AppColors.techBorder)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: AppColors.techGreen,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const Spacer(),
          Flexible(
            child: Text(
              description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.techTextMuted),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.md),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class PageTitleBlock extends StatelessWidget {
  const PageTitleBlock({
    super.key,
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          description,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.techTextMuted),
        ),
      ],
    );
  }
}
