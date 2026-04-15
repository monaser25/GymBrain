import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/gym_models.dart';
import '../services/database_service.dart';
import 'routine_editor_screen.dart';
import 'exercise_library_screen.dart';
import '../utils/workout_helper.dart';
import 'active_workout_screen.dart';
import '../l10n/app_localizations.dart';

class RoutinesScreen extends StatelessWidget {
  const RoutinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.myRoutines ?? "My Routines",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showAddRoutineDialog(context),
            icon: const Icon(Icons.add, color: Color(0xFF39FF14)),
          ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ExerciseLibraryScreen()),
            ),
            icon: const Icon(Icons.inventory_2, color: Colors.white),
            tooltip: 'Exercise Library',
          ),
        ],
      ),
      body: ValueListenableBuilder<Box<Routine>>(
        valueListenable: GymDatabase().routineListenable,
        builder: (context, box, _) {
          final routines = box.values.toList();
          if (routines.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  AppLocalizations.of(context)?.noRoutinesCreate ?? "No routines found.\nCreate one to get started!",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: routines.length,
            itemBuilder: (context, index) {
              final routine = routines[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
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
                    "${routine.exerciseIds.length} ${AppLocalizations.of(context)?.exercises ?? 'Exercises'}",
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.play_arrow_rounded,
                          size: 32,
                          color: Color(0xFF39FF14),
                        ),
                        onPressed: () async {
                          if (await checkActiveWorkout(context)) {
                            if (context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ActiveWorkoutScreen(routine: routine),
                                ),
                              );
                            }
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 22,
                          color: Colors.grey,
                        ),
                        onPressed: () =>
                            _confirmDeleteRoutine(context, routine),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            RoutineEditorScreen(routineId: routine.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDeleteRoutine(BuildContext context, Routine routine) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C1C1E),
          title: Text(
            AppLocalizations.of(context)?.deleteRoutineTitle ?? "Delete Routine?",
            style: const TextStyle(color: Colors.white),
          ),
          content: Text(
            AppLocalizations.of(context)?.deleteRoutineMsg(routine.name) ?? "Are you sure you want to delete '${routine.name}'?",
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)?.cancelBtn ?? "Cancel", style: const TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                await GymDatabase().deleteRoutine(routine.id);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text(
                "Delete",
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddRoutineDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C1C1E),
          title: Text(
            AppLocalizations.of(context)?.newRoutine ?? "New Routine",
            style: const TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF2C2C2E),
                hintText: AppLocalizations.of(context)?.egPushDay ?? "e.g., Push Day",
                hintStyle: const TextStyle(color: Colors.grey),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              autofocus: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)?.cancelBtn ?? "Cancel", style: const TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  final newRoutine = Routine(
                    id: const Uuid().v4(),
                    name: nameController.text,
                    exerciseIds: [],
                  );
                  await GymDatabase().saveRoutine(newRoutine);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF39FF14),
                foregroundColor: Colors.black,
              ),
              child: Text(
                AppLocalizations.of(context)?.save ?? "Create",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}
