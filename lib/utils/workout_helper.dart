import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/active_workout_provider.dart';
import '../screens/active_workout_screen.dart';

Future<bool> checkActiveWorkout(BuildContext context) async {
  final provider = Provider.of<ActiveWorkoutProvider>(context, listen: false);

  if (!provider.hasActiveWorkout) {
    return true; // No active workout, allow proceeding
  }

  // Active workout exists, show dialog
  final shouldProceed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1C1C1E),
      title: const Text(
        "Active Workout in Progress ⚠️",
        style: TextStyle(color: Colors.white),
      ),
      content: const Text(
        "You have a workout running in the background. You cannot start a new one until you finish or discard the current one.",
        style: TextStyle(color: Colors.white70),
      ),
      actions: [
        // RESUME (Cancel new, go to old)
        TextButton(
          onPressed: () {
            Navigator.pop(ctx, false); // Return false
            // Navigate to active workout
            if (provider.currentRoutine != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ActiveWorkoutScreen(routine: provider.currentRoutine!),
                ),
              );
            }
          },
          child: const Text(
            "Resume",
            style: TextStyle(color: Color(0xFF39FF14)),
          ),
        ),
        // CANCEL (Stay here)
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
        ),
        // DISCARD (Clear old, allow new)
        TextButton(
          onPressed: () async {
            await provider.clearData();
            if (ctx.mounted) Navigator.pop(ctx, true);
          },
          child: const Text(
            "Discard Old & Start New",
            style: TextStyle(color: Colors.redAccent),
          ),
        ),
      ],
    ),
  );

  return shouldProceed ?? false;
}
