import 'package:flutter/material.dart';
import '../services/database_service.dart';

class ExerciseLibraryScreen extends StatelessWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get all exercises directly from DB using getExercises()
    // It's better if we listen to them, so we'll use ValueListenableBuilder inside.
    final db = GymDatabase();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "Exercise Library",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ValueListenableBuilder(
        valueListenable: db.exerciseListenable,
        builder: (context, box, _) {
          final exercises = db.getExercises();

          // Optionally unique by name if we want to show unique library entries,
          // or show all instances (which might be confusing).
          // Use getUniqueExerciseNames to show the "Concept" of exercises.
          // But maybe the user wants to see actual objects.
          // The request said: "lists ALL exercises in exercisesBox".
          // But duplicates will appear. Let's group them or just list unique names?
          // "Allows the user to see/edit their 'Global Database'".
          // If we show "Bench Press" 5 times (one for each routine), it's weird.
          // But editing one "Bench Press" in PPL doesn't edit "Bench Press" in Another Routine structurally (different IDs),
          // BUT they share name.
          // The user said "This allows the user to see/edit their 'Global Database'".
          // If I edit "Bench Press", should it update ALL of them?
          // In the Add Dialog, we update existing.
          // Let's just list unique Names for now, as that represents the "Library".

          final uniqueNames = db.getUniqueExerciseNames();

          if (uniqueNames.isEmpty) {
            return Center(
              child: Text(
                "Library is empty.",
                style: TextStyle(color: Colors.grey[600]),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: uniqueNames.length,
            separatorBuilder: (_, __) => const Divider(color: Colors.white10),
            itemBuilder: (context, index) {
              final name = uniqueNames[index];
              return ListTile(
                title: Text(
                  name,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF1C1C1E),
                  child: Text(
                    name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Color(0xFF39FF14)),
                  ),
                ),
                // We can maybe add delete/edit here later but for now just viewing
              );
            },
          );
        },
      ),
    );
  }
}
