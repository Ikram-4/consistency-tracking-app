import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phantom/models/goal.dart';
import 'package:phantom/providers/goal_provider.dart';
import 'package:phantom/providers/practice_provider.dart';
import 'package:phantom/providers/check_in_provider.dart';
import 'package:phantom/providers/stats_provider.dart';
import 'package:phantom/providers/weekly_review_provider.dart';
import 'package:phantom/screens/weekly_review_screen.dart';
import 'package:phantom/widgets/empty_state.dart';
import 'package:phantom/screens/goal_detail_screen.dart';
import 'package:phantom/screens/goal_form_screen.dart';
import 'package:phantom/theme/app_theme.dart';
import 'package:phantom/utils/date_helpers.dart';

/// Standing Dashboard screen displaying a professional overview of the user's progress.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Standing Dashboard'),
      ),
      body: Consumer5<GoalProvider, PracticeProvider, CheckInProvider, StatsProvider, WeeklyReviewProvider>(
        builder: (context, goalProvider, practiceProvider, checkInProvider, statsProvider, weeklyReviewProvider, child) {
          final activeGoals = goalProvider.activeGoals;

          if (activeGoals.isEmpty) {
            return EmptyState(
              icon: Icons.dashboard_outlined,
              title: 'Welcome to Phantom',
              subtitle: 'Create a goal to begin tracking your skill-development consistency.',
              actionLabel: 'Define Goal',
              onAction: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const GoalFormScreen(),
                  ),
                );
              },
            );
          }

          // Compute global summary statistics
          int totalOnTrack = 0;
          int totalBehind = 0;
          int totalFallingOff = 0;
          int checkInsLast14Days = 0;

          final twoWeeksAgo = DateTime.now().subtract(const Duration(days: 14));
          final recentCheckIns = checkInProvider.checkIns.where(
            (c) => c.timestamp.isAfter(twoWeeksAgo),
          );
          checkInsLast14Days = recentCheckIns.length;

          final List<_GoalDashboardItem> items = [];

          for (final goal in activeGoals) {
            final practices = practiceProvider.getByGoalId(goal.id);
            final checkIns = checkInProvider.getByGoalId(goal.id);
            final totalCheckIns = checkInProvider.totalCountForGoal(goal.id);

            final pace = StatsProvider.calculatePace(
              goal: goal,
              practices: practices,
              checkIns: checkIns,
            );

            items.add(_GoalDashboardItem(
              goal: goal,
              totalCheckIns: totalCheckIns,
              pace: pace,
            ));

            switch (pace.status) {
              case TrackingStatus.onTrack:
                totalOnTrack++;
                break;
              case TrackingStatus.behind:
                totalBehind++;
                break;
              case TrackingStatus.fallingOff:
                totalFallingOff++;
                break;
            }
          }

          final weekStart = PhantomDateHelpers.weekStart(DateTime.now());
          final hasCompletedReview = weeklyReviewProvider.getByWeekStart(weekStart) != null;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              if (!hasCompletedReview) ...[
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                    border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2), width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.psychology_outlined, color: theme.colorScheme.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'WEEKLY REVIEW DUE',
                              style: textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Reflect on your progress this week, log what worked and what friction points you faced, and adjust next week\'s targets.',
                          style: textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.8),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const WeeklyReviewScreen(),
                                ),
                              );
                            },
                            child: const Text('Start Weekly Review'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              // ── GLOBAL STANDING METRICS ──
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      title: 'STANDING',
                      value: '$totalOnTrack / ${activeGoals.length}',
                      subtitle: '$totalBehind behind, $totalFallingOff falling off',
                      valueColor: totalOnTrack == activeGoals.length
                          ? AppTheme.onTrack
                          : (totalFallingOff > 0 ? AppTheme.fallingOff : AppTheme.behind),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      title: 'ACTIVITY',
                      value: '$checkInsLast14Days',
                      subtitle: 'Logs (last 14 days)',
                      valueColor: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Section Header
              Text(
                'GOAL STANDINGS',
                style: textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),

              // ── GOAL DASHBOARD CARDS ──
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final goal = goalProvider.getById(item.goal.id) ?? item.goal;
                  final pace = item.pace;

                  // Pacing status details
                  Color statusColor;
                  String statusText;
                  IconData statusIcon;

                  switch (pace.status) {
                    case TrackingStatus.onTrack:
                      statusColor = AppTheme.onTrack;
                      statusText = 'ON TRACK';
                      break;
                    case TrackingStatus.behind:
                      statusColor = AppTheme.behind;
                      statusText = 'BEHIND';
                      break;
                    case TrackingStatus.fallingOff:
                      statusColor = AppTheme.fallingOff;
                      statusText = 'FALLING OFF';
                      break;
                  }
                  statusIcon = AppTheme.statusIcon(statusText);

                  // Progress percent display
                  double displayProgress = 0.0;
                  final InlineSpan progressSpan;
                  switch (goal.progressType) {
                    case ProgressType.milestone:
                      displayProgress = goal.progressPercent;
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
                            text: '/ ${goal.milestones.length} ',
                            style: textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          TextSpan(
                            text: 'milestones',
                            style: textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      );
                      break;
                    case ProgressType.count:
                      final target = goal.targetCount ?? 1;
                      displayProgress = (item.totalCheckIns / target).clamp(0.0, 1.0);
                      progressSpan = TextSpan(
                        children: [
                          TextSpan(
                            text: '${item.totalCheckIns} ',
                            style: textTheme.labelSmall?.copyWith(
                              color: AppTheme.dataWhite,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: '/ $target ',
                            style: textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          TextSpan(
                            text: 'logs',
                            style: textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
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
                            style: textTheme.labelSmall?.copyWith(
                              color: AppTheme.dataWhite,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: 'time elapsed',
                            style: textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      );
                      break;
                  }

                  final dColor = AppTheme.domainColor(goal.domain);

                  return Container(
                    decoration: AppTheme.elevatedDecoration(), // Faint gradient top edge depth
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => GoalDetailScreen(goalId: goal.id),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Goal title, domain, standing status
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          goal.title,
                                          style: textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
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
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(AppTheme.controlRadius),
                                      border: Border.all(color: statusColor.withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(statusIcon, size: 14, color: statusColor),
                                        const SizedBox(width: 4),
                                        Text(
                                          statusText,
                                          style: textTheme.labelSmall?.copyWith(
                                            color: statusColor,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),

                              // Pacing metrics grid (Tabular high-contrast dataWhite numbers)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildMetricColumn(
                                    context,
                                    label: 'ACTUAL PACE',
                                    value: '${pace.actualPace.toStringAsFixed(1)} /wk',
                                    subtitle: 'Last 2 weeks',
                                  ),
                                  _buildMetricColumn(
                                    context,
                                    label: 'REQUIRED PACE',
                                    value: '${pace.requiredPace.toStringAsFixed(1)} /wk',
                                    subtitle: 'To finish on time',
                                  ),
                                  _buildMetricColumn(
                                    context,
                                    label: 'TIME LEFT',
                                    value: goal.daysRemaining >= 0
                                        ? '${(goal.daysRemaining / 7).ceil()} wks'
                                        : 'Expired',
                                    subtitle: goal.daysRemaining >= 0
                                        ? '${goal.daysRemaining} days'
                                        : 'Target passed',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Progress bar (Animated micro-interaction)
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
                                        backgroundColor: theme.colorScheme.outline.withOpacity(0.2),
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
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    goal.progressType == ProgressType.timeElapsed ? 'Time Elapsed' : 'Goal Progress',
                                    style: textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  Text.rich(
                                    progressSpan,
                                    style: textTheme.labelSmall,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required Color valueColor,
  }) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Container(
      decoration: AppTheme.elevatedDecoration(), // Faint gradient top edge depth
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: textTheme.headlineMedium?.copyWith(
                color: valueColor == theme.colorScheme.primary ? AppTheme.dataWhite : valueColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricColumn(
    BuildContext context, {
    required String label,
    required String value,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: textTheme.titleMedium?.copyWith(
            color: AppTheme.dataWhite, // Data contrast high-contrast tabular number
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _GoalDashboardItem {
  final Goal goal;
  final int totalCheckIns;
  final PaceData pace;

  _GoalDashboardItem({
    required this.goal,
    required this.totalCheckIns,
    required this.pace,
  });
}
