library;

// Gym Math Utility Functions
//
// Helper functions for weight conversions and formatting with hybrid units (KG/LB).

/// Format a weight value to remove trailing zeros
/// Example: 5.0 -> "5", 2.5 -> "2.5"
String formatWeight(double weight) {
  if (weight == weight.roundToDouble()) {
    return weight.toInt().toString();
  }
  return weight.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
}

/// Convert KG to LB
/// Uses standard conversion: 1 kg = 2.204 lb
double kgToLb(double kg) {
  return kg * 2.204;
}

/// Convert LB to KG
/// Uses standard conversion: 1 lb = 0.453592 kg
double lbToKg(double lb) {
  return lb * 0.453592;
}

/// Round LB to nearest 5 (Gym Standard)
/// Gyms typically use plates in increments of 5 lbs
int roundLbToGymStandard(double lb) {
  int rounded = ((lb / 5).round() * 5);
  // If rounded to 0 but we had some weight, use at least 5
  if (rounded == 0 && lb > 0) rounded = 5;
  return rounded;
}

/// Format weight with both KG and LB (Gym Math)
/// Example: 2.5 kg -> "2.5 كجم (5 lb)"
/// Example: 5 kg -> "5 كجم (10 lb)"
String formatWeightHybrid(double kg) {
  String kgStr = formatWeight(kg);
  double lbs = kgToLb(kg);
  int roundedLbs = roundLbToGymStandard(lbs);
  return "$kgStr كجم ($roundedLbs lb)";
}

/// Format weight with both KG and LB in bold (for Arabic AI messages)
/// Example: 2.5 kg -> "**2.5 كجم (5 lb)**"
String formatWeightHybridBold(double kg) {
  return "**${formatWeightHybrid(kg)}**";
}

/// Format weight based on preference
/// If preferKg is true, shows "X kg", otherwise shows "X lb"
String formatWeightWithUnit(double value, bool isKg) {
  String valueStr = formatWeight(value);
  return isKg ? "$valueStr kg" : "$valueStr lb";
}

/// Normalize weight to KG for consistent comparisons
/// Takes a weight and its current unit, returns the weight in KG
double normalizeToKg(double weight, String unit) {
  if (unit.toLowerCase() == 'lb') {
    return lbToKg(weight);
  }
  return weight;
}
