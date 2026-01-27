import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/gym_models.dart';
import '../services/database_service.dart';
import '../utils/timer_config.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  final Routine routine;

  const ActiveWorkoutScreen({super.key, required this.routine});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  final _db = GymDatabase();
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _stopwatchTimer;
  String _elapsedString = "00:00";

  // Focus Mode State
  int _focusedIndex = 0;
  final ScrollController _scrollController = ScrollController();

  // Ghost Data Cache
  Map<String, ExerciseSet?> _historyCache = {};
  bool _isLoadingHistory = true;

  // Rest Timer State
  Timer? _restTimer;
  int _restSecondsRemaining = 0;
  bool _isResting = false;

  // State for the session
  final List<ExerciseSet> _completedSets = [];
  late DateTime _startTime;

  // Cache for exercise objects
  List<Exercise> _exercises = [];

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
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
    _scrollController.dispose();
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
  void _startRestTimer([int? duration]) {
    _restTimer?.cancel();
    setState(() {
      _isResting = true;
      _restSecondsRemaining = duration ?? 90; // Use smart duration or default
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

  void _add30Seconds() {
    setState(() {
      _restSecondsRemaining += 30;
    });
  }

  void _scrollToIndex(int index) {
    // Small delay to allow UI to rebuild if size changed
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          index * 150.0, // Approximation, but workable
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _onSetCompleted(ExerciseSet set, int index) {
    setState(() {
      _completedSets.add(set);
    });

    // Check if we should advance to next exercise
    // Logic: If user has done 3 sets (or whatever logic), advance.
    // For now, let's keep it manual or based on a "Finish Exercise" button?
    // The prompt says "Check if this was the last set".
    // Since we don't have a rigid "Target Sets" property yet, let's look at completed sets count
    // If user hits 3 sets, we propose moving on.
    final exercise = _exercises[index];
    final setsForThis = _completedSets
        .where((s) => s.exerciseName == set.exerciseName)
        .length;

    // Use dynamic targetSets
    if (setsForThis >= exercise.targetSets) {
      if (_focusedIndex < _exercises.length - 1) {
        setState(() => _focusedIndex++);
        _scrollToIndex(_focusedIndex);
      }
    }

    // Smart Timer Logic
    final restTime = TimerConfig.getRestTime(exercise.name);
    _startRestTimer(restTime);
  }

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
        backgroundColor: Colors.black, // Dark Mode Background
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () async {
              if (await _showExitConfirmation()) {
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  widget.routine.name,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Timer Pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF39FF14), // Neon Green
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _elapsedString,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: 120),
                itemCount: _exercises.length,
                itemBuilder: (context, index) {
                  final exercise = _exercises[index];
                  final todaysSets = _completedSets
                      .where((s) => s.exerciseName == exercise.name)
                      .toList();
                  final isTargetMet = todaysSets.length >= exercise.targetSets;

                  // Condition A: Active (Focused)
                  if (index == _focusedIndex) {
                    return _ExerciseInputCard(
                      key: ValueKey(exercise.id),
                      exercise: exercise,
                      lastPerformance: _historyCache[exercise.id],
                      isLoadingHistory: _isLoadingHistory,
                      todaysSets: todaysSets,
                      isFocused: true,
                      isTargetMet: isTargetMet,
                      onCollapse: () {
                        setState(() {
                          _focusedIndex = -1;
                        });
                      },
                      onSetCompleted: (set) => _onSetCompleted(set, index),
                    );
                  }

                  // Condition B & C: Untargeted (Collapsed) Card
                  if (index != _focusedIndex) {
                    final isStarted = todaysSets.isNotEmpty;
                    final isComplete = todaysSets.length >= exercise.targetSets;

                    return GestureDetector(
                      onTap: () {
                        setState(() => _focusedIndex = index);
                        _scrollToIndex(index);
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: _focusedIndex == -1
                              ? const Color(0xFF1C1C1E)
                              : (index > _focusedIndex
                                    ? const Color(
                                        0xFF1C1C1E,
                                      ).withValues(alpha: 0.5)
                                    : Colors.black),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    exercise.name,
                                    style: TextStyle(
                                      color: isComplete
                                          ? Colors.grey[500]
                                          : Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      decoration: isComplete
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                  if (isStarted || isComplete) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      "Completed: ${todaysSets.length} / ${exercise.targetSets}",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isComplete
                                            ? const Color(0xFF39FF14)
                                            : Colors.yellow,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ] else ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      "${exercise.targetSets} Sets",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (isComplete)
                              const Icon(
                                Icons.check_circle,
                                color: Color(0xFF39FF14),
                                size: 24,
                              )
                            else if (index > _focusedIndex &&
                                _focusedIndex != -1)
                              // Lock icon only if we are in focused mode and it's ahead
                              Icon(
                                Icons.lock_outline,
                                color: Colors.grey[700],
                                size: 18,
                              )
                            else if (isStarted)
                              // In progress indicator
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.yellow,
                                ),
                              )
                            else
                              // Chevron or nothing
                              Icon(
                                Icons.chevron_right,
                                color: Colors.grey[700],
                                size: 18,
                              ),
                          ],
                        ),
                      ),
                    );
                  }
                  // Should be unreachable if logic is correct, but for safety:
                  return const SizedBox.shrink();
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
                    color: const Color(0xFF39FF14),
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 20,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.timer, color: Colors.black, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "Rest: ${_restSecondsRemaining}s",
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(width: 16),
                        TextButton(
                          onPressed: _add30Seconds,
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.black.withValues(
                              alpha: 0.1,
                            ),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            "+30s",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: _skipRest,
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.black.withValues(
                              alpha: 0.1,
                            ),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            "SKIP",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Finish Button (Only visible if near end or explicitly scrolled? User requested visibility logic)
                // Let's show it always at bottom for safety, but maybe highlight it when last exercise is done.
                if (_focusedIndex >= _exercises.length - 1 ||
                    _completedSets.isNotEmpty)
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
            backgroundColor: const Color(0xFF1C1C1E),
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
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.grey),
                ),
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
      color: Colors.black,
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
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text(
              "FINISH WORKOUT",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
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
      durationInSeconds: DateTime.now().difference(_startTime).inSeconds,
      sets: _completedSets,
    );

    await _db.saveSession(session);

    // Slight delay to ensure saving
    await Future.delayed(const Duration(milliseconds: 300));

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
  final bool isFocused;
  final bool isTargetMet;
  final VoidCallback onCollapse;

  const _ExerciseInputCard({
    super.key,
    required this.exercise,
    required this.lastPerformance,
    required this.isLoadingHistory,
    required this.onSetCompleted,
    required this.todaysSets,
    required this.onCollapse,
    this.isFocused = false,
    this.isTargetMet = false,
  });

  @override
  State<_ExerciseInputCard> createState() => _ExerciseInputCardState();
}

