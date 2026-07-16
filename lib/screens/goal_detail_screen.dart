import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phantom/models/goal.dart';
import 'package:phantom/models/practice.dart';
import 'package:phantom/providers/goal_provider.dart';
import 'package:phantom/providers/practice_provider.dart';
import 'package:phantom/providers/check_in_provider.dart';
import 'package:phantom/providers/stats_provider.dart';
import 'package:phantom/screens/goal_form_screen.dart';
import 'package:phantom/screens/check_in_screen.dart';
import 'package:phantom/widgets/practice_tile.dart';
import 'package:phantom/utils/date_helpers.dart';
import 'package:phantom/theme/app_theme.dart';
import 'package:phantom/models/celebration_event.dart';
import 'package:phantom/services/celebration_controller.dart';
import 'package:phantom/repositories/habit_repository.dart';
import 'package:phantom/models/progress_shaping.dart';

/// Detailed view of a goal showing its status, milestones, and practices.
class GoalDetailScreen extends StatelessWidget {
  final String goalId;

  const GoalDetailScreen({super.key, required this.goalId});

  void _showAddPracticeDialog(BuildContext context, String goalId) {
    final titleController = TextEditingController();
    final targetController = TextEditingController(text: '4');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: const Text('Add Practice'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PRACTICE TITLE',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: titleController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Title is required.';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    hintText: 'e.g. VAPT lab practice, DSA problem',
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'WEEKLY TARGET (SESSIONS)',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: targetController,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Target is required.';
                    }
                    final count = int.tryParse(value);
                    if (count == null || count <= 0) {
                      return 'Enter a number greater than 0.';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    hintText: 'e.g. 4',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                final title = titleController.text.trim();
                final weeklyTarget = int.parse(targetController.text.trim());

                final practice = Practice(
                  goalId: goalId,
                  title: title,
                  weeklyTarget: weeklyTarget,
                );

                final practiceProvider = Provider.of<PracticeProvider>(context, listen: false);
                await practiceProvider.addPractice(practice);

                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, Goal goal) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Goal?'),
          content: Text(
            'Are you sure you want to delete "${goal.title}"? This will permanently delete all check-in counts and attached practices. This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final goalProvider = Provider.of<GoalProvider>(context, listen: false);
                await goalProvider.deleteGoal(goal.id);
                if (context.mounted) {
                  Navigator.of(context).pop(); // pop dialog
                  Navigator.of(context).pop(); // pop detail screen
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Consumer4<GoalProvider, PracticeProvider, CheckInProvider, StatsProvider>(
      builder: (context, goalProvider, practiceProvider, checkInProvider, statsProvider, child) {
        final goal = goalProvider.getById(goalId);

        if (goal == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(
              child: Text('Goal not found'),
            ),
          );
        }

        final practices = practiceProvider.getByGoalId(goalId);
        final activePractices = practices.where((p) => p.isActive).toList();
        final checkIns = checkInProvider.getByGoalId(goalId);
        final totalCheckIns = checkInProvider.totalCountForGoal(goalId);

        final paceData = StatsProvider.calculatePace(
          goal: goal,
          practices: activePractices,
          checkIns: checkIns,
        );

        final habitRepo = HabitRepository(
          checkIns: checkIns,
          profileLookup: (id) => goal.profile,
        );
        final state = habitRepo.currentState(goalId);
        final habitGoal = (goal.targetCount ?? 100).toDouble();
        final rawFraction = state.progress / habitGoal;
        // displayFraction is cosmetic only; core math must keep using rawFraction / state.progress.
        final displayFraction = shapeProgress(rawFraction);

        // Progress Details
        final double displayProgress;
        final InlineSpan progressSpan;
        switch (goal.progressType) {
          case ProgressType.milestone:
            displayProgress = displayFraction;
            progressSpan = TextSpan(
              children: [
                TextSpan(
                  text: '${goal.completedMilestoneCount} ',
                  style: textTheme.labelSmall?.copyWith(
                    color: AppTheme.dataWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: 'of ',
                  style: textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                TextSpan(
                  text: '${goal.milestones.length} ',
                  style: textTheme.labelSmall?.copyWith(
                    color: AppTheme.dataWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: 'milestones',
                  style: textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            );
            break;
          case ProgressType.count:
            final count = goal.targetCount ?? 1;
            displayProgress = displayFraction;
            progressSpan = TextSpan(
              children: [
                TextSpan(
                  text: '$totalCheckIns ',
                  style: textTheme.labelSmall?.copyWith(
                    color: AppTheme.dataWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: 'of ',
                  style: textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                TextSpan(
                  text: '$count ',
                  style: textTheme.labelSmall?.copyWith(
                    color: AppTheme.dataWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: 'logs',
                  style: textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            );
            break;
          case ProgressType.timeElapsed:
            displayProgress = displayFraction;
            progressSpan = TextSpan(
              children: [
                TextSpan(
                  text: '${(displayProgress * 100).toStringAsFixed(0)}% ',
                  style: textTheme.labelSmall?.copyWith(
                    color: AppTheme.dataWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: 'time elapsed',
                  style: textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            );
            break;
        }

        final dColor = AppTheme.domainColor(goal.domain);

        Color? statusColor;
        switch (paceData.status) {
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

        return Scaffold(
          appBar: AppBar(
            title: Text(goal.title),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit Goal',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => GoalFormScreen(goal: goal),
                    ),
                  );
                },
              ),
              if (!goal.isArchived)
                IconButton(
                  icon: const Icon(Icons.archive_outlined),
                  tooltip: 'Archive Goal',
                  onPressed: () async {
                    await goalProvider.archiveGoal(goal.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Goal archived'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      Navigator.of(context).pop();
                    }
                  },
                ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: theme.colorScheme.error,
                tooltip: 'Delete Goal',
                onPressed: () => _confirmDelete(context, goal),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(20.0),
            children: [
              // ── OVERVIEW CARD ──
              Container(
                decoration: AppTheme.elevatedDecoration(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                AppTheme.statusIcon(paceData.progressLabel),
                                size: 14,
                                color: statusColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                paceData.progressLabel,
                                style: textTheme.labelMedium?.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Target Date: ${PhantomDateHelpers.formatDate(goal.targetDate)}',
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.dataWhite,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text.rich(
                        goal.daysRemaining >= 0
                            ? TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${goal.daysRemaining} ',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.dataWhite,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'days remaining',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              )
                            : TextSpan(
                                text: 'Target date passed',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildStatBadge(
                            context: context,
                            icon: Icons.local_fire_department,
                            iconColor: AppTheme.behind,
                            label: 'Streak',
                            value: '${state.streakDays} days',
                          ),
                          const SizedBox(width: 8),
                          _buildStatBadge(
                            context: context,
                            icon: Icons.psychology,
                            iconColor: theme.colorScheme.primary,
                            label: 'Focus',
                            value: state.focus.toStringAsFixed(1),
                          ),
                          const SizedBox(width: 8),
                          _buildStatBadge(
                            context: context,
                            icon: Icons.tune,
                            iconColor: theme.colorScheme.secondary,
                            label: 'Style',
                            value: goal.profile.name[0].toUpperCase() + goal.profile.name.substring(1),
                          ),
                        ],
                      ),
                      if (goal.whyStatement != null && goal.whyStatement!.isNotEmpty) ...[
                        const Divider(height: 24),
                        Text(
                          'Why Statement',
                          style: textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '"${goal.whyStatement}"',
                          style: textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: theme.colorScheme.onSurface.withOpacity(0.8),
                          ),
                        ),
                      ],
                      const Divider(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            goal.progressType == ProgressType.timeElapsed ? 'Time Elapsed' : 'Goal Progress',
                            style: textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text.rich(
                            progressSpan,
                            style: textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: SizedBox(
                          height: 6,
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
                    ],
                  ),
                ),
              ),

              // ── PROJECTED COMPLETION ──
              Builder(builder: (context) {
                // Compute projected completion date inline using the
                // check-ins already loaded above — no extra providers needed.
                final habitRepo = HabitRepository(
                  checkIns: checkIns,
                  profileLookup: (id) => goal.profile,
                );
                final habitGoal = (goal.targetCount ?? 100).toDouble();
                final result =
                    habitRepo.projectedCompletionDay(goalId, habitGoal);
                final projectedDay = result.projectedDay;

                final String projectedLabel;
                if (projectedDay == null) {
                  projectedLabel = 'Not enough data yet';
                } else {
                  final today = DateTime.now();
                  final daysFromNow = projectedDay -
                      habitRepo.currentState(goalId).day;
                  final projectedDate =
                      today.add(Duration(days: daysFromNow));
                  final y = projectedDate.year.toString().padLeft(4, '0');
                  final m = projectedDate.month.toString().padLeft(2, '0');
                  final d = projectedDate.day.toString().padLeft(2, '0');
                  projectedLabel = '$y-$m-$d (Confidence: ${result.label})';
                }

                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Projected: ',
                        style: textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        projectedLabel,
                        style: textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 24),

              // ── MILESTONES SECTION ──
              if (goal.milestones.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'MILESTONES',
                      style: textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      '${goal.completedMilestoneCount} of ${goal.milestones.length}',
                      style: textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: goal.milestones.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final ms = goal.milestones[index];
                      return ListTile(
                        onTap: () async {
                          final result = await goalProvider.toggleMilestone(goal.id, ms.id);
                          if (result != null && result.wasCompleted) {
                            final events = <CelebrationEvent>[];
                            if (result.isGoalComplete) {
                              events.add(CelebrationEvent(
                                type: CelebrationType.goalComplete,
                                title: '🏆 Goal Complete!',
                                subtitle: 'All ${result.totalCount} milestones done',
                                dedupeKey: 'goal-complete:${goal.id}',
                              ));
                            } else {
                              events.add(CelebrationEvent(
                                type: CelebrationType.singleMilestone,
                                title: 'Milestone Complete!',
                                subtitle: '${result.completedCount} of ${result.totalCount} milestones',
                                dedupeKey: 'milestone:${goal.id}:${ms.id}',
                              ));
                            }
                            CelebrationController.instance.enqueue(events);
                          }
                        },
                        leading: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: ms.isCompleted
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(4),
                            color: ms.isCompleted
                                ? theme.colorScheme.primary
                                : Colors.transparent,
                          ),
                          child: ms.isCompleted
                              ? const Icon(
                                  Icons.check,
                                  size: 14,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        title: Text(
                          ms.title,
                          style: textTheme.bodyLarge?.copyWith(
                            decoration: ms.isCompleted ? TextDecoration.lineThrough : null,
                            color: ms.isCompleted
                                ? theme.colorScheme.onSurfaceVariant
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                        trailing: ms.targetDate != null
                            ? Text(
                                PhantomDateHelpers.formatDateShort(ms.targetDate!),
                                style: textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              )
                            : null,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // ── PRACTICES SECTION ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'RECURRING PRACTICES',
                    style: textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => _showAddPracticeDialog(context, goalId),
                    tooltip: 'Add Practice',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (activePractices.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Center(
                      child: Column(
                        children: [
                          Text(
                            'No practices defined.',
                            style: textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add recurring actions like "VAPT lab practice" or "DSA problem" to build consistency.',
                            style: textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _showAddPracticeDialog(context, goalId),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Practice'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                ...activePractices.map((practice) {
                  final thisWeekCount = checkInProvider.countForPracticeThisWeek(practice.id);
                  return PracticeTile(
                    practice: practice,
                    thisWeekCount: thisWeekCount,
                    onTap: () {
                      CheckInSheet.show(context, practiceId: practice.id, goalId: goalId);
                    },
                  );
                }),
              const SizedBox(height: 48),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatBadge({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.dataWhite,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
