import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phantom/providers/check_in_provider.dart';
import 'package:phantom/providers/goal_provider.dart';
import 'package:phantom/providers/practice_provider.dart';
import 'package:phantom/widgets/check_in_tile.dart';
import 'package:phantom/widgets/empty_state.dart';
import 'package:phantom/utils/date_helpers.dart';

/// Screen displaying searchable and filterable history logs of all check-ins.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _searchController = TextEditingController();
  String _selectedDomain = 'All';
  DateTimeRange? _selectedDateRange;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectDateRange() async {
    final now = DateTime.now();
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 30)),
      initialDateRange: _selectedDateRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 7)),
            end: now,
          ),
    );

    if (pickedRange != null) {
      setState(() {
        _selectedDateRange = pickedRange;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedDomain = 'All';
      _selectedDateRange = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final checkInProvider = Provider.of<CheckInProvider>(context);
    final goalProvider = Provider.of<GoalProvider>(context);
    final practiceProvider = Provider.of<PracticeProvider>(context);

    // List of unique domains for filtering
    final domains = ['All', ...goalProvider.allDomains];

    // Filter check-ins locally for responsiveness
    final query = _searchController.text.trim().toLowerCase();
    
    final filteredCheckIns = checkInProvider.checkIns.where((checkIn) {
      // 1. Text Search filter
      if (query.isNotEmpty && !checkIn.note.toLowerCase().contains(query)) {
        return false;
      }

      // Find the attached goal to get the domain
      final goal = goalProvider.getById(checkIn.goalId);
      
      // 2. Domain filter
      if (_selectedDomain != 'All') {
        if (goal == null || goal.domain.toLowerCase() != _selectedDomain.toLowerCase()) {
          return false;
        }
      }

      // 3. Date Range filter
      if (_selectedDateRange != null) {
        // Zero out times for date comparison
        final start = DateTime(_selectedDateRange!.start.year, _selectedDateRange!.start.month, _selectedDateRange!.start.day);
        final end = DateTime(_selectedDateRange!.end.year, _selectedDateRange!.end.month, _selectedDateRange!.end.day, 23, 59, 59);
        if (checkIn.timestamp.isBefore(start) || checkIn.timestamp.isAfter(end)) {
          return false;
        }
      }

      return true;
    }).toList()
      // Sort newest first
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final hasActiveFilters = query.isNotEmpty || _selectedDomain != 'All' || _selectedDateRange != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Check-In Log'),
        actions: [
          if (hasActiveFilters)
            TextButton(
              onPressed: _clearFilters,
              child: const Text('Clear'),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── FILTER BAR ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            color: theme.colorScheme.surface,
            child: Column(
              children: [
                // Search Input
                TextFormField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {}); // trigger filtering rebuild
                  },
                  decoration: InputDecoration(
                    hintText: 'Search logged notes...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 10),

                // Dropdowns and Date pickers
                Row(
                  children: [
                    // Domain Filter dropdown
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.colorScheme.outline),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedDomain,
                            isExpanded: true,
                            hint: const Text('Domain'),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedDomain = val;
                                });
                              }
                            },
                            items: domains.map((domain) {
                              return DropdownMenuItem<String>(
                                value: domain,
                                child: Text(domain),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Date range picker trigger
                    Expanded(
                      child: InkWell(
                        onTap: _selectDateRange,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _selectedDateRange != null
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outline,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.date_range_outlined,
                                size: 18,
                                color: _selectedDateRange != null
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selectedDateRange != null
                                      ? '${PhantomDateHelpers.formatDateShort(_selectedDateRange!.start)} - ${PhantomDateHelpers.formatDateShort(_selectedDateRange!.end)}'
                                      : 'Date Range',
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: _selectedDateRange != null
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── HISTORY LIST ──
          Expanded(
            child: filteredCheckIns.isEmpty
                ? (hasActiveFilters
                    ? EmptyState(
                        icon: Icons.search_off_outlined,
                        title: 'No search results',
                        subtitle: 'No logs match your current search terms or active filters.',
                        actionLabel: 'Reset Filters',
                        onAction: _clearFilters,
                      )
                    : const EmptyState(
                        icon: Icons.history_outlined,
                        title: 'No check-ins logged yet',
                        subtitle: 'Log a practice from a goal details view or bottom check-in sheet.',
                      ))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                    itemCount: filteredCheckIns.length,
                    itemBuilder: (context, index) {
                      final checkIn = filteredCheckIns[index];
                      final practice = practiceProvider.getById(checkIn.practiceId);
                      final goal = goalProvider.getById(checkIn.goalId);

                      return CheckInTile(
                        checkIn: checkIn,
                        practice: practice,
                        goal: goal,
                        onDelete: () async {
                          await checkInProvider.deleteCheckIn(checkIn.id);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
