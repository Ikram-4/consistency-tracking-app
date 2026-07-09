import 'package:flutter/material.dart';
import 'package:phantom/screens/dashboard_screen.dart';
import 'package:phantom/screens/goals_screen.dart';
import 'package:phantom/screens/heatmap_screen.dart';
import 'package:phantom/screens/history_screen.dart';
import 'package:phantom/screens/check_in_screen.dart';

/// Home screen serving as the app's navigation shell.
///
/// Contains a [BottomNavigationBar] with four tabs (Dashboard, Goals,
/// Heatmap, History) and a centered floating action button for quick
/// check-in entry. Uses [IndexedStack] to preserve tab state across
/// navigation.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    GoalsScreen(),
    HeatmapScreen(),
    HistoryScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onCheckInPressed() {
    CheckInSheet.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onCheckInPressed,
        tooltip: 'Check In',
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: theme.colorScheme.surface,
        elevation: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              _buildNavItem(
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard,
                label: 'Home',
                index: 0,
                theme: theme,
              ),
              _buildNavItem(
                icon: Icons.flag_outlined,
                activeIcon: Icons.flag,
                label: 'Goals',
                index: 1,
                theme: theme,
              ),
              const SizedBox(width: 48), // Space for centered FAB
              _buildNavItem(
                icon: Icons.grid_view_outlined,
                activeIcon: Icons.grid_view,
                label: 'Grid',
                index: 2,
                theme: theme,
              ),
              _buildNavItem(
                icon: Icons.history_outlined,
                activeIcon: Icons.history,
                label: 'Logs',
                index: 3,
                theme: theme,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a single navigation item for the bottom app bar, centered and scaled to avoid overflow.
  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required ThemeData theme,
  }) {
    final isSelected = _currentIndex == index;
    final color = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withOpacity(0.5);

    return Expanded(
      child: InkWell(
        onTap: () => _onTabTapped(index),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: color,
                size: 20, // More compact, elegant sizing
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 9, // Small, precise labels matching Things 3 style
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
