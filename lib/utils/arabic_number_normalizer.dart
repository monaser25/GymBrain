/// Converts Eastern Arabic numerals (٠١٢٣٤٥٦٧٨٩) to Western digits (0123456789).
///
/// iOS Arabic keyboards output Eastern Arabic numerals by default,
/// which causes `double.tryParse` / `int.tryParse` to return null.
/// Call this on any user-entered text before parsing.
String normalizeArabicNumbers(String input) {
  const arabicNumbers = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  const englishNumbers = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  for (int i = 0; i < arabicNumbers.length; i++) {
    input = input.replaceAll(arabicNumbers[i], englishNumbers[i]);
  }
  // Also normalize the Arabic decimal separator (٫) to a dot
  input = input.replaceAll('٫', '.');
  return input;
}

/// Convenience wrapper: normalizes Arabic numerals then parses as double.
double? parseLocalizedDouble(String text) {
  return double.tryParse(normalizeArabicNumbers(text.trim()));
}

/// Convenience wrapper: normalizes Arabic numerals then parses as int.
int? parseLocalizedInt(String text) {
  return int.tryParse(normalizeArabicNumbers(text.trim()));
}
