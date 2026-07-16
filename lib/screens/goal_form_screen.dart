import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phantom/models/goal.dart';
import 'package:phantom/models/milestone.dart';
import 'package:phantom/providers/goal_provider.dart';
import 'package:phantom/utils/constants.dart';
import 'package:phantom/utils/date_helpers.dart';

/// Screen for creating and editing a goal.
class GoalFormScreen extends StatefulWidget {
  final Goal? goal;

  const GoalFormScreen({super.key, this.goal});

  @override
  State<GoalFormScreen> createState() => _GoalFormScreenState();
}

class _GoalFormScreenState extends State<GoalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late final TextEditingController _titleController;
  late final TextEditingController _domainController;
  late final TextEditingController _whyController;
  late final TextEditingController _targetCountController;

  DateTime? _selectedTargetDate;
  final List<Milestone> _milestones = [];
  late HabitProfile _selectedProfile;

  bool get _isEditMode => widget.goal != null;

  @override
  void initState() {
    super.initState();
    final g = widget.goal;

    _titleController = TextEditingController(text: g?.title ?? '');
    _domainController = TextEditingController(text: g?.domain ?? '');
    _whyController = TextEditingController(text: g?.whyStatement ?? '');
    _targetCountController = TextEditingController(
      text: g?.targetCount != null ? g!.targetCount.toString() : '',
    );

    _selectedTargetDate = g?.targetDate;
    _selectedProfile = g?.profile ?? HabitProfile.duration;
    if (g != null) {
      _milestones.addAll(g.milestones);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _domainController.dispose();
    _whyController.dispose();
    _targetCountController.dispose();
    super.dispose();
  }

  void _selectTargetDate() async {
    final now = DateTime.now();
    final initialDate = _selectedTargetDate ?? now.add(const Duration(days: 30));
    
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(now) ? now : initialDate,
      firstDate: now.subtract(const Duration(days: 365)), // allow edit of older goals
      lastDate: now.add(const Duration(days: 3650)),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedTargetDate = pickedDate;
      });
    }
  }

  void _addMilestone() {
    setState(() {
      _milestones.add(Milestone(title: ''));
    });
  }

  void _removeMilestone(int index) {
    setState(() {
      _milestones.removeAt(index);
    });
  }

  void _selectMilestoneDate(int index) async {
    final now = DateTime.now();
    final initialDate = _milestones[index].targetDate ?? now.add(const Duration(days: 14));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(now) ? now : initialDate,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 3650)),
    );

    if (pickedDate != null) {
      setState(() {
        _milestones[index] = _milestones[index].copyWith(targetDate: pickedDate);
      });
    }
  }

  void _submit() async {
    if (_selectedTargetDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a target date.')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final targetCount = int.tryParse(_targetCountController.text.trim());

    // Clean up empty milestones
    final cleanedMilestones = _milestones
        .where((m) => m.title.trim().isNotEmpty)
        .map((m) => m.copyWith(title: m.title.trim()))
        .toList();

    final goalProvider = Provider.of<GoalProvider>(context, listen: false);

    if (_isEditMode) {
      final updatedGoal = widget.goal!.copyWith(
        title: _titleController.text.trim(),
        domain: _domainController.text.trim(),
        targetDate: _selectedTargetDate!,
        whyStatement: _whyController.text.trim().isEmpty ? null : _whyController.text.trim(),
        targetCount: targetCount,
        milestones: cleanedMilestones,
        profile: _selectedProfile,
      );
      await goalProvider.updateGoal(updatedGoal);
    } else {
      final newGoal = Goal(
        title: _titleController.text.trim(),
        domain: _domainController.text.trim(),
        targetDate: _selectedTargetDate!,
        whyStatement: _whyController.text.trim().isEmpty ? null : _whyController.text.trim(),
        targetCount: targetCount,
        milestones: cleanedMilestones,
        profile: _selectedProfile,
      );
      await goalProvider.addGoal(newGoal);
    }

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditMode ? 'Goal updated successfully.' : 'Goal created successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final goalProvider = Provider.of<GoalProvider>(context);
    final existingDomains = goalProvider.allDomains;
    
    // Combine unique domains from user goals and defaults
    final List<String> domainSuggestions = {
      ...existingDomains,
      ...AppConstants.defaultDomainSuggestions,
    }.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Goal' : 'New Goal'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Goal Title
              Text(
                'GOAL TITLE',
                style: textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title is required.';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  hintText: 'e.g. Finish HTB CWES path',
                ),
              ),
              const SizedBox(height: 24),

              // Domain autocomplete
              Text(
                'DOMAIN / CATEGORY',
                style: textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return domainSuggestions;
                  }
                  return domainSuggestions.where((option) {
                    return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                  });
                },
                onSelected: (String selection) {
                  _domainController.text = selection;
                },
                fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                  // Link input value to parent controller
                  if (textEditingController.text != _domainController.text && _domainController.text.isNotEmpty) {
                    textEditingController.text = _domainController.text;
                  }
                  textEditingController.addListener(() {
                    _domainController.text = textEditingController.text;
                  });

                  return TextFormField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    onFieldSubmitted: (val) => onFieldSubmitted(),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Domain is required.';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      hintText: 'e.g. Cybersecurity, DSA, Mobile Dev',
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Target Date Picker
              Text(
                'TARGET DATE',
                style: textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectTargetDate,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.colorScheme.outline),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedTargetDate != null
                              ? PhantomDateHelpers.formatDate(_selectedTargetDate!)
                              : 'Select target date',
                          style: textTheme.bodyLarge?.copyWith(
                            color: _selectedTargetDate != null
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Target Count (Optional)
              Text(
                'TARGET COUNT (OPTIONAL)',
                style: textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _targetCountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'e.g. 150 (for numeric goals like DSA problems)',
                  helperText: 'Set this if progress is tracked by cumulative check-in counts.',
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (int.tryParse(value) == null) {
                      return 'Enter a valid number.';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Why Statement (Optional)
              Text(
                'WHY STATEMENT (OPTIONAL)',
                style: textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _whyController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Why does this goal matter to you? Keep it serious.',
                ),
              ),
              const SizedBox(height: 24),

              // Tuning Profile / Style
              Text(
                'HABIT PROFILE / TUNING STYLE',
                style: textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<HabitProfile>(
                value: _selectedProfile,
                onChanged: (HabitProfile? val) {
                  if (val != null) {
                    setState(() {
                      _selectedProfile = val;
                    });
                  }
                },
                items: HabitProfile.values.map((profile) {
                  final name = profile.name[0].toUpperCase() + profile.name.substring(1);
                  return DropdownMenuItem<HabitProfile>(
                    value: profile,
                    child: Text(name),
                  );
                }).toList(),
                decoration: const InputDecoration(
                  helperText: 'Controls how check-in weights affect consistency math.',
                ),
              ),
              const SizedBox(height: 12),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _getProfileIcon(_selectedProfile),
                      color: _getProfileColor(context, _selectedProfile),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getProfileTitle(_selectedProfile),
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getProfileDescription(_selectedProfile),
                            style: textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Milestones Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'MILESTONES / CHECKPOINTS',
                    style: textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addMilestone,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_milestones.isEmpty)
                Text(
                  'No milestones added yet. Milestones serve as primary progress indicators.',
                  style: textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _milestones.length,
                  itemBuilder: (context, index) {
                    final ms = _milestones[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      key: ValueKey(ms.id),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: ms.title,
                              onChanged: (val) {
                                _milestones[index] = ms.copyWith(title: val);
                              },
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Title required.';
                                }
                                return null;
                              },
                              decoration: const InputDecoration(
                                hintText: 'Milestone title',
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Milestone Date picker
                          InkWell(
                            onTap: () => _selectMilestoneDate(index),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest,
                                border: Border.all(color: theme.colorScheme.outline),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    size: 16,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  if (ms.targetDate != null) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      PhantomDateHelpers.formatDateShort(ms.targetDate!),
                                      style: textTheme.bodySmall,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            color: theme.colorScheme.error,
                            onPressed: () => _removeMilestone(index),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 48),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: Text(_isEditMode ? 'Update Goal' : 'Create Goal'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getProfileIcon(HabitProfile profile) {
    switch (profile) {
      case HabitProfile.intensity:
        return Icons.local_fire_department;
      case HabitProfile.duration:
        return Icons.hourglass_empty;
      case HabitProfile.singleSession:
        return Icons.check_circle_outline;
      case HabitProfile.frequency:
        return Icons.repeat;
    }
  }

  Color _getProfileColor(BuildContext context, HabitProfile profile) {
    final theme = Theme.of(context);
    switch (profile) {
      case HabitProfile.intensity:
        return Colors.orangeAccent;
      case HabitProfile.duration:
        return theme.colorScheme.primary;
      case HabitProfile.singleSession:
        return Colors.green;
      case HabitProfile.frequency:
        return theme.colorScheme.secondary;
    }
  }

  String _getProfileTitle(HabitProfile profile) {
    switch (profile) {
      case HabitProfile.intensity:
        return 'Intensity Style';
      case HabitProfile.duration:
        return 'Duration Style (Default)';
      case HabitProfile.singleSession:
        return 'Single Session Style';
      case HabitProfile.frequency:
        return 'Frequency Style';
    }
  }

  String _getProfileDescription(HabitProfile profile) {
    switch (profile) {
      case HabitProfile.intensity:
        return 'Best for workouts or gym. Higher consistency ceiling (4.0); multiple sessions in a day yield substantial focus boosts.';
      case HabitProfile.duration:
        return 'Best for study or reading. Progress scales steadily with the time and effort you invest in your study sessions.';
      case HabitProfile.singleSession:
        return 'Best for meditation or vitamins. Logging a check-in once gives near-maximum credit; extra logs do not add more progress.';
      case HabitProfile.frequency:
        return 'Best for drinking water or posture checks. Many small checks build consistency quickly, so small actions add up fast.';
    }
  }
}