class _ExerciseInputCardState extends State<_ExerciseInputCard> {
  final _weightController = TextEditingController();
  final _repsController = TextEditingController();
  String _selectedRpe = 'Good';
  bool _isKg = false; // Default LB

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: widget.isFocused
            ? Border.all(color: const Color(0xFF39FF14), width: 1.5)
            : null,
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Neon Strip
            Container(
              width: 4,
              decoration: const BoxDecoration(
                color: Color(0xFF39FF14),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    GestureDetector(
                      // Tap header to collapse
                      onTap: widget.onCollapse, // Call the onCollapse callback
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.exercise.name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                _buildSetProgressText(),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.info_outline,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                                onPressed: () => _showInfoDialog(context),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.keyboard_arrow_up, // Collapse Icon
                                  color: Colors.grey,
                                  size: 24,
                                ),
                                onPressed: widget.onCollapse,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Ghost Text
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: widget.isLoadingHistory
                          ? const Text(
                              "Loading history...",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            )
                          : (widget.lastPerformance != null
                                ? Text(
                                    "Last: ${widget.lastPerformance!.weight}${widget.lastPerformance!.unit} x ${widget.lastPerformance!.reps} (${widget.lastPerformance!.rpe})",
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  )
                                : TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                  ).toText("No history")),
                    ),

                    // Inputs
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Weight Input
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "WEIGHT",
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2C2C2E),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _weightController,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        decoration: const InputDecoration(
                                          hintText: "0",
                                          hintStyle: TextStyle(
                                            color: Colors.grey,
                                          ),
                                          border: InputBorder.none,
                                          isDense: true,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () =>
                                          setState(() => _isKg = !_isKg),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          _isKg ? "KG" : "LB",
                                          style: const TextStyle(
                                            color: Color(0xFF39FF14),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 16),

                        // Reps Input
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "REPS",
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2C2C2E),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: TextField(
                                  controller: _repsController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: "0",
                                    hintStyle: TextStyle(color: Colors.grey),
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // RPE
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "RPE (EFFORT)",
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: ['Easy', 'Good', 'Hard'].map((rpe) {
                            final isSelected = _selectedRpe == rpe;
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

                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedRpe = rpe),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? color
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected
                                          ? color
                                          : Colors.grey[800]!,
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    rpe,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.black
                                          : Colors.grey,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // COMPLETE BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitSet,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF39FF14),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          "COMPLETE SET",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),

                    // History Log - Compact
                    if (widget.todaysSets.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Divider(color: Colors.grey[800], height: 1),
                      const SizedBox(height: 12),
                      ...widget.todaysSets.asMap().entries.map((entry) {
                        final idx = entry.key + 1;
                        final set = entry.value;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey[800],
                                ),
                                child: Text(
                                  "$idx",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "${set.weight}${set.unit} x ${set.reps}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _getRpeColor(set.rpe),
                                ),
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.check,
                                size: 16,
                                color: Color(0xFF39FF14),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),
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

  Widget _buildSetProgressText() {
    final int currentSet = widget.todaysSets.length + 1;
    final int target = widget.exercise.targetSets;

    // Logic for Bonus Sets
    if (widget.todaysSets.length >= target) {
      // We are in bonus territory or just finished
      final int bonusSetNum = widget.todaysSets.length - target + 1;
      return Text(
        "Bonus Set $bonusSetNum (Target: $target)",
        style: const TextStyle(
          color: Colors.greenAccent, // Keep it green
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    return Text(
      "Set $currentSet of $target",
      style: const TextStyle(
        color: Color(0xFF39FF14),
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
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
        unit: _isKg ? 'kg' : 'lb',
      );

      widget.onSetCompleted(set);

      // Don't clear controller, user might do same weight
      // _repsController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C1C1E),
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
              child: const Text(
                "Close",
                style: TextStyle(color: Color(0xFF39FF14)),
              ),
            ),
          ],
        );
      },
    );
  }
}

extension TextHelper on TextStyle {
  Text toText(String content) => Text(content, style: this);
}
