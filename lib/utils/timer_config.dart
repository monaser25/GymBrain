class TimerConfig {
  static int? getRestTime(String exerciseName) {
    final name = exerciseName.toLowerCase();

    // 1. Power / Strength (Heavy Compound) -> 3 Mins (180s)
    if (name.contains('squat') ||
        name.contains('deadlift') ||
        // "bench press" matches flat bench.
        // Note: "incline bench press" would also match "bench press" string if we aren't careful.
        // But usually we check "incline" first if we want to differentiate,
        // OR we assume "bench press" implies heavy unless qualified.
        // However, user put "incline" in 120s category.
        (name.contains('bench press') && !name.contains('incline')) ||
        name.contains('overhead press')) {
      return 180;
    }

    // 2. Hypertrophy (Compound) -> 2 Mins (120s)
    if (name.contains('incline') || // Covers Incline Bench, Incline DB Press
        name.contains('row') ||
        name.contains('pull down') ||
        name.contains('leg press') ||
        name.contains('dip') ||
        name.contains('pull up')) {
      return 120;
    }

    // 3. Isolation / Endurance -> 1 Min (60s)
    if (name.contains('curl') ||
        name.contains('extension') ||
        name.contains('raise') ||
        name.contains('fly') ||
        name.contains('pushdown') ||
        name.contains('calf') ||
        name.contains('abs') ||
        name.contains('crunch')) {
      return 60;
    }

    // Default -> Null (Use App Setting)
    return null;
  }
}
