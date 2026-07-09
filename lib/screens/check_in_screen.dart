import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phantom/models/check_in.dart';
import 'package:phantom/models/practice.dart';
import 'package:phantom/models/goal.dart';
import 'package:phantom/providers/check_in_provider.dart';
import 'package:phantom/providers/goal_provider.dart';
import 'package:phantom/providers/practice_provider.dart';
import 'package:phantom/utils/constants.dart';
import 'package:phantom/theme/app_theme.dart';

/// A bottom sheet for logging a check-in against a practice.
class CheckInSheet extends StatefulWidget {
  final String? preSelectedPracticeId;
  final String? preSelectedGoalId;

  const CheckInSheet({
    super.key,
    this.preSelectedPracticeId,
    this.preSelectedGoalId,
  });

  /// Displays the check-in bottom sheet.
  static Future<void> show(
    BuildContext context, {
    String? practiceId,
    String? goalId,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: CheckInSheet(
          preSelectedPracticeId: practiceId,
          preSelectedGoalId: goalId,
        ),
      ),
    );
  }

  @override
  State<CheckInSheet> createState() => _CheckInSheetState();
}

class _CheckInSheetState extends State<CheckInSheet> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();
  final _durationController = TextEditingController();

  String? _selectedGoalId;
  String? _selectedPracticeId;
  int _selectedEffortLevel = EffortLevel.moderate;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _selectedPracticeId = widget.preSelectedPracticeId;
    _selectedGoalId = widget.preSelectedGoalId;

    if (_selectedPracticeId != null && _selectedGoalId == null) {
      // Find the goal ID for this practice
      final practiceProvider = Provider.of<PracticeProvider>(context, listen: false);
      final practice = practiceProvider.getById(_selectedPracticeId!);
      if (practice != null) {
        _selectedGoalId = practice.goalId;
      }
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_selectedGoalId == null || _selectedPracticeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a practice to log.')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final duration = int.tryParse(_durationController.text.trim());

    final checkIn = CheckIn(
      goalId: _selectedGoalId!,
      practiceId: _selectedPracticeId!,
      note: _noteController.text.trim(),
      effortLevel: _selectedEffortLevel,
      durationMinutes: duration,
    );

    final checkInProvider = Provider.of<CheckInProvider>(context, listen: false);
    await checkInProvider.addCheckIn(checkIn);

    if (mounted) {
      setState(() {
        _isSuccess = true;
      });
      
      // Wait for the scale/fade checkmark animation to complete
      await Future.delayed(const Duration(milliseconds: 700));

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check-in logged successfully.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final goalProvider = Provider.of<GoalProvider>(context);
    final practiceProvider = Provider.of<PracticeProvider>(context);

    final activeGoals = goalProvider.activeGoals;
    final activePractices = practiceProvider.activePractices;

    // Group active practices by goal
    final Map<Goal, List<Practice>> goalPracticesMap = {};
    for (final goal in activeGoals) {
      final practices = activePractices.where((p) => p.goalId == goal.id).toList();
      if (practices.isNotEmpty) {
        goalPracticesMap[goal] = practices;
      }
    }

    final hasPreselected = widget.preSelectedPracticeId != null;
    Goal? preselectedGoal;
    Practice? preselectedPractice;

    if (hasPreselected) {
      preselectedPractice = practiceProvider.getById(widget.preSelectedPracticeId!);
      if (preselectedPractice != null) {
        preselectedGoal = goalProvider.getById(preselectedPractice.goalId);
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border.all(color: theme.colorScheme.outline, width: 1),
      ),
      padding: const EdgeInsets.all(20),
      child: _isSuccess
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 32),
                AnimatedScale(
                  scale: _isSuccess ? 1.0 : 0.5,
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeOutBack,
                  child: AnimatedOpacity(
                    opacity: _isSuccess ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: const Icon(
                      Icons.check_circle_outline,
                      size: 48,
                      color: AppTheme.onTrack,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Check-in logged',
                  style: textTheme.titleMedium?.copyWith(
                    color: AppTheme.dataWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
              ],
            )
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag Handle
                    Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Log Check-In',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Step 1: Practice Selection (if not preselected)
              if (hasPreselected && preselectedPractice != null && preselectedGoal != null) ...[
                Text(
                  'PRACTICE',
                  style: textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.colorScheme.outline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        preselectedPractice.title,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        preselectedGoal.title,
                        style: textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ] else ...[
                Text(
                  'SELECT PRACTICE',
                  style: textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),
                if (goalPracticesMap.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Text(
                      'No active practices. Add a practice to a goal first.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  )
                else
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView(
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      children: goalPracticesMap.entries.map((entry) {
                        final goal = entry.key;
                        final practices = entry.value;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6.0),
                              child: Text(
                                goal.title.toUpperCase(),
                                style: textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            ...practices.map((practice) {
                              final isSelected = _selectedPracticeId == practice.id;
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedPracticeId = practice.id;
                                    _selectedGoalId = goal.id;
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? theme.colorScheme.primaryContainer.withOpacity(0.2)
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.outline,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          practice.title,
                                          style: textTheme.bodyMedium?.copyWith(
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        Icon(
                                          Icons.check_circle,
                                          color: theme.colorScheme.primary,
                                          size: 20,
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(height: 12),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                const SizedBox(height: 20),
              ],

              // Step 2: Note Field
              Text(
                'WHAT DID YOU ACTUALLY DO? (REQUIRED)',
                style: textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _noteController,
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'A one-line log note is required.';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  hintText: 'e.g. Completed VAPT lab on port scanning, solved 2 DSA questions on Trees',
                ),
              ),
              const SizedBox(height: 20),

              // Step 3: Effort Level Selector
              Text(
                'EFFORT LEVEL',
                style: textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildEffortButton(
                      context,
                      level: EffortLevel.light,
                      label: 'Light',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildEffortButton(
                      context,
                      level: EffortLevel.moderate,
                      label: 'Moderate',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildEffortButton(
                      context,
                      level: EffortLevel.deep,
                      label: 'Deep',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Step 4: Duration (Optional)
              Text(
                'DURATION (OPTIONAL)',
                style: textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _durationController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'Duration',
                        suffixText: 'minutes',
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (int.tryParse(value) == null) {
                            return 'Enter a valid number';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Log Check-in'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEffortButton(
    BuildContext context, {
    required int level,
    required String label,
  }) {
    final theme = Theme.of(context);
    final isSelected = _selectedEffortLevel == level;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedEffortLevel = level;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer.withOpacity(0.2)
              : Colors.transparent,
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
