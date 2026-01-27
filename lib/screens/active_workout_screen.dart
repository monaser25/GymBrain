import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/gym_models.dart';
import '../services/database_service.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  final Routine routine;

  const ActiveWorkoutScreen({super.key, required this.routine});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  final _db = GymDatabase();
  Stopwatch _stopwatch = Stopwatch();
  Timer? _stopwatchTimer;
  String _elapsedString = "00:00";

  // Ghost Data Cache
  Map<String, ExerciseSet?> _historyCache = {};
  bool _isLoadingHistory = true;

  // Rest Timer State
  Timer? _restTimer;
  int _restSecondsRemaining = 0;
  bool _isResting = false;

  // State for the session
  final List<ExerciseSet> _completedSets = [];

  // Cache for exercise objects
  List<Exercise> _exercises = [];

  @override
  void initState() {
    super.initState();
    _startStopwatch();
    _loadExercisesAndHistory();
  }

  void _startStopwatch() {
    _stopwatch.start();
    _stopwatchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsedString = _formatDuration(_stopwatch.elapsed);
        });
      }
    });
  }

  Future<void> _loadExercisesAndHistory() async {
    // Load exercises
    _exercises = widget.routine.exerciseIds
        .map((id) => _db.getExercise(id))
        .whereType<Exercise>()
        .toList();

    // Pre-fetch history for ALL exercises
    final cache = <String, ExerciseSet?>{};
    for (var ex in _exercises) {
      cache[ex.id] = _db.getLastPerformance(ex.id);
    }

    if (mounted) {
      setState(() {
        _historyCache = cache;
        _isLoadingHistory = false;
      });
    }
  }

  @override
  void dispose() {
    _stopwatchTimer?.cancel();
    _restTimer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    if (d.inHours > 0) {
      return "${twoDigits(d.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    }
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  // --- Rest Timer Logic ---
  void _startRestTimer() {
    _restTimer?.cancel();
    setState(() {
      _isResting = true;
      _restSecondsRemaining = 90; // Default rest
    });

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_restSecondsRemaining > 0) {
          _restSecondsRemaining--;
        } else {
          _isResting = false;
          timer.cancel();
        }
      });
    });
  }

  void _skipRest() {
    _restTimer?.cancel();
    setState(() {
      _isResting = false;
    });
  }

  @override
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _showExitConfirmation();
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.routine.name, style: const TextStyle(fontSize: 16)),
              Text(
                _elapsedString,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 100),
                itemCount: _exercises.length,
                itemBuilder: (context, index) {
                  final exercise = _exercises[index];
                  return _ExerciseInputCard(
                    key: ValueKey(exercise.id),
                    exercise: exercise,
                    lastPerformance: _historyCache[exercise.id],
                    isLoadingHistory: _isLoadingHistory,
                    onSetCompleted: (set) {
                      setState(() {
                        _completedSets.add(set);
                      });
                      _startRestTimer();
                    },
                    todaysSets: _completedSets
                        .where((s) => s.exerciseName == exercise.name)
                        .toList(),
                  );
                },
              ),
            ),

            // Sticky Footer Area
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Rest Timer Overlay
                if (_isResting)
                  Container(
                    width: double.infinity,
                    color: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.timer, color: Colors.black),
                        const SizedBox(width: 8),
                        Text(
                          "Rest: ${_restSecondsRemaining}s",
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(width: 16),
                        TextButton(
                          onPressed: _skipRest,
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.black.withValues(
                              alpha: 0.1,
                            ),
                            foregroundColor: Colors.black,
                          ),
                          child: const Text(
                            "SKIP",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Finish Button
                _buildFinishButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showExitConfirmation() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text(
              "Exit Workout?",
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              "Current progress will be lost. Are you sure?",
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  "Exit",
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _buildFinishButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        // Ensure it respects bottom notch
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _finishWorkout,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "FINISH WORKOUT",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  void _finishWorkout() async {
    if (_completedSets.isEmpty) {
      if (!mounted) return;
      Navigator.pop(context);
      return;
    }

    final session = WorkoutSession(
      id: const Uuid().v4(),
      routineName: widget.routine.name,
      date: DateTime.now(),
      durationInSeconds: _stopwatch.elapsed.inSeconds,
      sets: _completedSets,
    );

    await _db.saveSession(session);

    if (!mounted) return;
    Navigator.pop(context);
  }
}

class _ExerciseInputCard extends StatefulWidget {
  final Exercise exercise;
  final ExerciseSet? lastPerformance;
  final bool isLoadingHistory;
  final Function(ExerciseSet) onSetCompleted;
  final List<ExerciseSet> todaysSets;

  const _ExerciseInputCard({
    super.key,
    required this.exercise,
    required this.lastPerformance,
    required this.isLoadingHistory,
    required this.onSetCompleted,
    required this.todaysSets,
  });

  @override
  State<_ExerciseInputCard> createState() => _ExerciseInputCardState();
}

class _ExerciseInputCardState extends State<_ExerciseInputCard> {
  final _weightController = TextEditingController();
  final _repsController = TextEditingController();
  String _selectedRpe = 'Good';
  bool _isKg = false; // Local state for unit toggle, default LB

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.exercise.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline, color: Colors.grey),
                  onPressed: () => _showInfoDialog(context),
                ),
              ],
            ),

            // Ghost Text from Cache
            if (widget.isLoadingHistory)
              const Text(
                "Loading history...",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              )
            else if (widget.lastPerformance != null)
              Text(
                "Last: ${widget.lastPerformance!.weight}${widget.lastPerformance!.unit /*?? 'kg'*/} x ${widget.lastPerformance!.reps} (${widget.lastPerformance!.rpe})",
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              const Text(
                "No history",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),

            const SizedBox(height: 16),

            // Inputs
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Weight Input
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      labelText: "Weight",
                      suffixText: _isKg ? "kg" : "lb",
                      suffixStyle: const TextStyle(
                        color: Color(0xFF39FF14),
                        fontWeight: FontWeight.bold,
                      ),
                      hintText: "0",
                      labelStyle: const TextStyle(color: Colors.grey),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey[800]!),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF39FF14)),
                      ),
                    ),
                  ),
                ),

                // Unit Toggle
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: 4.0,
                    left: 8.0,
                    right: 8.0,
                  ),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _isKg = !_isKg;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _isKg ? "KG" : "LB",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),

                // Reps Input
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _repsController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      labelText: "Reps",
                      hintText: "0",
                      labelStyle: const TextStyle(color: Colors.grey),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey[800]!),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF39FF14)),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // RPE & Complete Button
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "RPE",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['Easy', 'Good', 'Hard'].map((rpe) {
                            final isSelected = _selectedRpe == rpe;
                            // Colors for RPE
                            Color color;
                            switch (rpe) {
                              case 'Easy':
                                color = Colors.greenAccent;
                                break;
                              case 'Hard':
                                color = Colors.redAccent;
                                break;
                              default:
                                color = Colors.orangeAccent;
                            }

                            return Padding(
                              padding: const EdgeInsets.only(right: 4.0),
                              child: ChoiceChip(
                                label: Text(rpe),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected)
                                    setState(() => _selectedRpe = rpe);
                                },
                                selectedColor: color,
                                backgroundColor: Colors.grey[800],
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.black
                                      : Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _submitSet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    "COMPLETE\nSET",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            // Today's Sets History
            if (widget.todaysSets.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(color: Colors.white24),
              ...widget.todaysSets.asMap().entries.map((entry) {
                final idx = entry.key + 1;
                final set = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    children: [
                      Text(
                        "Set $idx: ",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${set.weight}${set.unit} x ${set.reps}",
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      // RPE Dot
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getRpeColor(set.rpe),
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.check_circle_outline,
                        size: 16,
                        color: Color(0xFF39FF14),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Color _getRpeColor(String rpe) {
    switch (rpe) {
      case 'Easy':
        return Colors.greenAccent;
      case 'Hard':
        return Colors.redAccent;
      default:
        return Colors.orangeAccent;
    }
  }

  void _submitSet() {
    final weight = double.tryParse(_weightController.text);
    final reps = int.tryParse(_repsController.text);

    if (weight != null && reps != null) {
      final set = ExerciseSet(
        exerciseName: widget.exercise.name,
        weight: weight,
        reps: reps,
        rpe: _selectedRpe,
        isCompleted: true,
        unit: _isKg ? 'kg' : 'lb', // Use local state
      );

      widget.onSetCompleted(set);

      _repsController.clear();
      // Keep weight and keyboard open for flow
    }
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            widget.exercise.name,
            style: const TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.exercise.setupNote != null)
                Text(
                  "Setup:\n${widget.exercise.setupNote}",
                  style: const TextStyle(color: Colors.white70),
                ),
              if (widget.exercise.setupNote == null)
                const Text(
                  "No setup notes.",
                  style: TextStyle(color: Colors.grey),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }
}
