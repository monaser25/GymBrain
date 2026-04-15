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

String getLocalizedExerciseName(BuildContext context, String englishName) {
  final lang = Localizations.localeOf(context).languageCode;
  if (lang != 'ar') return englishName;

  switch (englishName) {
    case 'Bench Press': return 'بنش برس';
    case 'Squat': return 'سكوات (قرفصاء)';
    case 'Deadlift': return 'رفعة مميتة';
    case 'Overhead Press': return 'ضغط علوي للأكتاف';
    case 'Pull-Up': return 'عقلة';
    case 'Barbell Row': return 'تجديف بالبار';
    case 'Dumbbell Curl': return 'بايسبس دامبلز';
    case 'Triceps Extension': return 'ترايسبس خلفي';
    case 'Leg Press': return 'دفع أرجل';
    case 'Leg Curl': return 'مرجحة أرجل خلفي';
    case 'Leg Extension': return 'رفرفة أرجل أمامي';
    case 'Calf Raise': return 'سمانة';
    case 'Lat Pulldown': return 'سحب ظهر أمامي';
    case 'Seated Cable Row': return 'تجديف كابل أرضي';
    case 'Incline Bench Press': return 'بنش برس علوي';
    case 'Lateral Raise': return 'رفرفة أكتاف جانبي';
    case 'Face Pull': return 'سحب خلفي بالكروس (Face Pull)';
    case 'Romanian Deadlift (RDL)': return 'رفعة مميتة رومانية (RDL)';
    case 'Hip Thrust': return 'دفع حوض (Hip Thrust)';
    case 'Crunch': return 'طحن معدة';
    case 'Plank': return 'بلانك';
    default: return englishName;
  }
}

String? getLocalizedExerciseNote(BuildContext context, String? englishNote) {
  if (englishNote == null || englishNote.isEmpty) return englishNote;
  final lang = Localizations.localeOf(context).languageCode;
  if (lang != 'ar') return englishNote;

  switch (englishNote) {
    case 'Flat bench, grip slightly wider than shoulders': return 'مستلقٍ على بنش مستوي، قبضة أوسع قليلاً من الكتفين';
    case 'Bench at 30-45 degrees': return 'بنش بزاوية 30-45 درجة';
    case 'Standing or seated, barbell or dumbbells': return 'واقفاً أو جالساً، باستخدام البار أو الدامبلز';
    case 'Lean forward for chest, upright for triceps': return 'مل للأمام لاستهداف الصدر، أو قف مستقيماً لاستهداف الترايسبس';
    case 'Cable machine, rope or bar attachment': return 'جهاز الكيبل، بكرة أو حبل';
    case 'Light weight, control the movement': return 'أوزان خفيفة، مع التحكم بالحركة';
    case 'Hinge at hips, pull to lower chest': return 'انحنِ من الورك واسحب للصدر السفلي';
    case 'Wide grip for lats, close grip for mid-back': return 'قبضة واسعة للمجنص، ضيقة للظهر الأوسط';
    case 'Pull to upper chest, squeeze lats': return 'اسحب للصدر العلوي واعصر المجنص';
    case 'Rope attachment, pull to face level': return 'باستخدام الحبل، اسحب لمستوى الوجه';
    case 'EZ bar or straight bar, control the negative': return 'بار متعرج أو مستقيم، مع التحكم في النزول';
    case 'Neutral grip, targets brachialis': return 'قبضة محايدة، يستهدف عضلة البراكيلس';
    case 'Bar on upper traps or front rack position': return 'البار على الترابيس العلوية أو الرف الأمامي';
    case 'Keep slight knee bend, feel hamstring stretch': return 'ثني الركبة قليلاً والشعور بتمدد الهامسترنج';
    case 'Feet shoulder-width, full range of motion': return 'القدمين بعرض الكتفين، مدى حركي كامل';
    case 'Lying or seated, squeeze at contraction': return 'مستلقٍ أو جالس، اعصر في قمة الانقباض';
    case 'Controlled movement, pause at top': return 'حركة متحكم بها وتوقف مؤقت بالأعلى';
    case 'Full stretch at bottom, squeeze at top': return 'تمدد كامل بالأسفل وعصر بالقمة';
    default: return englishNote;
  }
}
