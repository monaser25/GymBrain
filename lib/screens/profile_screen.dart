import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/database_service.dart';
import '../l10n/app_localizations.dart';
import 'progress_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _db = GymDatabase();

  // Profile Data
  String? _userName;
  DateTime? _userDob;
  int? get _userAge => _userDob != null ? calculateAge(_userDob!) : null;

  int calculateAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }
  double? _userHeightCm;
  String? _userGender;
  double? _activityLevel;

  // Activity Level Options
  Map<double, String> _getActivityLevels(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return {
      1.2: l10n?.activitySedentary ?? "Sedentary (little or no exercise)",
      1.375: l10n?.activityLightly ?? "Lightly active (1-3 days/week)",
      1.55: l10n?.activityModerately ?? "Moderately active (3-5 days/week)",
      1.725: l10n?.activityVery ?? "Very active (6-7 days/week)",
      1.9: l10n?.activityExtra ?? "Extra active (very hard exercise)",
    };
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    final settingsBox = _db.settingsBox;
    setState(() {
      _userName = settingsBox.get('user_name');
      final dobStr = settingsBox.get('user_dob');
      if (dobStr != null) {
        _userDob = DateTime.tryParse(dobStr);
      } else if (settingsBox.containsKey('user_age')) {
        final age = settingsBox.get('user_age');
        if (age is int) {
          _userDob = DateTime.now().subtract(Duration(days: age * 365));
          _db.settingsBox.put('user_dob', _userDob!.toIso8601String());
        }
      }
      _userHeightCm = settingsBox.get('user_height_cm');
      _userGender = settingsBox.get('user_gender');
      _activityLevel = settingsBox.get('activity_level');
    });
  }

  Future<void> _saveField(String key, dynamic value) async {
    await _db.settingsBox.put(key, value);
    _loadProfile();
  }

  double? get _currentWeight {
    final latestInBody = _db.getLatestInBody();
    return latestInBody?.weight;
  }

  // BMI Calculation
  double? get _bmi {
    final weight = _currentWeight;
    final height = _userHeightCm;
    if (weight == null || height == null || height == 0) return null;
    return weight / ((height / 100) * (height / 100));
  }

  String _getBmiCategory(BuildContext context, double bmi) {
    if (bmi < 18.5) return AppLocalizations.of(context)?.bmiUnderweight ?? "Underweight";
    if (bmi < 25) return AppLocalizations.of(context)?.bmiNormal ?? "Normal";
    if (bmi < 30) return AppLocalizations.of(context)?.bmiOverweight ?? "Overweight";
    return AppLocalizations.of(context)?.bmiObese ?? "Obese";
  }

  Color _getBmiColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return const Color(0xFF39FF14);
    if (bmi < 30) return Colors.orange;
    return Colors.redAccent;
  }

  // TDEE Calculation (Mifflin-St Jeor)
  double? get _tdee {
    final weight = _currentWeight;
    final height = _userHeightCm;
    final age = _userAge;
    final gender = _userGender;
    final activity = _activityLevel ?? 1.55;

    if (weight == null || height == null || age == null) return null;

    double bmr;
    if (gender == 'Female') {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161;
    } else {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
    }
    return bmr * activity;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.myProfile ?? "My Profile",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SMART METRICS SECTION
            _buildSmartMetricsSection(),

            const SizedBox(height: 32),

            // PERSONAL INFO SECTION
            Text(
              AppLocalizations.of(context)?.personalInfo ?? "PERSONAL INFO",
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),

            _buildInfoTile(
              icon: Icons.person_outline,
              label: AppLocalizations.of(context)?.name ?? "Name",
              value: _userName ?? "Tap to set",
              onTap: () => _editName(),
            ),
            _buildInfoTile(
              icon: Icons.cake_outlined,
              label: AppLocalizations.of(context)?.age ?? "Age",
              value: _userAge != null ? "$_userAge ${AppLocalizations.of(context)?.yearsOld ?? 'years'}" : "Tap to set",
              onTap: () => _editDob(),
            ),
            _buildInfoTile(
              icon: Icons.height,
              label: AppLocalizations.of(context)?.height ?? "Height",
              value: _userHeightCm != null
                  ? _db.isBodyWeightKg
                      ? "${_userHeightCm!.toStringAsFixed(1)} ${AppLocalizations.of(context)?.cmLabel ?? 'cm'}"
                      : "${(_userHeightCm! / 2.54).toStringAsFixed(1)} ${AppLocalizations.of(context)?.inchLabel ?? 'in'}"
                  : "Tap to set",
              onTap: () => _editHeight(),
            ),
            _buildInfoTile(
              icon: Icons.wc_outlined,
              label: AppLocalizations.of(context)?.gender ?? "Gender",
              value: _userGender != null 
                  ? (_userGender == 'Male' ? (AppLocalizations.of(context)?.male ?? 'Male') : (AppLocalizations.of(context)?.female ?? 'Female'))
                  : "Tap to set",
              onTap: () => _editGender(),
            ),
            _buildInfoTile(
              icon: Icons.directions_run,
              label: AppLocalizations.of(context)?.activityLevel ?? "Activity Level",
              value: _activityLevel != null
                  ? _getActivityLevels(context)[_activityLevel] ?? "Custom"
                  : "Tap to set",
              onTap: () => _editActivityLevel(),
            ),

            const SizedBox(height: 32),

            // BODY STATS (READ-ONLY, SYNCED)
            Text(
              AppLocalizations.of(context)?.bodyStats ?? "BODY STATS",
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),

            _buildInfoTile(
              icon: Icons.monitor_weight_outlined,
              label: AppLocalizations.of(context)?.currentWeight ?? "Current Weight",
              value: _currentWeight != null
                  ? _db.isBodyWeightKg
                      ? "${_currentWeight!.toStringAsFixed(1)} ${AppLocalizations.of(context)?.kgLabel ?? 'kg'}"
                      : "${(_currentWeight! * 2.20462).toStringAsFixed(1)} ${AppLocalizations.of(context)?.lbLabel ?? 'lb'}"
                  : "Add in Stats tab",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProgressScreen()),
                );
              },
              isReadOnly: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartMetricsSection() {
    final bmi = _bmi;
    final tdee = _tdee;

    return Column(
      children: [
        // BMI Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1C1C1E),
                bmi != null
                    ? _getBmiColor(bmi).withValues(alpha: 0.2)
                    : const Color(0xFF1C1C1E),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: bmi != null
                  ? _getBmiColor(bmi).withValues(alpha: 0.5)
                  : Colors.white10,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.health_and_safety_outlined,
                          color: bmi != null ? _getBmiColor(bmi) : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)?.bodyMassIndex ?? "Body Mass Index",
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      bmi != null ? bmi.toStringAsFixed(1) : "--",
                      style: TextStyle(
                        color: bmi != null ? _getBmiColor(bmi) : Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (bmi != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getBmiColor(bmi).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getBmiCategory(context, bmi),
                    style: TextStyle(
                      color: _getBmiColor(bmi),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // TDEE Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1C1C1E),
                const Color(0xFF39FF14).withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF39FF14).withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          color: tdee != null
                              ? const Color(0xFF39FF14)
                              : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)?.dailyCalories ?? "Daily Calories (TDEE)",
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          tdee != null ? tdee.toStringAsFixed(0) : "--",
                          style: const TextStyle(
                            color: Color(0xFF39FF14),
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (tdee != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6, left: 4),
                            child: Text(
                              AppLocalizations.of(context)?.kcalLabel ?? "kcal",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (tdee == null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    AppLocalizations.of(context)?.missingData ?? "Missing data",
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    bool isReadOnly = false,
  }) {
    final isPlaceholder =
        value.contains("Tap to set") || value.contains("Add in");

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isReadOnly ? Colors.grey : const Color(0xFF39FF14),
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      color: isPlaceholder ? Colors.grey : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontStyle: isPlaceholder
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isReadOnly ? Icons.lock_outline : Icons.edit,
              color: Colors.grey[600],
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // EDIT DIALOGS
  void _editName() {
    final controller = TextEditingController(text: _userName ?? "");
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: Text(AppLocalizations.of(context)?.editNameTitle ?? "Edit Name", style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          cursorColor: const Color(0xFF39FF14),
          decoration: const InputDecoration(
            hintText: "Your name",
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF39FF14)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)?.cancelBtn ?? "Cancel", style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                _saveField('user_name', name);
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF39FF14),
              foregroundColor: Colors.black,
            ),
            child: Text(AppLocalizations.of(context)?.save ?? "Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _editDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _userDob ?? now.subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF39FF14),
              onPrimary: Colors.black,
              surface: Color(0xFF1C1C1E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _userDob) {
      await _saveField('user_dob', picked.toIso8601String());
    }
  }

  void _editHeight() {
    bool isCm = _db.isBodyWeightKg;
    final controller = TextEditingController(
      text: _userHeightCm != null
          ? (isCm ? _userHeightCm!.toStringAsFixed(1) : (_userHeightCm! / 2.54).toStringAsFixed(1))
          : "",
    );
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          final l10n = AppLocalizations.of(context);
          final unitLabel = isCm ? (l10n?.cmLabel ?? 'cm') : (l10n?.inchLabel ?? 'in');
          return AlertDialog(
            backgroundColor: const Color(0xFF1C1C1E),
            title: Text(l10n?.editHeightTitle ?? "Edit Height", style: const TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // CM / IN Toggle
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (!isCm) {
                              final val = double.tryParse(controller.text);
                              if (val != null) controller.text = (val * 2.54).toStringAsFixed(1);
                            }
                            setStateDialog(() => isCm = true);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isCm ? const Color(0xFF39FF14) : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              l10n?.cmLabel ?? "cm",
                              style: TextStyle(
                                color: isCm ? Colors.black : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (isCm) {
                              final val = double.tryParse(controller.text);
                              if (val != null) controller.text = (val / 2.54).toStringAsFixed(1);
                            }
                            setStateDialog(() => isCm = false);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: !isCm ? const Color(0xFF39FF14) : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              l10n?.inchLabel ?? "in",
                              style: TextStyle(
                                color: !isCm ? Colors.black : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white),
                  cursorColor: const Color(0xFF39FF14),
                  decoration: InputDecoration(
                    hintText: "${l10n?.height ?? 'Height'} ($unitLabel)",
                    hintStyle: const TextStyle(color: Colors.grey),
                    suffixText: unitLabel,
                    suffixStyle: const TextStyle(color: Colors.grey),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF39FF14)),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n?.cancelBtn ?? "Cancel", style: const TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () {
                  final val = double.tryParse(controller.text);
                  if (val != null) {
                    // Always store in cm
                    final heightCm = isCm ? val : val * 2.54;
                    if (heightCm > 50 && heightCm < 300) {
                      _saveField('user_height_cm', heightCm);
                    }
                  }
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF39FF14),
                  foregroundColor: Colors.black,
                ),
                child: Text(l10n?.save ?? "Save"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _editGender() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: Text(
          AppLocalizations.of(context)?.selectGenderTitle ?? "Select Gender",
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLocalizations.of(context)?.male ?? 'Male',
            AppLocalizations.of(context)?.female ?? 'Female'
          ].map((gender) {
            final isSelected = _userGender == gender;
            return GestureDetector(
              onTap: () {
                _saveField('user_gender', gender);
                Navigator.pop(context);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF39FF14).withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF39FF14)
                        : Colors.grey.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      gender == (AppLocalizations.of(context)?.male ?? 'Male') ? Icons.male : Icons.female,
                      color: isSelected ? const Color(0xFF39FF14) : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      gender,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle,
                        color: Color(0xFF39FF14),
                        size: 20,
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _editActivityLevel() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: Text(
          AppLocalizations.of(context)?.activityLevelTitle ?? "Activity Level",
          style: const TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _getActivityLevels(context).entries.map((entry) {
              final isSelected = _activityLevel == entry.key;
              return GestureDetector(
                onTap: () {
                  _saveField('activity_level', entry.key);
                  Navigator.pop(context);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF39FF14).withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF39FF14)
                          : Colors.grey.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF39FF14),
                          size: 18,
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
