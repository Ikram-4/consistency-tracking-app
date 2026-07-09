import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phantom/providers/goal_provider.dart';
import 'package:phantom/providers/practice_provider.dart';
import 'package:phantom/providers/check_in_provider.dart';
import 'package:phantom/providers/stats_provider.dart';
import 'package:phantom/widgets/goal_card.dart';
import 'package:phantom/widgets/empty_state.dart';
import 'package:phantom/screens/goal_form_screen.dart';
import 'package:phantom/screens/goal_detail_screen.dart';

/// Screen listing the user's active and archived goals.
class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const GoalFormScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer4<GoalProvider, PracticeProvider, CheckInProvider, StatsProvider>(
        builder: (context, goalProvider, practiceProvider, checkInProvider, statsProvider, child) {
          final activeGoals = goalProvider.activeGoals;
          final archivedGoals = goalProvider.archivedGoals;

          if (activeGoals.isEmpty && archivedGoals.isEmpty) {
            return EmptyState(
              icon: Icons.flag_outlined,
              title: 'No Goals Defined',
              subtitle: 'Define a skill-development goal with milestones and practices to track.',
              actionLabel: 'Create Goal',
              onAction: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const GoalFormScreen(),
                  ),
                );
              },
            );
          }

          // Sort active goals by targetDate ascending
          final sortedActiveGoals = List.of(activeGoals)
            ..sort((a, b) => a.targetDate.compareTo(b.targetDate));

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              if (sortedActiveGoals.isNotEmpty) ...[
                Text(
                  'ACTIVE',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sortedActiveGoals.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final goal = sortedActiveGoals[index];
                    final totalCheckIns = checkInProvider.totalCountForGoal(goal.id);
                    final practices = practiceProvider.getByGoalId(goal.id);
                    final checkIns = checkInProvider.getByGoalId(goal.id);

                    final paceData = StatsProvider.calculatePace(
                      goal: goal,
                      practices: practices,
                      checkIns: checkIns,
                    );

                    return GoalCard(
                      goal: goal,
                      totalCheckIns: totalCheckIns,
                      paceData: paceData,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => GoalDetailScreen(goalId: goal.id),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
              if (archivedGoals.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'ARCHIVED',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: archivedGoals.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final goal = archivedGoals[index];
                    final totalCheckIns = checkInProvider.totalCountForGoal(goal.id);

                    return Opacity(
                      opacity: 0.6,
                      child: GoalCard(
                        goal: goal,
                        totalCheckIns: totalCheckIns,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => GoalDetailScreen(goalId: goal.id),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
