import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/database_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _db = GymDatabase();

  // Profile Data
  String? _userName;
  int? _userAge;
  double? _userHeightCm;
  String? _userGender;
  double? _activityLevel;

  // Activity Level Options
  static final Map<double, String> activityLevels = {
    1.2: "Sedentary (little or no exercise)",
    1.375: "Lightly active (1-3 days/week)",
    1.55: "Moderately active (3-5 days/week)",
    1.725: "Very active (6-7 days/week)",
    1.9: "Extra active (very hard exercise)",
  };

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    final settingsBox = _db.settingsBox;
    setState(() {
      _userName = settingsBox.get('user_name');
      _userAge = settingsBox.get('user_age');
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

  String _getBmiCategory(double bmi) {
    if (bmi < 18.5) return "Underweight";
    if (bmi < 25) return "Normal";
    if (bmi < 30) return "Overweight";
    return "Obese";
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
        title: const Text(
          "My Profile",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
            const Text(
              "PERSONAL INFO",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),

            _buildInfoTile(
              icon: Icons.person_outline,
              label: "Name",
              value: _userName ?? "Tap to set",
              onTap: () => _editName(),
            ),
            _buildInfoTile(
              icon: Icons.cake_outlined,
              label: "Age",
              value: _userAge != null ? "$_userAge years" : "Tap to set",
              onTap: () => _editAge(),
            ),
            _buildInfoTile(
              icon: Icons.height,
              label: "Height",
              value: _userHeightCm != null
                  ? "${_userHeightCm!.toStringAsFixed(1)} cm"
                  : "Tap to set",
              onTap: () => _editHeight(),
            ),
            _buildInfoTile(
              icon: Icons.wc_outlined,
              label: "Gender",
              value: _userGender ?? "Tap to set",
              onTap: () => _editGender(),
            ),
            _buildInfoTile(
              icon: Icons.directions_run,
              label: "Activity Level",
              value: _activityLevel != null
                  ? activityLevels[_activityLevel] ?? "Custom"
                  : "Tap to set",
              onTap: () => _editActivityLevel(),
            ),

            const SizedBox(height: 32),

            // BODY STATS (READ-ONLY, SYNCED)
            const Text(
              "BODY STATS",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),

            _buildInfoTile(
              icon: Icons.monitor_weight_outlined,
              label: "Current Weight",
              value: _currentWeight != null
                  ? "${_currentWeight!.toStringAsFixed(1)} kg"
                  : "Add in Stats tab",
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Update your weight in the Stats tab"),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              isReadOnly: true,
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
                        const Text(
                          "Body Mass Index",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
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
                    _getBmiCategory(bmi),
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
                        const Text(
                          "Daily Calories (TDEE)",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
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
                          const Padding(
                            padding: EdgeInsets.only(bottom: 6, left: 4),
                            child: Text(
                              "kcal",
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
                  child: const Text(
                    "Missing data",
                    style: TextStyle(
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
        title: const Text("Edit Name", style: TextStyle(color: Colors.white)),
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
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
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
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _editAge() {
    final controller = TextEditingController(text: _userAge?.toString() ?? "");
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text("Edit Age", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(color: Colors.white),
          cursorColor: const Color(0xFF39FF14),
          decoration: const InputDecoration(
            hintText: "Age in years",
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
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final age = int.tryParse(controller.text);
              if (age != null && age > 0 && age < 150) {
                _saveField('user_age', age);
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF39FF14),
              foregroundColor: Colors.black,
            ),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _editHeight() {
    final controller = TextEditingController(
      text: _userHeightCm?.toStringAsFixed(1) ?? "",
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text("Edit Height", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white),
          cursorColor: const Color(0xFF39FF14),
          decoration: const InputDecoration(
            hintText: "Height in cm",
            hintStyle: TextStyle(color: Colors.grey),
            suffixText: "cm",
            suffixStyle: TextStyle(color: Colors.grey),
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
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final height = double.tryParse(controller.text);
              if (height != null && height > 50 && height < 300) {
                _saveField('user_height_cm', height);
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF39FF14),
              foregroundColor: Colors.black,
            ),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _editGender() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text(
          "Select Gender",
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Male', 'Female'].map((gender) {
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
                      gender == 'Male' ? Icons.male : Icons.female,
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
        title: const Text(
          "Activity Level",
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: activityLevels.entries.map((entry) {
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
