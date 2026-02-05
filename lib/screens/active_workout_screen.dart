import 'dart:async';
import 'package:flutter/material.dart';
import '../models/gym_models.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter/services.dart';
import '../utils/timer_config.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:provider/provider.dart';
import '../providers/active_workout_provider.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  final Routine routine;

  const ActiveWorkoutScreen({super.key, required this.routine});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen>
    with WidgetsBindingObserver {
  final _db = GymDatabase();
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _stopwatchTimer;
  String _elapsedString = "00:00";

  // Focus Mode State
  final ScrollController _scrollController = ScrollController();

  // Ghost Data Cache
  Map<String, ExerciseSet?> _historyCache = {};
  bool _isLoadingHistory = true;

  // Rest Timer State
  Timer? _restTimer;
  int _restSecondsRemaining = 0;
  bool _isResting = false;
  DateTime? _restEndTime;
  DateTime? _timerEndTime;

  // Exercise Cache
  List<Exercise> _exercises = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestAndroidExactAlarmPermission();

    // Initialize Provider State
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ActiveWorkoutProvider>();
      if (provider.currentRoutine?.id == widget.routine.id) {
        // Resuming: Use provider data
      } else {
        // New Workout
        provider.startWorkout(widget.routine);
      }
      _startStopwatch();
      _loadExercisesAndHistory();

      // Sync Focused Index
      if (provider.focusedIndex > 0) {
        _scrollToIndex(provider.focusedIndex);
      }
    });

    // Enable wakelock to keep screen on during workout
    WakelockPlus.enable();
  }

  Future<void> _requestAndroidExactAlarmPermission() async {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    final androidImplementation = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImplementation != null) {
      await androidImplementation.requestExactAlarmsPermission();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      if (_isResting) {
        _timerEndTime = DateTime.now().add(
          Duration(seconds: _restSecondsRemaining),
        );
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_isResting && _timerEndTime != null) {
        final remaining = _timerEndTime!.difference(DateTime.now()).inSeconds;
        if (remaining > 0) {
          setState(() {
            _restSecondsRemaining = remaining;
          });
          NotificationService().cancelAll();
        } else {
          _skipRest();
        }
      }
    }
  }

  // Removed _checkActiveSession as it is handled by Provider initialization

  void _startStopwatch() {
    _stopwatchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        final provider = context.read<ActiveWorkoutProvider>();
        if (provider.startTime != null) {
          setState(() {
            final elapsed = DateTime.now().difference(provider.startTime!);
            _elapsedString = _formatDuration(elapsed);
          });
        }
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
    WidgetsBinding.instance.removeObserver(this);
    _stopwatchTimer?.cancel();
    _restTimer?.cancel();
    _stopwatch.stop();
    NotificationService().cancelNotification(
      0,
    ); // Cancel timer notification on dispose
    _scrollController.dispose();
    // Disable wakelock when leaving workout screen
    WakelockPlus.disable();
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
  // Uses timestamp-based calculation to survive iOS background throttling
  void _startRestTimer([int? duration]) {
    _restTimer?.cancel();
    final targetSeconds = duration ?? _db.defaultRestSeconds;

    // Calculate the target end time using timestamp delta approach
    _restEndTime = DateTime.now().add(Duration(seconds: targetSeconds));

    setState(() {
      _isResting = true;
      _restSecondsRemaining = targetSeconds;
    });

    _scheduleNotification(targetSeconds);

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      // Calculate remaining time from timestamp delta (not tick counting!)
      // This fixes iOS timer freeze when phone locks
      final remaining = _restEndTime!.difference(DateTime.now()).inSeconds;

      setState(() {
        if (remaining > 0) {
          _restSecondsRemaining = remaining;
        } else {
          _restSecondsRemaining = 0;
          _isResting = false;
          _restEndTime = null;
          timer.cancel();
          // Sound & Vibration Feedback
          if (_db.enableSound) {
            Vibration.vibrate();
            SystemSound.play(SystemSoundType.click);
          }
        }
      });
    });
  }

  void _skipRest() {
    _restTimer?.cancel();
    _restEndTime = null;
    NotificationService().cancelNotification(0);
    setState(() {
      _isResting = false;
    });
  }

  void _add30Seconds() {
    // Extend the end time by 30 seconds
    if (_restEndTime != null) {
      _restEndTime = _restEndTime!.add(const Duration(seconds: 30));
      setState(() {
        _restSecondsRemaining = _restEndTime!
            .difference(DateTime.now())
            .inSeconds;
      });
      // Reschedule notification
      NotificationService().cancelNotification(0);
      _scheduleNotification(_restSecondsRemaining);
    }
  }

  void _scrollToIndex(int index) {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          index * 150.0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _onSetCompleted(ExerciseSet set, int index) {
    // Add to provider
    context.read<ActiveWorkoutProvider>().addSet(set);

    final exercise = _exercises[index];
    final provider = context.read<ActiveWorkoutProvider>();
    final setsForThis = provider.completedSets
        .where((s) => s.exerciseName == set.exerciseName)
        .length;

    if (setsForThis >= exercise.targetSets) {
      if (index < _exercises.length - 1) {
        // Update focused index in provider
        provider.setFocusedIndex(index + 1);
        _scrollToIndex(index + 1);
      }
    }

    final restTime = TimerConfig.getRestTime(exercise.name);
    _startRestTimer(restTime);
  }

  Future<void> _scheduleNotification(int seconds) async {
    if (!_db.enableNotifications) return;

    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    final provider = context.read<ActiveWorkoutProvider>();

    String currentExerciseName = "your next set";
    if (provider.focusedIndex >= 0 &&
        provider.focusedIndex < _exercises.length) {
      currentExerciseName = _exercises[provider.focusedIndex].name;
    }

    try {
      await NotificationService().scheduleNotification(
        id: 0,
        title: "Rest Finished! 🔔",
        body: "Time to crush your next set of $currentExerciseName!",
        seconds: seconds,
        playSound: _db.enableSound,
      );
    } catch (e) {
      Future.delayed(Duration(seconds: seconds), () async {
        if (!mounted || !_isResting) return;

        const AndroidNotificationDetails androidNotificationDetails =
            AndroidNotificationDetails(
              'gym_timer',
              'Timer',
              channelDescription: 'Notifications for workout rest timers',
              importance: Importance.max,
              priority: Priority.high,
              ticker: 'ticker',
              icon: '@mipmap/ic_launcher',
            );
        const NotificationDetails notificationDetails = NotificationDetails(
          android: androidNotificationDetails,
        );

        await flutterLocalNotificationsPlugin.show(
          id: 0,
          title: "Rest Finished! 🔔",
          body: "Time to crush your next set of $currentExerciseName!",
          notificationDetails: notificationDetails,
        );
      });
    }
  }

  // _saveProgress removed (handled by provider)

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Consumer<ActiveWorkoutProvider>(
      builder: (context, provider, child) {
        final completedSets = provider.completedSets;
        final focusedIndex = provider.focusedIndex;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            // Feature 4: Minimize vs End
            final action = await showDialog<String>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: const Color(0xFF1C1C1E),
                title: const Text(
                  "Workout Active",
                  style: TextStyle(color: Colors.white),
                ),
                content: const Text(
                  "Do you want to minimize the workout (keep running) or end it (discard part)?\nUse 'Finish' button to save.",
                  style: TextStyle(color: Colors.white70),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, 'minimize'),
                    child: const Text(
                      "Minimize",
                      style: TextStyle(color: Colors.blueAccent),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, 'end'),
                    child: const Text(
                      "End (Discard)",
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
            );

            if (action == 'minimize' && context.mounted) {
              provider.minimizeWorkout();
              Navigator.pop(context);
            } else if (action == 'end' && context.mounted) {
              await provider.clearData();
              if (context.mounted) Navigator.pop(context);
            }
          },
          child: Scaffold(
            backgroundColor: Colors.black,
            resizeToAvoidBottomInset: true,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () async {
                  // Trigger PopScope logic
                  Navigator.maybePop(context);
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF39FF14),
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
                      // Filter sets for this exercise
                      final todaysSets = completedSets
                          .where((s) => s.exerciseName == exercise.name)
                          .toList();
                      final isTargetMet =
                          todaysSets.length >= exercise.targetSets;

                      if (index == focusedIndex) {
                        return _ExerciseInputCard(
                          key: ValueKey(exercise.id),
                          exercise: exercise,
                          lastPerformance: _historyCache[exercise.id],
                          isLoadingHistory: _isLoadingHistory,
                          todaysSets: todaysSets,
                          isFocused: true,
                          isTargetMet: isTargetMet,
                          onCollapse: () {
                            provider.setFocusedIndex(-1);
                          },
                          onSetCompleted: (set) => _onSetCompleted(set, index),
                          // Feature 2: Edit Set Callback
                          onSetEdited: (oldSet, newSet) {
                            // Find index in main list
                            final globalIndex = completedSets.indexOf(oldSet);
                            if (globalIndex != -1) {
                              provider.updateSet(globalIndex, newSet);
                            }
                          },
                        );
                      }

                      if (index != focusedIndex) {
                        final isStarted = todaysSets.isNotEmpty;
                        final isComplete =
                            todaysSets.length >= exercise.targetSets;

                        return GestureDetector(
                          onTap: () {
                            provider.setFocusedIndex(index);
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
                              color: focusedIndex == -1
                                  ? const Color(0xFF1C1C1E)
                                  : (index > focusedIndex
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                else if (index > focusedIndex &&
                                    focusedIndex != -1)
                                  Icon(
                                    Icons.lock_outline,
                                    color: Colors.grey[700],
                                    size: 18,
                                  )
                                else if (isStarted)
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.yellow,
                                    ),
                                  )
                                else
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
                      return const SizedBox.shrink();
                    },
                  ),
                ),

                // Sticky Footer Area
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                            const Icon(
                              Icons.timer,
                              color: Colors.black,
                              size: 20,
                            ),
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

                    if (!isKeyboardVisible &&
                        (focusedIndex >= _exercises.length - 1 ||
                            completedSets.isNotEmpty))
                      _buildFinishButton(
                        context,
                        provider,
                      ), // Pass context/provider if needed
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper dialogs for PopScope above (already implemented inline or can be helper)
  // I implemented inline.

  Widget _buildFinishButton(
    BuildContext context,
    ActiveWorkoutProvider provider,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.black,
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () async {
              final shouldFinish =
                  await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF1C1C1E),
                      title: const Text(
                        "Finish Workout?",
                        style: TextStyle(color: Colors.white),
                      ),
                      content: const Text(
                        "Are you ready to complete this session?",
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
                            "Finish",
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      ],
                    ),
                  ) ??
                  false;

              if (shouldFinish) {
                await provider.finishWorkout();
                NotificationService().cancelAll();
                if (mounted) Navigator.pop(context);
              }
            },
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

  // remove _finishWorkout as it is now inside the widget builder logic or implicitly handled
}

