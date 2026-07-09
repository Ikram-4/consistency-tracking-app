import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:phantom/models/check_in.dart';
import 'package:phantom/models/goal.dart';
import 'package:phantom/providers/check_in_provider.dart';
import 'package:phantom/providers/goal_provider.dart';
import 'package:phantom/providers/stats_provider.dart';
import 'package:phantom/widgets/heatmap_grid.dart';
import 'package:phantom/widgets/empty_state.dart';
import 'package:phantom/utils/date_helpers.dart';
import 'package:phantom/utils/constants.dart';

/// Screen showing consistency visualizations: Heatmap Grid and Analytics charts.
class HeatmapScreen extends StatefulWidget {
  const HeatmapScreen({super.key});

  @override
  State<HeatmapScreen> createState() => _HeatmapScreenState();
}

class _HeatmapScreenState extends State<HeatmapScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _selectedDomainFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final goalProvider = Provider.of<GoalProvider>(context);
    final checkInProvider = Provider.of<CheckInProvider>(context);
    final statsProvider = Provider.of<StatsProvider>(context);

    final checkIns = checkInProvider.checkIns;
    final activeGoals = goalProvider.activeGoals;

    // Build filter list
    final List<String> domainFilters = ['All', ...goalProvider.allDomains];

    // Filter check-ins by selected domain
    List<CheckIn> filteredCheckIns = checkIns;
    if (_selectedDomainFilter != 'All') {
      final goalIdsInDomain = goalProvider.goals
          .where((g) => g.domain.toLowerCase() == _selectedDomainFilter.toLowerCase())
          .map((g) => g.id)
          .toSet();
      filteredCheckIns = checkIns.where((c) => goalIdsInDomain.contains(c.goalId)).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Consistency & Stats'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          tabs: const [
            Tab(text: 'Grid View'),
            Tab(text: 'Analytics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Tab 1: Heatmap Grid View ──
          filteredCheckIns.isEmpty && checkIns.isEmpty
              ? const EmptyState(
                  icon: Icons.grid_view_outlined,
                  title: 'No activity logged yet',
                  subtitle: 'Your contribution heatmap grid will compile as you log practices.',
                )
              : _buildGridView(
                  context,
                  theme,
                  textTheme,
                  domainFilters,
                  filteredCheckIns,
                ),

          // ── Tab 2: Analytics Charts ──
          checkIns.isEmpty
              ? const EmptyState(
                  icon: Icons.bar_chart_outlined,
                  title: 'No statistics available',
                  subtitle: 'Analytics charts will render once check-ins are logged.',
                )
              : _buildAnalyticsView(
                  context,
                  theme,
                  textTheme,
                  activeGoals,
                  checkIns,
                  statsProvider,
                ),
        ],
      ),
    );
  }

  Widget _buildGridView(
    BuildContext context,
    ThemeData theme,
    TextTheme textTheme,
    List<String> domainFilters,
    List<CheckIn> filteredCheckIns,
  ) {
    // Shading stats
    int lightLogs = filteredCheckIns.where((c) => c.effortLevel == EffortLevel.light).length;
    int moderateLogs = filteredCheckIns.where((c) => c.effortLevel == EffortLevel.moderate).length;
    int deepLogs = filteredCheckIns.where((c) => c.effortLevel == EffortLevel.deep).length;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Domain Filter
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'FILTER BY DOMAIN',
              style: textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            DropdownButton<String>(
              value: _selectedDomainFilter,
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedDomainFilter = val;
                  });
                }
              },
              underline: const SizedBox(),
              items: domainFilters.map((String filter) {
                return DropdownMenuItem<String>(
                  value: filter,
                  child: Text(filter),
                );
              }).toList(),
            ),
          ],
        ),
        const Divider(height: 16),
        const SizedBox(height: 12),

        // Heatmap Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '16-WEEK CONSISTENCY MATRIX',
                  style: textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                HeatmapGrid(checkIns: filteredCheckIns),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Effort Stats Summary
        Text(
          'LOG EFFORT SESSIONS',
          style: textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildSmallStatTile(
                context,
                label: 'Light Work',
                value: '$lightLogs',
                color: theme.colorScheme.primary.withOpacity(0.4),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSmallStatTile(
                context,
                label: 'Moderate',
                value: '$moderateLogs',
                color: theme.colorScheme.primary.withOpacity(0.7),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSmallStatTile(
                context,
                label: 'Deep Focus',
                value: '$deepLogs',
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnalyticsView(
    BuildContext context,
    ThemeData theme,
    TextTheme textTheme,
    List<Goal> activeGoals,
    List<CheckIn> checkIns,
    StatsProvider statsProvider,
  ) {
    final totalSessions = statsProvider.totalSessions(checkIns);
    final totalMins = statsProvider.totalMinutes(checkIns);
    final totalHours = (totalMins / 60.0).toStringAsFixed(1);

    // Effort deep work ratio
    final deepCount = checkIns.where((c) => c.effortLevel == EffortLevel.deep).length;
    final deepRatio = totalSessions > 0
        ? '${(deepCount / totalSessions * 100).toStringAsFixed(0)}%'
        : '0%';

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Global summaries
        Row(
          children: [
            Expanded(
              child: _buildAnalyticHeaderTile(
                context,
                label: 'TOTAL LOGGED HOURS',
                value: totalHours,
                icon: Icons.schedule_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildAnalyticHeaderTile(
                context,
                label: 'DEEP WORK RATIO',
                value: deepRatio,
                icon: Icons.psychology_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Line Chart: Weekly Consistency
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WEEKLY ACTIVITY TREND (12 WEEKS)',
                  style: textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 180,
                  child: _buildLineChart(theme, checkIns, statsProvider),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Bar Chart: Sessions per Domain
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SESSIONS BY DOMAIN',
                  style: textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 180,
                  child: _buildBarChart(theme, activeGoals, checkIns, statsProvider),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSmallStatTile(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(label, style: theme.textTheme.bodySmall?.copyWith(fontSize: 10)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticHeaderTile(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          children: [
            Icon(icon, size: 28, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
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

  Widget _buildLineChart(
    ThemeData theme,
    List<CheckIn> checkIns,
    StatsProvider statsProvider,
  ) {
    // Retrieve data (last 12 weeks)
    final rawMap = statsProvider.checkInsPerWeek(checkIns, weeks: 12);
    final sortedKeys = rawMap.keys.toList()..sort();

    if (sortedKeys.isEmpty) return const Center(child: Text('No data'));

    final List<FlSpot> spots = [];
    for (int i = 0; i < sortedKeys.length; i++) {
      spots.add(FlSpot(i.toDouble(), rawMap[sortedKeys[i]]!.toDouble()));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: theme.colorScheme.outline.withOpacity(0.15),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx >= 0 && idx < sortedKeys.length) {
                  // Only display label every 3 weeks to avoid cluttering
                  if (idx % 3 == 0 || idx == sortedKeys.length - 1) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text(
                        PhantomDateHelpers.formatDateShort(sortedKeys[idx]),
                        style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontSize: 9),
                      ),
                    );
                  }
                }
                return const SizedBox();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: theme.colorScheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: theme.colorScheme.primary.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(
    ThemeData theme,
    List<Goal> activeGoals,
    List<CheckIn> checkIns,
    StatsProvider statsProvider,
  ) {
    // Retrieve data
    final rawMap = statsProvider.sessionsPerDomain(activeGoals, checkIns);
    final sortedDomains = rawMap.keys.toList()
      ..sort((a, b) => rawMap[b]!.compareTo(rawMap[a]!)); // Sort descending count

    if (sortedDomains.isEmpty) return const Center(child: Text('No data'));



    final List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < sortedDomains.length && i < 5; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: rawMap[sortedDomains[i]]!.toDouble(),
              color: theme.colorScheme.primary,
              width: 14,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: theme.colorScheme.outline.withOpacity(0.15),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx >= 0 && idx < sortedDomains.length && idx < 5) {
                  final domain = sortedDomains[idx];
                  final label = domain.length > 8 ? '${domain.substring(0, 7)}..' : domain;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
      ),
    );
  }
}
