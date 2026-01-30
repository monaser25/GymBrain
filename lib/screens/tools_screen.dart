import 'package:flutter/material.dart';

class ToolsScreen extends StatelessWidget {
  final int initialTab;

  const ToolsScreen({super.key, this.initialTab = 0});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: initialTab,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            "Gym Tools",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          bottom: TabBar(
            indicatorColor: const Color(0xFF39FF14),
            indicatorWeight: 3,
            labelColor: const Color(0xFF39FF14),
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            tabs: const [
              Tab(icon: Icon(Icons.calculate_outlined), text: "1RM Calculator"),
              Tab(
                icon: Icon(Icons.donut_large_outlined),
                text: "Plate Calculator",
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: 1RM Calculator
            _buildComingSoonTab(
              icon: Icons.fitness_center,
              title: "1RM Calculator",
              subtitle: "Calculate your one-rep max based on your lifts",
            ),
            // Tab 2: Plate Calculator
            _buildComingSoonTab(
              icon: Icons.donut_large,
              title: "Plate Calculator",
              subtitle: "Find the right plates for your target weight",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComingSoonTab({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF39FF14).withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Icon(icon, size: 64, color: const Color(0xFF39FF14)),
            ),
            const SizedBox(height: 32),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF39FF14).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF39FF14).withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.construction, color: Color(0xFF39FF14), size: 18),
                  SizedBox(width: 8),
                  Text(
                    "Coming Soon",
                    style: TextStyle(
                      color: Color(0xFF39FF14),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
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