class _ExerciseInputCard extends StatefulWidget {
  final Exercise exercise;
  final ExerciseSet? lastPerformance;
  final bool isLoadingHistory;
  final Function(ExerciseSet) onSetCompleted;
  final Function(ExerciseSet, ExerciseSet)? onSetEdited; // New callback
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
    this.onSetEdited,
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
  int _rpeValue = 8; // 1-10 scale
  bool _isAssisted = false;
  bool _isDropSet = false; // New state
  bool _isKg = GymDatabase().settingsBox.get(
    'default_is_kg',
    defaultValue: true,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      clipBehavior: Clip.antiAlias,
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

                    // RPE SELECTOR (1-10 Numeric)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "RPE (EFFORT 1-10)",
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 44,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: 10,
                            itemBuilder: (context, index) {
                              final rpe = index + 1;
                              final isSelected = _rpeValue == rpe;
                              final color = _getRpeValueColor(rpe);

                              return GestureDetector(
                                onTap: () => setState(() => _rpeValue = rpe),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 38,
                                  margin: const EdgeInsets.only(right: 6),
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
                                    '$rpe',
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.black
                                          : Colors.grey,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _getRpeDescription(_rpeValue),
                          style: TextStyle(
                            color: _getRpeValueColor(_rpeValue),
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ASSISTED TOGGLE
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2E),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.people_outline,
                            color: _isAssisted
                                ? Colors.orange
                                : Colors.grey[600],
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Spotter Assisted?",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  "Mark if someone helped you",
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Transform.scale(
                            scale: 0.85,
                            child: Switch(
                              value: _isAssisted,
                              onChanged: (val) =>
                                  setState(() => _isAssisted = val),
                              activeThumbColor: Colors.orange,
                              activeTrackColor: Colors.orange.withValues(
                                alpha: 0.3,
                              ),
                              inactiveThumbColor: Colors.grey[600],
                              inactiveTrackColor: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2E),
                        borderRadius: BorderRadius.circular(8),
                        border: _isDropSet
                            ? Border.all(color: Colors.amber, width: 1)
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.layers,
                            color: _isDropSet ? Colors.amber : Colors.grey[600],
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Drop Set?",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (_isDropSet)
                                  Text(
                                    "Weight lowered immediately",
                                    style: TextStyle(
                                      color: Colors.amber[200],
                                      fontSize: 10,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Transform.scale(
                            scale: 0.85,
                            child: Switch(
                              value: _isDropSet,
                              onChanged: (val) =>
                                  setState(() => _isDropSet = val),
                              activeThumbColor: Colors.amber,
                              activeTrackColor: Colors.amber.withValues(
                                alpha: 0.3,
                              ),
                              inactiveThumbColor: Colors.grey[600],
                              inactiveTrackColor: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
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
                        return GestureDetector(
                          onTap: () => _showEditSetDialog(context, set),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[900],
                              borderRadius: BorderRadius.circular(8),
                              border: set.isDropSet
                                  ? Border.all(color: Colors.amber, width: 1)
                                  : Border.all(color: Colors.white10),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: set.isDropSet
                                        ? Colors.amber
                                        : Colors.grey[800],
                                  ),
                                  child: Text(
                                    "$idx",
                                    style: TextStyle(
                                      color: set.isDropSet
                                          ? Colors.black
                                          : Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
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
                                if (set.isDropSet) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withValues(
                                        alpha: 0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      "DROP",
                                      style: TextStyle(
                                        color: Colors.amber,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
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
                                  Icons.edit,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
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

  // Color for numeric RPE (1-10)
  Color _getRpeValueColor(int rpe) {
    if (rpe <= 6) return Colors.greenAccent;
    if (rpe <= 8) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  // Description for numeric RPE
  String _getRpeDescription(int rpe) {
    switch (rpe) {
      case 1:
        return "Very easy - could do 9+ more reps";
      case 2:
        return "Easy - could do 8+ more reps";
      case 3:
        return "Light - could do 7+ more reps";
      case 4:
        return "Light-moderate - could do 6+ more reps";
      case 5:
        return "Moderate - could do 5+ more reps";
      case 6:
        return "Moderate - could do 4+ more reps";
      case 7:
        return "Somewhat hard - could do 3 more reps";
      case 8:
        return "Hard - could do 2 more reps";
      case 9:
        return "Very hard - could do 1 more rep";
      case 10:
        return "Max effort - couldn't do more";
      default:
        return "Rate your effort";
    }
  }

  // 🧠 THE GYM BRAIN ALGORITHM (Arabic with Gym Math)
  String _generateRecommendation({
    required int reps,
    required double weight,
    required int targetReps,
    required int rpe,
    required bool isAssisted,
    required bool isKg,
  }) {
    // Helper for number formatting (5.0 -> 5, 2.5 -> 2.5)
    String formatNum(double w) {
      return w.toStringAsFixed(1).replaceAll('.0', '');
    }

    // Format increment suggestion based on unit
    String formatIncrementSuggestion({
      required double small,
      required double large,
    }) {
      if (isKg) {
        // KG suggestions: 2.5 - 5 kg
        return "${formatNum(small)} - ${formatNum(large)} كجم";
      } else {
        // LB suggestions: 5 - 10 lb
        return "${formatNum(small)} - ${formatNum(large)} lb";
      }
    }

    final unitStr = isKg ? "كجم" : "lb";
    final weightStr = formatNum(weight);

    // Case 1: Assisted
    if (isAssisted) {
      return "⚠️ المرة دي بمساعدة.. ثبت الوزن ($weightStr $unitStr) المرة الجاية عشان تتقن الأداء.";
    }

    // Case 2: Too Easy - Suggest increasing weight
    if (rpe <= 7 && reps >= targetReps) {
      // Suggest increase based on RPE and unit
      if (rpe <= 5) {
        // Very easy, suggest bigger jump
        final suggestion = isKg
            ? formatIncrementSuggestion(small: 5, large: 7.5)
            : formatIncrementSuggestion(small: 10, large: 15);
        return "🚀 عاش يا وحش! التمرين سهل.. زود $suggestion المرة الجاية.";
      } else {
        // Moderately easy, suggest smaller jump
        final suggestion = isKg
            ? formatIncrementSuggestion(small: 2.5, large: 5)
            : formatIncrementSuggestion(small: 5, large: 10);
        return "🚀 عاش! التمرين سهل.. زود $suggestion المرة الجاية.";
      }
    }

    // Case 3: Perfect Zone
    if (rpe == 8 || rpe == 9) {
      return "✅ الله ينور! الوزن ($weightStr $unitStr) ممتاز.. حافظ عليه وركز في التكنيك.";
    }

    // Case 4: Failure/Max Effort
    if (rpe == 10 || reps < targetReps) {
      return "🔥 أداء عالي! ريح كويس وثبت الوزن ($weightStr $unitStr) لحد ما تجيبه مرتاح.";
    }

    // Fallback
    return "💪 سيت كويس! كمّل كده.";
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
      // Map rpeValue to string for legacy compatibility
      String legacyRpe;
      if (_rpeValue <= 6) {
        legacyRpe = 'Easy';
      } else if (_rpeValue <= 8) {
        legacyRpe = 'Good';
      } else {
        legacyRpe = 'Hard';
      }

      final set = ExerciseSet(
        exerciseName: widget.exercise.name,
        weight: weight,
        reps: reps,
        rpe: legacyRpe,
        rpeValue: _rpeValue,
        isAssisted: _isAssisted,
        isCompleted: true,

        unit: _isKg ? 'kg' : 'lb',
        isDropSet: _isDropSet,
      );

      widget.onSetCompleted(set);

      // Generate and show Gym Brain recommendation
      final recommendation = _generateRecommendation(
        reps: reps,
        weight: weight,
        targetReps: 8, // Default target, could be customized per exercise
        rpe: _rpeValue,
        isAssisted: _isAssisted,
        isKg: _isKg,
      );

      // Show recommendation as Arabic Bottom Sheet (if enabled)
      if (GymDatabase().enableAiFeedback) {
        _showPerformanceSheet(recommendation);
      }

      // Reset assisted toggle after each set
      // Reset state
      setState(() {
        _isAssisted = false;
        _isDropSet = false;
      });

      FocusScope.of(context).unfocus();
    }
  }

  void _showPerformanceSheet(String recommendation) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF39FF14).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.psychology,
                      color: Color(0xFF39FF14),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "تحليل الأداء",
                    style: TextStyle(
                      color: Color(0xFF39FF14),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Recommendation Text (Arabic - RTL)
              Directionality(
                textDirection: TextDirection.rtl,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _getSheetAccentColor().withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    recommendation,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      height: 1.6,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Close Button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey[700]!),
                    ),
                  ),
                  child: const Text(
                    "تمام 👍",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getSheetAccentColor() {
    if (_isAssisted) return Colors.orange;
    if (_rpeValue <= 7) return Colors.greenAccent;
    if (_rpeValue <= 9) return const Color(0xFF39FF14);
    return Colors.redAccent;
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

  void _showEditSetDialog(BuildContext context, ExerciseSet set) {
    final weightCtrl = TextEditingController(text: set.weight.toString());
    final repsCtrl = TextEditingController(text: set.reps.toString());
    bool isDrop = set.isDropSet;
    int rpe = set.rpeValue ?? 8;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text("Edit Set", style: TextStyle(color: Colors.white)),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: weightCtrl,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: "Weight",
                          labelStyle: TextStyle(color: Colors.grey),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF39FF14)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: repsCtrl,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Reps",
                          labelStyle: TextStyle(color: Colors.grey),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF39FF14)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "RPE: $rpe",
                      style: const TextStyle(color: Colors.white),
                    ),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getRpeValueColor(rpe),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: rpe.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  activeColor: _getRpeValueColor(rpe),
                  onChanged: (v) => setState(() => rpe = v.round()),
                ),
                CheckboxListTile(
                  title: const Text(
                    "Drop Set?",
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  value: isDrop,
                  activeColor: Colors.amber,
                  checkColor: Colors.black,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) => setState(() => isDrop = v ?? false),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.pop(ctx),
          ),
          TextButton(
            child: const Text(
              "Save",
              style: TextStyle(
                color: Color(0xFF39FF14),
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () {
              final newWeight = double.tryParse(weightCtrl.text) ?? set.weight;
              final newReps = int.tryParse(repsCtrl.text) ?? set.reps;

              String legacyRpe;
              if (rpe <= 6)
                legacyRpe = 'Easy';
              else if (rpe <= 8)
                legacyRpe = 'Good';
              else
                legacyRpe = 'Hard';

              final newSet = ExerciseSet(
                exerciseName: set.exerciseName,
                weight: newWeight,
                reps: newReps,
                rpe: legacyRpe,
                rpeValue: rpe,
                unit: set.unit,
                isAssisted: set.isAssisted,
                isCompleted: true,
                isDropSet: isDrop,
              );

              widget.onSetEdited?.call(set, newSet);
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }
}

extension TextHelper on TextStyle {
  Text toText(String content) => Text(content, style: this);
}
