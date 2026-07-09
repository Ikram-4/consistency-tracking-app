import 'package:flutter/material.dart';
import 'package:phantom/models/goal.dart';
import 'package:phantom/providers/stats_provider.dart';
import 'package:phantom/theme/app_theme.dart';

/// A compact card displaying goal title, domain, progress, and pacing status.
class GoalCard extends StatelessWidget {
  final Goal goal;
  final int totalCheckIns;
  final PaceData? paceData;
  final VoidCallback? onTap;

  const GoalCard({
    super.key,
    required this.goal,
    required this.totalCheckIns,
    this.paceData,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // Calculate progress details
    final double displayProgress;
    final InlineSpan progressSpan;

    switch (goal.progressType) {
      case ProgressType.milestone:
        displayProgress = goal.progressPercent;
        progressSpan = TextSpan(
          children: [
            TextSpan(
              text: '${goal.completedMilestoneCount} ',
              style: textTheme.bodySmall?.copyWith(
                color: AppTheme.dataWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: 'of ',
              style: textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            TextSpan(
              text: '${goal.milestones.length} ',
              style: textTheme.bodySmall?.copyWith(
                color: AppTheme.dataWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: 'milestones',
              style: textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        );
        break;
      case ProgressType.count:
        final count = goal.targetCount ?? 1;
        displayProgress = (totalCheckIns / count).clamp(0.0, 1.0);
        progressSpan = TextSpan(
          children: [
            TextSpan(
              text: '$totalCheckIns ',
              style: textTheme.bodySmall?.copyWith(
                color: AppTheme.dataWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: 'of ',
              style: textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            TextSpan(
              text: '$count ',
              style: textTheme.bodySmall?.copyWith(
                color: AppTheme.dataWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: 'logs',
              style: textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        );
        break;
      case ProgressType.timeElapsed:
        displayProgress = goal.progressPercent;
        progressSpan = TextSpan(
          children: [
            TextSpan(
              text: '${(displayProgress * 100).toStringAsFixed(0)}% ',
              style: textTheme.bodySmall?.copyWith(
                color: AppTheme.dataWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: 'time elapsed',
              style: textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        );
        break;
    }

    // Determine status color, label, and shape icon if pace data is present
    Color? statusColor;
    String? statusLabel;
    IconData? statusIcon;
    if (paceData != null) {
      statusLabel = paceData!.progressLabel;
      statusIcon = AppTheme.statusIcon(statusLabel);
      switch (paceData!.status) {
        case TrackingStatus.onTrack:
          statusColor = AppTheme.onTrack;
          break;
        case TrackingStatus.behind:
          statusColor = AppTheme.behind;
          break;
        case TrackingStatus.fallingOff:
          statusColor = AppTheme.fallingOff;
          break;
      }
    }

    final dColor = AppTheme.domainColor(goal.domain);

    return Container(
      decoration: AppTheme.elevatedDecoration(), // Subtle physical depth top-edge gradient
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Domain Chip and Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: dColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(AppTheme.controlRadius),
                        border: Border.all(color: dColor.withOpacity(0.25), width: 1),
                      ),
                      child: Text(
                        goal.domain.toUpperCase(),
                        style: textTheme.labelSmall?.copyWith(
                          color: dColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (statusLabel != null && statusColor != null && statusIcon != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            statusIcon,
                            size: 14,
                            color: statusColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            statusLabel,
                            style: textTheme.labelMedium?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Title
                Text(
                  goal.title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),

                // Days remaining (Tabular numbers)
                Text.rich(
                  goal.daysRemaining >= 0
                      ? TextSpan(
                          children: [
                            TextSpan(
                              text: '${goal.daysRemaining} ',
                              style: textTheme.bodySmall?.copyWith(
                                color: AppTheme.dataWhite,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text: 'days left',
                              style: textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        )
                      : TextSpan(
                          text: 'Target date passed',
                          style: textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                ),
                const SizedBox(height: 16),

                // Progress Bar with Micro-interaction animation
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: SizedBox(
                    height: 4,
                    width: double.infinity,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: displayProgress),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return LinearProgressIndicator(
                          value: value,
                          backgroundColor: theme.colorScheme.outline.withOpacity(0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            goal.progressType == ProgressType.timeElapsed
                                ? theme.colorScheme.secondary
                                : theme.colorScheme.primary,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Progress details text (Tabular contrast numbers)
                Text.rich(progressSpan),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
