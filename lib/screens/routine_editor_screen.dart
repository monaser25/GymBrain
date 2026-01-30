import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/gym_models.dart';
import '../services/database_service.dart';

class RoutineEditorScreen extends StatefulWidget {
  final String routineId;

  const RoutineEditorScreen({super.key, required this.routineId});

  @override
  State<RoutineEditorScreen> createState() => _RoutineEditorScreenState();
}

class _RoutineEditorScreenState extends State<RoutineEditorScreen> {
  final _db = GymDatabase();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<Routine>>(
      valueListenable: _db.routineListenable,
      builder: (context, routineBox, _) {
        final routine = routineBox.get(widget.routineId);

        if (routine == null) {
          return const Scaffold(body: Center(child: Text("Routine not found")));
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(routine.name),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          // Listen to Exercise Box to update UI when exercise name/details change
          body: ValueListenableBuilder<Box<Exercise>>(
            valueListenable: _db.exerciseListenable,
            builder: (context, exerciseBox, _) {
              return _buildExerciseList(routine);
            },
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () =>
                _showExerciseDialog(context, routine).then((result) {
                  if (result == true) {
                    setState(() {});
                  }
                }),
            label: const Text("Add Exercise"),
            icon: const Icon(Icons.add),
            backgroundColor: const Color(0xFF39FF14),
            foregroundColor: Colors.black,
          ),
        );
      },
    );
  }

  Widget _buildExerciseList(Routine routine) {
    if (routine.exerciseIds.isEmpty) {
      return Center(
        child: Text(
          "No exercises yet.\nAdd one to start building this routine!",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    final exercises = <Exercise>[];
    for (final id in routine.exerciseIds) {
      final ex = _db.getExercise(id);
      if (ex != null) {
        exercises.add(ex);
      }
    }

    return ReorderableListView.builder(
      itemCount: exercises.length,
      padding: const EdgeInsets.all(16),
      onReorder: (oldIndex, newIndex) =>
          _onReorder(routine, oldIndex, newIndex),
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        return Card(
          key: ValueKey(exercise.id),
          margin: const EdgeInsets.symmetric(vertical: 6),
          color: const Color(0xFF1C1C1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            onTap: () =>
                _showExerciseDialog(
                  context,
                  routine,
                  existingExercise: exercise,
                ).then((result) {
                  // Refresh if edited (though listenable builder handles it mostly,
                  // explicit setState helps if list order or deep properties changed affecting list)
                  if (result == true) setState(() {});
                }),
            leading: CircleAvatar(
              backgroundColor: Colors.grey[800],
              child: Text(
                "${index + 1}",
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(
              exercise.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (exercise.setupNote != null &&
                    exercise.setupNote!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      "Setup: ${exercise.setupNote}",
                      style: TextStyle(color: Colors.grey[400], fontSize: 13),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    "Target: ${exercise.targetSets} Sets",
                    style: const TextStyle(
                      color: Color(0xFF39FF14),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  onPressed: () =>
                      _removeExerciseFromRoutine(routine, exercise.id),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.drag_handle, color: Colors.grey),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onReorder(Routine routine, int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = routine.exerciseIds.removeAt(oldIndex);
    routine.exerciseIds.insert(newIndex, item);
    await routine.save();
  }

  // --- ADD / EDIT DIALOG (Refactored for State/Scope) ---
  Future<bool?> _showExerciseDialog(
    BuildContext context,
    Routine routine, {
    Exercise? existingExercise,
  }) async {
    final isEditing = existingExercise != null;
    final libraryNames = _db.getUniqueExerciseNames();

    // Controllers
    final nameController = TextEditingController(
      text: existingExercise?.name ?? "",
    );
    final setupController = TextEditingController(
      text: existingExercise?.setupNote ?? "",
    );
    final targetSetsController = TextEditingController(
      text: existingExercise?.targetSets.toString() ?? "3",
    );

    // State Variables (local to closure, but we need them in setState)
    // We will update these inside the StatefulBuilder
    int selectedTabIndex = 0;
    String? selectedLibraryName;

    return showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1C1C1E),
              title: isEditing
                  ? const Text(
                      "Edit Exercise",
                      style: TextStyle(color: Colors.white),
                    )
                  : Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    setDialogState(() => selectedTabIndex = 0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: selectedTabIndex == 0
                                            ? const Color(0xFF39FF14)
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    "New",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: selectedTabIndex == 0
                                          ? const Color(0xFF39FF14)
                                          : Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    setDialogState(() => selectedTabIndex = 1),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: selectedTabIndex == 1
                                            ? const Color(0xFF39FF14)
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    "Library",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: selectedTabIndex == 1
                                          ? const Color(0xFF39FF14)
                                          : Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    Expanded(
                      child: selectedTabIndex == 0
                          ? SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(
                                    controller: nameController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: const InputDecoration(
                                      labelText: "Exercise Name",
                                      hintText: "e.g. Incline Bench Press",
                                      labelStyle: TextStyle(color: Colors.grey),
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.grey,
                                        ),
                                      ),
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color(0xFF39FF14),
                                        ),
                                      ),
                                    ),
                                    autofocus: !isEditing,
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: targetSetsController,
                                    style: const TextStyle(color: Colors.white),
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: "Target Sets",
                                      hintText: "3",
                                      labelStyle: TextStyle(color: Colors.grey),
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.grey,
                                        ),
                                      ),
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color(0xFF39FF14),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: setupController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: const InputDecoration(
                                      labelText: "Setup Note (Optional)",
                                      hintText: "e.g. Seat 4, Pin 3",
                                      labelStyle: TextStyle(color: Colors.grey),
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.grey,
                                        ),
                                      ),
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color(0xFF39FF14),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : (libraryNames.isEmpty
                                ? const Center(
                                    child: Text(
                                      "Library is empty.",
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: libraryNames.length,
                                    separatorBuilder: (_, __) => const Divider(
                                      height: 1,
                                      color: Colors.white10,
                                    ),
                                    itemBuilder: (context, index) {
                                      final name = libraryNames[index];
                                      final isSelected =
                                          selectedLibraryName == name;
                                      return ListTile(
                                        title: Text(
                                          name,
                                          style: TextStyle(
                                            color: isSelected
                                                ? const Color(0xFF39FF14)
                                                : Colors.white,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                        trailing: isSelected
                                            ? const Icon(
                                                Icons.check,
                                                color: Color(0xFF39FF14),
                                              )
                                            : null,
                                        onTap: () {
                                          setDialogState(() {
                                            selectedLibraryName = name;
                                          });
                                        },
                                      );
                                    },
                                  )),
                    ),
                    const SizedBox(height: 16),
                    // BUTTONS INSIDE THE BUILDER SCOPE
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            String finalName = "";
                            int finalTargetSets = 3;
                            String? finalSetup;

                            if (!isEditing && selectedTabIndex == 1) {
                              // LIBRARY TAB
                              if (selectedLibraryName == null) {
                                return;
                              }
                              finalName = selectedLibraryName!;
                            } else {
                              // NEW / EDIT TAB
                              if (!isEditing &&
                                  nameController.text.trim().isEmpty) {
                                return; // Validation
                              }

                              finalName = nameController.text.trim();
                              if (finalName.isEmpty) {
                                finalName = "Exercise";
                              }

                              finalTargetSets =
                                  int.tryParse(targetSetsController.text) ?? 3;
                              finalSetup =
                                  setupController.text.trim().isNotEmpty
                                  ? setupController.text.trim()
                                  : null;
                            }

                            if (isEditing) {
                              // EDIT - existingExercise is guaranteed non-null here
                              final updatedExercise = Exercise(
                                id: existingExercise.id,
                                name: finalName,
                                targetSets: finalTargetSets,
                                setupNote: finalSetup,
                                imagePath: existingExercise.imagePath,
                              );
                              await _db.saveExercise(updatedExercise);
                            } else {
                              // ADD / LINK
                              final existingId = _db.findExerciseIdByName(
                                finalName,
                              );
                              if (existingId != null) {
                                if (!routine.exerciseIds.contains(existingId)) {
                                  routine.exerciseIds.add(existingId);
                                  await routine.save();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "Linked existing '$finalName'!",
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } else {
                                  // Already exists
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "'$finalName' is already here!",
                                        ),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                  }
                                  // We can close or stay. Let's close.
                                }
                              } else {
                                final newExercise = Exercise(
                                  id: const Uuid().v4(),
                                  name: finalName,
                                  targetSets: finalTargetSets,
                                  setupNote: finalSetup,
                                );
                                await _db.saveExercise(newExercise);
                                routine.exerciseIds.add(newExercise.id);
                                await routine.save();
                              }
                            }

                            if (context.mounted) Navigator.pop(context, true);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF39FF14),
                            foregroundColor: Colors.black,
                          ),
                          child: Text(isEditing ? "Save" : "Add"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _removeExerciseFromRoutine(
    Routine routine,
    String exerciseId,
  ) async {
    routine.exerciseIds.remove(exerciseId);
    await routine.save();
  }
}
