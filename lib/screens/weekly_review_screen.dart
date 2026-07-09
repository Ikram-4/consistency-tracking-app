import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phantom/models/weekly_review.dart';
import 'package:phantom/models/practice.dart';
import 'package:phantom/providers/weekly_review_provider.dart';
import 'package:phantom/providers/practice_provider.dart';
import 'package:phantom/providers/check_in_provider.dart';
import 'package:phantom/providers/goal_provider.dart';
import 'package:phantom/utils/date_helpers.dart';

/// Screen guiding the user through reflecting on their week and adjusting practice targets.
class WeeklyReviewScreen extends StatefulWidget {
  const WeeklyReviewScreen({super.key});

  @override
  State<WeeklyReviewScreen> createState() => _WeeklyReviewScreenState();
}

class _WeeklyReviewScreenState extends State<WeeklyReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _whatWorkedController = TextEditingController();
  final _whatDidntController = TextEditingController();

  // Maps practiceId to adjusted target
  final Map<String, int> _targetAdjustments = {};

  @override
  void dispose() {
    _whatWorkedController.dispose();
    _whatDidntController.dispose();
    super.dispose();
  }

  void _submit(
    List<Practice> activePractices,
    WeeklyReviewProvider reviewProvider,
    PracticeProvider practiceProvider,
  ) async {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final weekStart = PhantomDateHelpers.weekStart(now);

    // 1. Create Weekly Review Entry
    final review = WeeklyReview(
      weekStartDate: weekStart,
      whatWorked: _whatWorkedController.text.trim(),
      whatDidnt: _whatDidntController.text.trim(),
      adjustments: Map<String, int>.from(_targetAdjustments),
    );

    await reviewProvider.saveReview(review);

    // 2. Apply target adjustments directly to practices
    for (final entry in _targetAdjustments.entries) {
      final practiceId = entry.key;
      final newTarget = entry.value;

      final practice = practiceProvider.getById(practiceId);
      if (practice != null && practice.weeklyTarget != newTarget) {
        await practiceProvider.updatePractice(
          practice.copyWith(weeklyTarget: newTarget),
        );
      }
    }

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Weekly review saved and targets adjusted.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final now = DateTime.now();
    final weekStart = PhantomDateHelpers.weekStart(now);
    final weekEnd = PhantomDateHelpers.weekEnd(now);

    final reviewProvider = Provider.of<WeeklyReviewProvider>(context);
    final practiceProvider = Provider.of<PracticeProvider>(context);
    final checkInProvider = Provider.of<CheckInProvider>(context);
    final goalProvider = Provider.of<GoalProvider>(context);

    final activePractices = practiceProvider.activePractices;

    // Initialize targets map if not done
    if (_targetAdjustments.isEmpty && activePractices.isNotEmpty) {
      for (final practice in activePractices) {
        _targetAdjustments[practice.id] = practice.weeklyTarget;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Review'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            // Week range banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.1),
                border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_month_outlined, color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Review for: ${PhantomDateHelpers.formatDateShort(weekStart)} - ${PhantomDateHelpers.formatDateShort(weekEnd)}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Step 1: Reflections
            Text(
              'WEEKLY REFLECTIONS',
              style: textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'What worked this week?',
              style: textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _whatWorkedController,
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Reflection is required.';
                }
                return null;
              },
              decoration: const InputDecoration(
                hintText: 'What strategies or systems helped you build consistency?',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'What didn\'t work?',
              style: textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _whatDidntController,
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Reflection is required.';
                }
                return null;
              },
              decoration: const InputDecoration(
                hintText: 'What friction points did you face? Where did you fall behind?',
              ),
            ),
            const SizedBox(height: 32),

            // Step 2: Practice Target Adjustments
            Text(
              'ADJUST NEXT WEEK\'S TARGETS',
              style: textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Increase targets if on track, or decrease them temporarily to build small consistency loops.',
              style: textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (activePractices.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Center(
                    child: Text(
                      'No active practices to adjust.',
                      style: textTheme.bodyMedium,
                    ),
                  ),
                ),
              )
            else
              ...activePractices.map((practice) {
                final thisWeekCount = checkInProvider.countForPracticeThisWeek(practice.id);
                final goal = goalProvider.getById(practice.goalId);
                final currentAdjustedValue = _targetAdjustments[practice.id] ?? practice.weeklyTarget;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  color: theme.colorScheme.surfaceContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    practice.title,
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (goal != null)
                                    Text(
                                      goal.title,
                                      style: textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Logged: $thisWeekCount / ${practice.weeklyTarget}',
                                style: textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          children: [
                            Text(
                              'Next Week Target:',
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            // Decrease target button
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: currentAdjustedValue > 1
                                  ? () {
                                      setState(() {
                                        _targetAdjustments[practice.id] = currentAdjustedValue - 1;
                                      });
                                    }
                                  : null,
                            ),
                            Container(
                              width: 32,
                              alignment: Alignment.center,
                              child: Text(
                                '$currentAdjustedValue',
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            // Increase target button
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: currentAdjustedValue < 7
                                  ? () {
                                      setState(() {
                                        _targetAdjustments[practice.id] = currentAdjustedValue + 1;
                                      });
                                    }
                                  : null,
                            ),
                            Text(
                              'x/week',
                              style: textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 48),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _submit(activePractices, reviewProvider, practiceProvider),
                child: const Text('Complete Weekly Review'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
