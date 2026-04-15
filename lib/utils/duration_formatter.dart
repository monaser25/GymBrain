/// Formats a [Duration] into a localized short string.
///
/// English: "5m 30s"  or  "1h 5m 30s"
/// Arabic:  "5د 30ث"  or  "1س 5د 30ث"
String formatLocalizedDuration(Duration duration, String locale) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);

  if (locale == 'ar') {
    if (hours > 0) return '$hoursس $minutesد $secondsث';
    return '$minutesد $secondsث';
  }
  if (hours > 0) return '${hours}h ${minutes}m ${seconds}s';
  return '${minutes}m ${seconds}s';
}
