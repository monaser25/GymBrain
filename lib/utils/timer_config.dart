class TimerConfig {
  static int getRestTime(String exerciseName) {
    final name = exerciseName.toLowerCase();

    // Heavy Compounds -> 3 Mins
    if (name.contains('squat') ||
        name.contains('deadlift') ||
        name.contains('bench press') ||
        name.contains('dumbbell press') ||
        name.contains('shoulder press')) {
      return 180;
    }

    // Secondary Compounds -> 2 Mins
    if (name.contains('leg press') ||
        name.contains('overhead') ||
        name.contains('row')) {
      return 120;
    }

    // Isolation -> 1 Min
    if (name.contains('fly') ||
        name.contains('curl') ||
        name.contains('extension') ||
        name.contains('raise') ||
        name.contains('pushdown')) {
      return 60;
    }

    // Default
    return 90;
  }
}
