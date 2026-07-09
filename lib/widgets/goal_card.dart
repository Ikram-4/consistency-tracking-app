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

    // Calculate progress percent based on type
    final double displayProgress;
    final String progressText;

    switch (goal.progressType) {
      case ProgressType.milestone:
        displayProgress = goal.progressPercent;
        progressText = '${goal.completedMilestoneCount} of ${goal.milestones.length} milestones';
        break;
      case ProgressType.count:
        final count = goal.targetCount ?? 1;
        displayProgress = (totalCheckIns / count).clamp(0.0, 1.0);
        progressText = '$totalCheckIns of $count';
        break;
      case ProgressType.timeElapsed:
        displayProgress = goal.progressPercent;
        progressText = '${(displayProgress * 100).toStringAsFixed(0)}% time elapsed';
        break;
    }

    // Determine status color and label if pace data is present
    Color? statusColor;
    String? statusLabel;
    if (paceData != null) {
      statusLabel = paceData!.progressLabel;
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

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      goal.domain.toUpperCase(),
                      style: textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  if (statusLabel != null && statusColor != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          statusLabel,
                          style: textTheme.labelMedium?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
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

              // Days remaining
              Text(
                goal.daysRemaining >= 0
                    ? '${goal.daysRemaining} days left'
                    : 'Target date passed',
                style: textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),

              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: SizedBox(
                  height: 4,
                  width: double.infinity,
                  child: LinearProgressIndicator(
                    value: displayProgress,
                    backgroundColor: theme.colorScheme.outline.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      goal.progressType == ProgressType.timeElapsed
                          ? theme.colorScheme.secondary
                          : theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Progress details text
              Text(
                progressText,
                style: textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
