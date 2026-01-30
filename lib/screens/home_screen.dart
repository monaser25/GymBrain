import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/gym_models.dart';
import '../services/database_service.dart';
import 'package:provider/provider.dart';
// Screens
import 'active_workout_screen.dart';
import 'progress_screen.dart';
import 'routines_screen.dart';
import 'settings_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'tools_screen.dart';
// Note: RoutineEditorScreen import might be needed if we link directly,
// but RoutinesScreen handles that.

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  late final List<Widget> _pages = [
    _DashboardView(
      onSwitchTab: (index) => setState(() => _currentIndex = index),
    ),
    const RoutinesScreen(),
    const ProgressScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      drawer: _buildDrawer(context),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const TextStyle(
                  color: Color(0xFF39FF14),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                );
              }
              return const TextStyle(color: Colors.grey, fontSize: 12);
            }),
            indicatorColor: const Color(0xFF39FF14).withValues(alpha: 0.2),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const IconThemeData(color: Color(0xFF39FF14));
              }
              return const IconThemeData(color: Colors.grey);
            }),
          ),
          child: NavigationBar(
            height: 65,
            backgroundColor: Colors.black,
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) =>
                setState(() => _currentIndex = index),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard, color: Color(0xFF39FF14)),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.fitness_center_outlined),
                selectedIcon: Icon(
                  Icons.fitness_center,
                  color: Color(0xFF39FF14),
                ),
                label: 'Workout',
              ),
              NavigationDestination(
                icon: Icon(Icons.show_chart),
                selectedIcon: Icon(Icons.show_chart, color: Color(0xFF39FF14)),
                label: 'Stats',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings, color: Color(0xFF39FF14)),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF1C1C1E),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drawer Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF39FF14).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.fitness_center,
                      color: Color(0xFF39FF14),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Gym Brain",
                        style: TextStyle(
                          color: Color(0xFF39FF14),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Tools & Utilities",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 1RM Calculator
            _buildDrawerTile(
              context: context,
              icon: Icons.calculate_outlined,
              label: "1RM Calculator",
              emoji: "🔢",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ToolsScreen(initialTab: 0),
                  ),
                );
              },
            ),

            // Plate Calculator
            _buildDrawerTile(
              context: context,
              icon: Icons.donut_large_outlined,
              label: "Plate Calculator",
              emoji: "💿",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ToolsScreen(initialTab: 1),
                  ),
                );
              },
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Divider(color: Colors.white10),
            ),

            // Settings
            _buildDrawerTile(
              context: context,
              icon: Icons.settings_outlined,
              label: "Settings",
              emoji: "⚙️",
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 3); // Switch to Settings tab
              },
            ),

            const Spacer(),

            // Footer
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                "Version 1.0.0",
                style: TextStyle(color: Colors.grey[700], fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String emoji,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 20)),
      ),
      title: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[600], size: 20),
      onTap: onTap,
    );
  }
}

class _DashboardView extends StatelessWidget {
  final Function(int) onSwitchTab;
  const _DashboardView({required this.onSwitchTab});

