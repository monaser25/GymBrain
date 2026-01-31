import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/gym_models.dart';
import '../services/database_service.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nameController = TextEditingController();
  bool _addStarterPack = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _onGetStarted() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      _showValidationSheet('Please enter your name to continue.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final db = GymDatabase();

      // Save user name
      await db.settingsBox.put('user_name', name);

      // If starter pack is enabled, seed the database
      if (_addStarterPack) {
        await _seedStarterPack(db);
      }

      // Mark onboarding as complete
      await db.settingsBox.put('is_first_time', false);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showValidationSheet('Something went wrong. Please try again.');
    }
  }

  Future<void> _seedStarterPack(GymDatabase db) async {
    const uuid = Uuid();

    // ===== STARTER EXERCISES =====
    final exercises = <Exercise>[
      // Push Exercises
      Exercise(
        id: uuid.v4(),
        name: 'Bench Press',
        setupNote: 'Flat bench, grip slightly wider than shoulders',
        targetSets: 4,
      ),
      Exercise(
        id: uuid.v4(),
        name: 'Incline Dumbbell Press',
        setupNote: 'Bench at 30-45 degrees',
        targetSets: 3,
      ),
      Exercise(
        id: uuid.v4(),
        name: 'Overhead Press',
        setupNote: 'Standing or seated, barbell or dumbbells',
        targetSets: 4,
      ),
      Exercise(
        id: uuid.v4(),
        name: 'Dips',
        setupNote: 'Lean forward for chest, upright for triceps',
        targetSets: 3,
      ),
      Exercise(
        id: uuid.v4(),
        name: 'Tricep Pushdown',
        setupNote: 'Cable machine, rope or bar attachment',
        targetSets: 3,
      ),
      Exercise(
        id: uuid.v4(),
        name: 'Lateral Raises',
        setupNote: 'Light weight, control the movement',
        targetSets: 3,
      ),

      // Pull Exercises
      Exercise(
        id: uuid.v4(),
        name: 'Barbell Row',
        setupNote: 'Hinge at hips, pull to lower chest',
        targetSets: 4,
      ),
      Exercise(
        id: uuid.v4(),
        name: 'Pull-ups',
        setupNote: 'Wide grip for lats, close grip for mid-back',
        targetSets: 3,
      ),
      Exercise(
        id: uuid.v4(),
        name: 'Lat Pulldown',
        setupNote: 'Pull to upper chest, squeeze lats',
        targetSets: 3,
      ),
      Exercise(
        id: uuid.v4(),
        name: 'Face Pulls',
        setupNote: 'Rope attachment, pull to face level',
        targetSets: 3,
      ),
      Exercise(
        id: uuid.v4(),
        name: 'Barbell Curl',
        setupNote: 'EZ bar or straight bar, control the negative',
        targetSets: 3,
      ),
      Exercise(
        id: uuid.v4(),
        name: 'Hammer Curl',
        setupNote: 'Neutral grip, targets brachialis',
        targetSets: 3,
      ),

      // Legs Exercises
      Exercise(
        id: uuid.v4(),
        name: 'Squat',
        setupNote: 'Bar on upper traps or front rack position',
        targetSets: 4,
      ),
      Exercise(
        id: uuid.v4(),
        name: 'Romanian Deadlift',
        setupNote: 'Keep slight knee bend, feel hamstring stretch',
        targetSets: 4,
      ),
      Exercise(
        id: uuid.v4(),
        name: 'Leg Press',
        setupNote: 'Feet shoulder-width, full range of motion',
        targetSets: 3,
      ),
      Exercise(
        id: uuid.v4(),
        name: 'Leg Curl',
        setupNote: 'Lying or seated, squeeze at contraction',
        targetSets: 3,
      ),
      Exercise(
        id: uuid.v4(),
        name: 'Leg Extension',
        setupNote: 'Controlled movement, pause at top',
        targetSets: 3,
      ),
      Exercise(
        id: uuid.v4(),
        name: 'Calf Raises',
        setupNote: 'Full stretch at bottom, squeeze at top',
        targetSets: 4,
      ),
    ];

    // Save all exercises
    for (final exercise in exercises) {
      await db.saveExercise(exercise);
    }

    // ===== STARTER ROUTINES =====
    // Helper to find exercise ID by name
    String findId(String name) {
      return exercises.firstWhere((e) => e.name == name).id;
    }

    final routines = <Routine>[
      Routine(
        id: uuid.v4(),
        name: 'Push Day',
        exerciseIds: [
          findId('Bench Press'),
          findId('Incline Dumbbell Press'),
          findId('Overhead Press'),
          findId('Dips'),
          findId('Tricep Pushdown'),
          findId('Lateral Raises'),
        ],
      ),
      Routine(
        id: uuid.v4(),
        name: 'Pull Day',
        exerciseIds: [
          findId('Barbell Row'),
          findId('Pull-ups'),
          findId('Lat Pulldown'),
          findId('Face Pulls'),
          findId('Barbell Curl'),
          findId('Hammer Curl'),
        ],
      ),
      Routine(
        id: uuid.v4(),
        name: 'Leg Day',
        exerciseIds: [
          findId('Squat'),
          findId('Romanian Deadlift'),
          findId('Leg Press'),
          findId('Leg Curl'),
          findId('Leg Extension'),
          findId('Calf Raises'),
        ],
      ),
    ];

    // Save all routines
    for (final routine in routines) {
      await db.saveRoutine(routine);
    }
  }

  void _showValidationSheet(String message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.orangeAccent,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF39FF14),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 60),

              // Logo
              Hero(
                tag: 'app_logo',
                child: Image.asset(
                  'assets/app_icon.png',
                  width: 120,
                  height: 120,
                ),
              ),
              const SizedBox(height: 32),

              // Welcome Title
              Text(
                'Welcome to',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'GYM BRAIN',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF39FF14),
                  letterSpacing: 3,
                  shadows: [
                    Shadow(
                      color: const Color(0xFF39FF14).withValues(alpha: 0.5),
                      blurRadius: 15,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your intelligent workout companion',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),

              const SizedBox(height: 48),

              // Name Input
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                textAlign: TextAlign.center,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'Your Name',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFF39FF14),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Starter Pack Checkbox
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                  border: _addStarterPack
                      ? Border.all(
                          color: const Color(0xFF39FF14).withValues(alpha: 0.3),
                          width: 1,
                        )
                      : null,
                ),
                child: CheckboxListTile(
                  value: _addStarterPack,
                  onChanged: (value) =>
                      setState(() => _addStarterPack = value ?? true),
                  activeColor: const Color(0xFF39FF14),
                  checkColor: Colors.black,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text(
                    'Add Starter Pack?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Includes basic exercises & Push/Pull/Legs routine.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Get Started Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _onGetStarted,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF39FF14),
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: const Color(
                      0xFF39FF14,
                    ).withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Get Started',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
