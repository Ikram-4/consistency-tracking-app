import 'package:flutter/material.dart';
import 'package:phantom/models/check_in.dart';
import 'package:phantom/models/practice.dart';
import 'package:phantom/models/goal.dart';
import 'package:phantom/utils/constants.dart';
import 'package:phantom/utils/date_helpers.dart';

/// A card displaying details of a single check-in.
class CheckInTile extends StatelessWidget {
  final CheckIn checkIn;
  final Practice? practice;
  final Goal? goal;
  final VoidCallback? onDelete;

  const CheckInTile({
    super.key,
    required this.checkIn,
    this.practice,
    this.goal,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // Effort color shading
    Color effortColor;
    switch (checkIn.effortLevel) {
      case EffortLevel.light:
        // Light opacity primary
        effortColor = theme.colorScheme.primary.withOpacity(0.4);
        break;
      case EffortLevel.moderate:
        effortColor = theme.colorScheme.primary.withOpacity(0.7);
        break;
      case EffortLevel.deep:
        effortColor = theme.colorScheme.primary;
        break;
      default:
        effortColor = theme.colorScheme.primary;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: theme.colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Practice, Date, Effort indicator, and Delete option
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        practice?.title ?? 'Practice Session',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        goal?.title ?? 'Goal',
                        style: textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      PhantomDateHelpers.relativeDate(checkIn.timestamp),
                      style: textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      PhantomDateHelpers.formatTime(checkIn.timestamp),
                      style: textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 16),

            // Note Text
            Text(
              checkIn.note,
              style: textTheme.bodyMedium?.copyWith(
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),

            // Bottom row: Effort chip, Duration, Delete button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: effortColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: effortColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: effortColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            EffortLevel.label(checkIn.effortLevel).toUpperCase(),
                            style: textTheme.labelSmall?.copyWith(
                              color: effortColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 9,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (checkIn.durationMinutes != null) ...[
                      const SizedBox(width: 10),
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${checkIn.durationMinutes} min',
                        style: textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    color: theme.colorScheme.error.withOpacity(0.7),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('Delete Check-In?'),
                            content: const Text(
                              'Are you sure you want to delete this check-in entry? This will adjust your pacing standing and check-in counts.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.error,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () {
                                  Navigator.of(context).pop(); // pop dialog
                                  onDelete!(); // perform delete callback
                                },
                                child: const Text('Delete'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