  @override
  Widget build(BuildContext context) {
    // Date Header
    final dateString = DateFormat('EEEE, MMM d').format(DateTime.now());

    return Consumer<GymDatabase>(
      builder: (context, db, child) {
        // Fetch Last Workout
        final sessions = db.getSessions();
        final lastSession = sessions.isNotEmpty ? sessions.first : null;

        String lastWorkoutTitle = "No workouts yet";
        String lastWorkoutTime = "--";

        if (lastSession != null) {
          lastWorkoutTitle = lastSession.routineName;
          lastWorkoutTime = _timeAgo(lastSession.date);
        }

        // Fetch Weight
        final lastInBody = db.getLatestInBody();
        final weightString = lastInBody != null
            ? "${lastInBody.weight} kg"
            : "--";

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Clean Header (Date)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          // Menu Button for Drawer
                          GestureDetector(
                            onTap: () {
                              Scaffold.of(context).openDrawer();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1C1C1E),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.menu,
                                color: Color(0xFF39FF14),
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Gym Brain",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dateString,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProfileScreen(),
                            ),
                          );
                        },
                        child: const CircleAvatar(
                          radius: 24,
                          backgroundColor: Color(0xFF1C1C1E),
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // 2. Data Cards
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            // Use full path or need import. I'll add import in next step or assume user's compilation.
                            // I will add the import at top of file in a separate call if needed, but I can't do two ranges.
                            // I will assume the user wants me to fix navigation.
                            // I'll use a dynamic route or just the class name and fix import later.
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const HistoryScreen(),
                              ),
                            );
                          },
                          child: _SummaryCard(
                            title: 'Last Workout',
                            value: lastWorkoutTitle,
                            subtitle: lastWorkoutTime,
                            icon: Icons.history,
                            color: const Color(0xFF39FF14), // Neon Green
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            onSwitchTab(2); // Switch to Stats (Index 2)
                          },
                          child: _SummaryCard(
                            title: 'Current Weight',
                            value: weightString,
                            subtitle: lastInBody != null
                                ? DateFormat('MMM d').format(lastInBody.date)
                                : "",
                            icon: Icons.monitor_weight_outlined,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 50),

                  // 3. Glowing Start Button
                  Center(
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF39FF14,
                            ).withValues(alpha: 0.3), // Neon Glow
                            blurRadius: 40,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () => _showRoutineSelectorSheet(context),
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          backgroundColor: Colors.black, // Dark center
                          foregroundColor: Colors.white,
                          side: const BorderSide(
                            color: Color(0xFF39FF14),
                            width: 2,
                          ),
                          elevation: 0,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.play_arrow_rounded,
                              size: 60,
                              color: Color(0xFF39FF14),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "START\nWORKOUT",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                                color: Colors.white,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 50),

                  // 4. Saved Routines (Restored)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Saved Routines",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          onSwitchTab(1); // Switch to Workout (Index 1)
                        },
                        child: const Text(
                          "See All",
                          style: TextStyle(color: Color(0xFF39FF14)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Routines List
                  ValueListenableBuilder<Box<Routine>>(
                    valueListenable: GymDatabase().routineListenable,
                    builder: (context, box, _) {
                      final routines = box.values.toList();
                      if (routines.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1C1E),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: const Center(
                            child: Text(
                              "No routines yet. Create one!",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        );
                      }

                      // Show first 3 routines
                      final displayRoutines = routines.take(3).toList();

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: displayRoutines.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final routine = displayRoutines[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1C1C1E),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.05),
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              title: Text(
                                routine.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Text(
                                "${routine.exerciseIds.length} Exercises",
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                              trailing: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF39FF14,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.play_arrow,
                                  color: Color(0xFF39FF14),
                                  size: 18,
                                ),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ActiveWorkoutScreen(routine: routine),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 100), // Bottom padding
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inDays > 365) return "${(diff.inDays / 365).floor()}y ago";
    if (diff.inDays > 30) return "${(diff.inDays / 30).floor()}mo ago";
    if (diff.inDays > 0) return "${diff.inDays}d ago";
    if (diff.inHours > 0) return "${diff.inHours}h ago";
    if (diff.inMinutes > 0) return "${diff.inMinutes}m ago";
    return "Just now";
  }

  void _showRoutineSelectorSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1C1C1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  "Select Routine",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Flexible(
                child: ValueListenableBuilder<Box<Routine>>(
                  valueListenable: GymDatabase().routineListenable,
                  builder: (context, box, _) {
                    final routines = box.values.toList();
                    if (routines.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(
                          "No routines found.\nCreate one in the Workout tab!",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: routines.length,
                      separatorBuilder: (_, __) =>
                          const Divider(color: Colors.white10, height: 1),
                      itemBuilder: (context, index) {
                        final routine = routines[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          title: Text(
                            routine.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          subtitle: Text(
                            "${routine.exerciseIds.length} Exercises",
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            color: Color(0xFF39FF14),
                            size: 16,
                          ),
                          onTap: () {
                            Navigator.pop(context); // Close sheet
                            // Push ActiveWorkoutScreen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ActiveWorkoutScreen(routine: routine),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Removed fixed height: 140
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Shrink wrap content
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (subtitle != null && subtitle!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                subtitle!,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}
