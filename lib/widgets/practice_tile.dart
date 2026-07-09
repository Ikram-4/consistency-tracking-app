import 'package:flutter/material.dart';
import 'package:phantom/models/practice.dart';

/// A tile displaying practice details and weekly progress.
class PracticeTile extends StatelessWidget {
  final Practice practice;
  final int thisWeekCount;
  final VoidCallback? onTap;

  const PracticeTile({
    super.key,
    required this.practice,
    required this.thisWeekCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final double progress = (thisWeekCount / practice.weeklyTarget).clamp(0.0, 1.0);
    final bool isCompleted = thisWeekCount >= practice.weeklyTarget;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: theme.colorScheme.surfaceContainer,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      practice.title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$thisWeekCount of ${practice.weeklyTarget} this week',
                      style: textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Progress Indicator
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 3,
                      backgroundColor: theme.colorScheme.outline.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isCompleted ? theme.colorScheme.primary : theme.colorScheme.primary.withOpacity(0.6),
                      ),
                    ),
                  ),
                  if (isCompleted)
                    Icon(
                      Icons.check,
                      size: 16,
                      color: theme.colorScheme.primary,
                    )
                  else
                    Text(
                      '${practice.weeklyTarget - thisWeekCount}',
                      style: textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
