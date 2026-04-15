import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/gym_models.dart';
import '../services/database_service.dart';
import '../l10n/app_localizations.dart';
import '../utils/workout_helper.dart';

class WorkoutDetailScreen extends StatelessWidget {
  final WorkoutSession session;

  const WorkoutDetailScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    // Group sets by exercise
    final groupedSets = <String, List<ExerciseSet>>{};
    for (var set in session.sets) {
      if (!groupedSets.containsKey(set.exerciseName)) {
        groupedSets[set.exerciseName] = [];
      }
      groupedSets[set.exerciseName]!.add(set);
    }

    final langCode = Localizations.localeOf(context).languageCode;
    final localeName = langCode == 'ar' ? 'ar' : 'en_US';
    final dateFormat = DateFormat.yMMMd(localeName);
    // ... rest of setup

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              session.routineName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              dateFormat.format(session.date),
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF1C1C1E),
                  title: Text(
                    AppLocalizations.of(context)?.deleteWorkout ?? "Delete Workout?",
                    style: const TextStyle(color: Colors.white),
                  ),
                  content: Text(
                    AppLocalizations.of(context)?.deleteUndone ?? "This action cannot be undone.",
                    style: const TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(
                        AppLocalizations.of(context)?.cancelBtn ?? "Cancel",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(
                        AppLocalizations.of(context)?.delete ?? "Delete",
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await GymDatabase().deleteSession(session.id);
                if (context.mounted) {
                  Navigator.pop(context, true); // Go back to history
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)?.workoutDeleted ?? "Workout deleted"),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Stats Header
          _buildStatsHeader(context, session),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context)?.sessionBreakdown ?? "Session Breakdown",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Exercise Cards
          ...groupedSets.entries.map((entry) {
            return _buildExerciseCard(entry.key, entry.value);
          }),
        ],
      ),
    );
  }

  Widget _buildStatsHeader(BuildContext context, WorkoutSession session) {
    // Calculate Volume (Normalized to KG)
    double totalVolume = 0;
    for (var set in session.sets) {
      double weightInKg = set.weight;
      if (set.unit == 'lb') {
        weightInKg = set.weight * 0.453592;
      }
      totalVolume += (weightInKg * set.reps);
    }

    // Format Duration
    final langCode = Localizations.localeOf(context).languageCode;
    final duration = Duration(seconds: session.durationInSeconds);
    String durationString = formatDuration(duration, langCode);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatItem(AppLocalizations.of(context)?.durationLabel.toUpperCase() ?? "DURATION", durationString, Icons.timer),
          Container(width: 1, height: 40, color: Colors.white10),
          _buildStatItem(
            AppLocalizations.of(context)?.volumeLabel.toUpperCase() ?? "VOLUME",
            "${totalVolume.toStringAsFixed(1)} ${AppLocalizations.of(context)?.kgLabel ?? 'kg'}",
            Icons.fitness_center,
          ),
          Container(width: 1, height: 40, color: Colors.white10),
          _buildStatItem(AppLocalizations.of(context)?.setsLabel.toUpperCase() ?? "SETS", "${session.sets.length}", Icons.layers),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF39FF14), size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseCard(String exerciseName, List<ExerciseSet> sets) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              exerciseName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const Divider(height: 1, color: Colors.white10),
          ListView.separated(
            padding: const EdgeInsets.all(16),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sets.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final set = sets[index];
              return Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: set.isDropSet ? Colors.amber : Colors.grey[800],
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      "${index + 1}",
                      style: TextStyle(
                        color: set.isDropSet ? Colors.black : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    "${set.weight}${set.unit} x ${set.reps}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (set.isDropSet) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        "DROP",
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  _buildRpeIndicator(set.rpeValue),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRpeIndicator(int rpe) {
    Color color;
    if (rpe <= 6) {
      color = Colors.greenAccent;
    } else if (rpe <= 8) {
      color = Colors.orangeAccent;
    } else {
      color = Colors.redAccent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        "RPE $rpe",
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
