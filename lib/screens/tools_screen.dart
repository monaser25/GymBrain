import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';

class ToolsScreen extends StatefulWidget {
  final int initialTab;

  const ToolsScreen({super.key, this.initialTab = 0});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 1RM Calculator State
  final _weightController = TextEditingController();
  final _repsController = TextEditingController();
  double? _oneRepMax;
  String _inputUnit = 'kg'; // Track input unit (kg/lb)

  // Smart 1RM History State
  String? _selectedExercise;
  String? _historyDateLabel;
  List<String> _exerciseNames = [];

  // Plate Calculator State
  final _targetWeightController = TextEditingController();
  double _barWeight = 20.0;
  List<Map<String, dynamic>> _platesPerSide = [];
  String? _plateError;

  // Unit System State (Metric = true, Imperial = false)
  bool _isMetric = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _loadExerciseNames();
  }

  void _loadExerciseNames() {
    final db = GymDatabase();
    setState(() {
      _exerciseNames = db.getExerciseNamesFromHistory();
    });
  }

  // Find the best 1RM for a given exercise from history
  void _onExerciseSelected(String exerciseName) {
    final db = GymDatabase();
    final sessions = db.getSessions();

    double maxOneRm = 0;
    double bestWeight = 0;
    String bestUnit = 'kg';
    int bestReps = 0;
    DateTime? bestDate;

    for (final session in sessions) {
      for (final set in session.sets) {
        if (set.exerciseName == exerciseName) {
          // Calculate 1RM using Epley formula
          // Normalize to kg for comparison
          double weightInKg = set.unit == 'lb'
              ? set.weight * 0.453592
              : set.weight;
          double oneRm = weightInKg * (1 + set.reps / 30);

          if (oneRm > maxOneRm) {
            maxOneRm = oneRm;
            bestWeight = set.weight;
            bestReps = set.reps;
            bestUnit = set.unit; // Capture unit
            bestDate = session.date;
          }
        }
      }
    }

    if (bestDate != null) {
      setState(() {
        _selectedExercise = exerciseName;
        _inputUnit = bestUnit; // Set unit
        _weightController.text = _formatWeight(bestWeight);
        _repsController.text = bestReps.toString();
        _historyDateLabel = DateFormat('dd MMM yyyy').format(bestDate!);
        _oneRepMax = null; // Reset result until user clicks calculate
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _weightController.dispose();
    _repsController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  // Epley Formula: 1RM = Weight * (1 + Reps / 30)
  void _calculateOneRepMax() {
    final weight = double.tryParse(_weightController.text);
    final reps = int.tryParse(_repsController.text);

    if (weight != null && weight > 0 && reps != null && reps > 0) {
      setState(() {
        _oneRepMax = weight * (1 + reps / 30);
      });
    }
  }

  // Get unit string based on current system
  String get _unitLabel => _isMetric ? 'kg' : 'lb';

  // Get bar weight options based on unit system
  List<Map<String, dynamic>> get _barWeightOptions {
    if (_isMetric) {
      return [
        {'value': 20.0, 'label': '20 kg (Olympic Standard)'},
        {'value': 15.0, 'label': '15 kg (Women\'s Olympic)'},
        {'value': 10.0, 'label': '10 kg (Training Bar)'},
      ];
    } else {
      return [
        {'value': 45.0, 'label': '45 lb (Standard)'},
        {'value': 35.0, 'label': '35 lb (Women\'s)'},
        {'value': 15.0, 'label': '15 lb (Training Bar)'},
      ];
    }
  }

  // Get available plates based on unit system (from database settings)
  List<double> get _availablePlates {
    final db = GymDatabase();
    if (_isMetric) {
      return db.availablePlatesKg;
    } else {
      return db.availablePlatesLb;
    }
  }

  // Plate Calculator Logic
  void _calculatePlates() {
    final targetWeight = double.tryParse(_targetWeightController.text);

    if (targetWeight == null || targetWeight <= _barWeight) {
      setState(() {
        _plateError =
            "Target must be greater than bar weight (${_formatWeight(_barWeight)} $_unitLabel)";
        _platesPerSide = [];
      });
      return;
    }

    // Calculate weight needed per side
    double remainingPerSide = (targetWeight - _barWeight) / 2;

    // Available plates (largest to smallest)
    final availablePlates = _availablePlates;
    final List<Map<String, dynamic>> result = [];

    for (final plate in availablePlates) {
      int count = (remainingPerSide / plate).floor();
      if (count > 0) {
        result.add({'weight': plate, 'count': count});
        remainingPerSide -= count * plate;
      }
    }

    // Check if we have exact match
    if (remainingPerSide > 0.01) {
      // Small tolerance for floating point
      setState(() {
        _plateError =
            "Cannot make exact weight with available plates. ${remainingPerSide.toStringAsFixed(2)} $_unitLabel remaining.";
        _platesPerSide = result;
      });
    } else {
      setState(() {
        _plateError = null;
        _platesPerSide = result;
      });
    }
  }

  // Switch unit system and reset bar weight to default for that system
  void _switchUnitSystem(bool isMetric) {
    setState(() {
      _isMetric = isMetric;
      _barWeight = isMetric ? 20.0 : 45.0; // Default bar for each system
      _platesPerSide = [];
      _plateError = null;
      _targetWeightController.clear();
    });
  }

  String _formatWeight(double weight) {
    return weight == weight.roundToDouble()
        ? weight.toInt().toString()
        : weight.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  }

  // Show dialog to customize available plates
  void _showPlateInventoryDialog() {
    final db = GymDatabase();

    // Get default and current plates
    final allPlatesKg = GymDatabase.defaultPlatesKg;
    final allPlatesLb = GymDatabase.defaultPlatesLb;

    // Create a copy of current selection
    Set<double> selectedKg = Set.from(db.availablePlatesKg);
    Set<double> selectedLb = Set.from(db.availablePlatesLb);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1C1C1E),
              title: const Row(
                children: [
                  Icon(Icons.tune, color: Color(0xFF39FF14), size: 24),
                  SizedBox(width: 12),
                  Text(
                    "Plate Inventory",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Uncheck plates you don't have at your gym.",
                        style: TextStyle(color: Colors.grey[400], fontSize: 13),
                      ),
                      const SizedBox(height: 20),

                      // Metric Plates Section
                      const Text(
                        "METRIC (KG)",
                        style: TextStyle(
                          color: Color(0xFF39FF14),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: allPlatesKg.map((plate) {
                          final isSelected = selectedKg.contains(plate);
                          return FilterChip(
                            label: Text(
                              "${_formatWeight(plate)} kg",
                              style: TextStyle(
                                color: isSelected ? Colors.black : Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              setDialogState(() {
                                if (selected) {
                                  selectedKg.add(plate);
                                } else {
                                  selectedKg.remove(plate);
                                }
                              });
                            },
                            selectedColor: const Color(0xFF39FF14),
                            backgroundColor: const Color(0xFF2C2C2E),
                            checkmarkColor: Colors.black,
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 24),

                      // Imperial Plates Section
                      const Text(
                        "IMPERIAL (LB)",
                        style: TextStyle(
                          color: Color(0xFF39FF14),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: allPlatesLb.map((plate) {
                          final isSelected = selectedLb.contains(plate);
                          return FilterChip(
                            label: Text(
                              "${_formatWeight(plate)} lb",
                              style: TextStyle(
                                color: isSelected ? Colors.black : Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              setDialogState(() {
                                if (selected) {
                                  selectedLb.add(plate);
                                } else {
                                  selectedLb.remove(plate);
                                }
                              });
                            },
                            selectedColor: const Color(0xFF39FF14),
                            backgroundColor: const Color(0xFF2C2C2E),
                            checkmarkColor: Colors.black,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Save the selections (sorted largest to smallest)
                    final sortedKg = selectedKg.toList()
                      ..sort((a, b) => b.compareTo(a));
                    final sortedLb = selectedLb.toList()
                      ..sort((a, b) => b.compareTo(a));

                    await db.setAvailablePlatesKg(sortedKg);
                    await db.setAvailablePlatesLb(sortedLb);

                    if (context.mounted) {
                      Navigator.pop(context);
                      // Clear current calculation to force recalculation with new plates
                      setState(() {
                        _platesPerSide = [];
                        _plateError = null;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Plate inventory updated!"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF39FF14),
                    foregroundColor: Colors.black,
                  ),
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Gym Tools",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF39FF14),
          indicatorWeight: 3,
          labelColor: const Color(0xFF39FF14),
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.calculate_outlined), text: "1RM Calculator"),
            Tab(
              icon: Icon(Icons.donut_large_outlined),
              text: "Plate Calculator",
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildOneRepMaxTab(), _buildPlateCalculatorTab()],
      ),
    );
  }

  // ============================================
  // TAB 1: 1RM CALCULATOR
  // ============================================
  Widget _buildOneRepMaxTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF39FF14).withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.fitness_center,
                  color: Color(0xFF39FF14),
                  size: 40,
                ),
                const SizedBox(height: 12),
                const Text(
                  "One Rep Max Calculator",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Calculate your estimated 1RM using the Epley formula",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Smart 1RM: Select from History Dropdown
          if (_exerciseNames.isNotEmpty) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "SELECT FROM HISTORY",
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2E),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedExercise != null
                                ? const Color(0xFF39FF14).withValues(alpha: 0.5)
                                : Colors.transparent,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedExercise,
                            isExpanded: true,
                            hint: Text(
                              "Choose an exercise...",
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                            dropdownColor: const Color(0xFF2C2C2E),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            icon: const Icon(
                              Icons.history,
                              color: Color(0xFF39FF14),
                            ),
                            items: _exerciseNames.map((name) {
                              return DropdownMenuItem(
                                value: name,
                                child: Text(name),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                _onExerciseSelected(value);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    if (_selectedExercise != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _selectedExercise = null;
                            _weightController.clear();
                            _repsController.clear();
                            _inputUnit = 'kg'; // Reset to default
                            _oneRepMax = null;
                            _historyDateLabel = null;
                          });
                        },
                        icon: const Icon(Icons.close, color: Colors.grey),
                        tooltip: "Clear History",
                      ),
                    ],
                  ],
                ),
                // History Date Label
                if (_historyDateLabel != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF39FF14).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          color: Color(0xFF39FF14),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Based on your lift on $_historyDateLabel",
                          style: const TextStyle(
                            color: Color(0xFF39FF14),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
          ],

          // Input Fields
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  controller: _weightController,
                  label: "LIFTED WEIGHT",
                  hint: "0",
                  suffix: _inputUnit,
                  onSuffixTap: () {
                    setState(() {
                      _inputUnit = _inputUnit == 'kg' ? 'lb' : 'kg';
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInputField(
                  controller: _repsController,
                  label: "REPS PERFORMED",
                  hint: "0",
                  suffix: "reps",
                  isInteger: true,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Calculate Button
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _calculateOneRepMax,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF39FF14),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                "CALCULATE 1RM",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Result Card
          if (_oneRepMax != null) ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF39FF14).withValues(alpha: 0.15),
                    const Color(0xFF1C1C1E),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF39FF14).withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    "ESTIMATED 1RM",
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatWeight(_oneRepMax!),
                        style: const TextStyle(
                          color: Color(0xFF39FF14),
                          fontSize: 56,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          " $_inputUnit",
                          style: const TextStyle(
                            color: Color(0xFF39FF14),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Percentage Table
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildPercentageRow(
                    "100%",
                    "Max Effort",
                    _oneRepMax!,
                    Colors.redAccent,
                  ),
                  _buildDivider(),
                  _buildPercentageRow(
                    "95%",
                    "Near Max",
                    _oneRepMax! * 0.95,
                    Colors.orange,
                  ),
                  _buildDivider(),
                  _buildPercentageRow(
                    "90%",
                    "Heavy",
                    _oneRepMax! * 0.90,
                    Colors.orangeAccent,
                  ),
                  _buildDivider(),
                  _buildPercentageRow(
                    "80%",
                    "Hypertrophy",
                    _oneRepMax! * 0.80,
                    const Color(0xFF39FF14),
                  ),
                  _buildDivider(),
                  _buildPercentageRow(
                    "70%",
                    "Strength-Endurance",
                    _oneRepMax! * 0.70,
                    Colors.cyanAccent,
                  ),
                  _buildDivider(),
                  _buildPercentageRow(
                    "50%",
                    "Warm-up",
                    _oneRepMax! * 0.50,
                    Colors.grey,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPercentageRow(
    String percentage,
    String label,
    double weight,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 50,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              percentage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          ),
          Text(
            "${_formatWeight(weight)} kg",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.grey[800],
      height: 1,
      indent: 20,
      endIndent: 20,
    );
  }

  // ============================================
  // TAB 2: PLATE CALCULATOR
  // ============================================
  Widget _buildPlateCalculatorTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with Settings Button
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF39FF14).withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.donut_large,
                      color: Color(0xFF39FF14),
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Plate Calculator",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Find out which plates to load on each side",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),
                  ],
                ),
              ),
              // Settings Icon (top-right corner)
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(
                    Icons.tune,
                    color: Color(0xFF39FF14),
                    size: 24,
                  ),
                  tooltip: "Plate Inventory",
                  onPressed: _showPlateInventoryDialog,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Unit System Toggle (Metric/Imperial)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "UNIT SYSTEM",
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _switchUnitSystem(true),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _isMetric
                                ? const Color(0xFF39FF14)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.straighten,
                                size: 18,
                                color: _isMetric ? Colors.black : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "METRIC (KG)",
                                style: TextStyle(
                                  color: _isMetric ? Colors.black : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _switchUnitSystem(false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: !_isMetric
                                ? const Color(0xFF39FF14)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.balance,
                                size: 18,
                                color: !_isMetric ? Colors.black : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "IMPERIAL (LB)",
                                style: TextStyle(
                                  color: !_isMetric
                                      ? Colors.black
                                      : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Target Weight Input
          _buildInputField(
            controller: _targetWeightController,
            label: "TARGET WEIGHT",
            hint: _isMetric ? "100" : "225",
            suffix: _unitLabel,
          ),

          const SizedBox(height: 16),

          // Bar Weight Dropdown (Dynamic based on unit system)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "BAR WEIGHT",
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<double>(
                    value: _barWeight,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF2C2C2E),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: Color(0xFF39FF14),
                    ),
                    items: _barWeightOptions.map((option) {
                      return DropdownMenuItem<double>(
                        value: option['value'] as double,
                        child: Text(option['label'] as String),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _barWeight = value);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Calculate Button
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _calculatePlates,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF39FF14),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                "CALCULATE PLATES",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Error Message
          if (_plateError != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _plateError!,
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Result
          if (_platesPerSide.isNotEmpty) ...[
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF39FF14).withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFF39FF14),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "LOAD PER SIDE",
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Visual Plate Representation
                  _buildPlateVisualization(),

                  const SizedBox(height: 20),
                  Divider(color: Colors.grey[800]),
                  const SizedBox(height: 16),

                  // Plate List
                  ...List.generate(_platesPerSide.length, (index) {
                    final plate = _platesPerSide[index];
                    final weight = plate['weight'] as double;
                    final count = plate['count'] as int;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _getPlateColor(
                                weight,
                              ).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _getPlateColor(weight),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                "${count}x",
                                style: TextStyle(
                                  color: _getPlateColor(weight),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            "${_formatWeight(weight)} $_unitLabel plate${count > 1 ? 's' : ''}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlateVisualization() {
    // Generate a list of individual plates for visualization
    final List<double> individualPlates = [];
    for (final plate in _platesPerSide) {
      final weight = plate['weight'] as double;
      final count = plate['count'] as int;
      for (int i = 0; i < count; i++) {
        individualPlates.add(weight);
      }
    }

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Bar end (left)
          Container(
            width: 8,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Bar
          Container(width: 30, height: 14, color: Colors.grey[700]),
          // Plates (largest to smallest, left to right)
          ...individualPlates.map((weight) {
            return Container(
              width: 12,
              height: _getPlateHeight(weight),
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: _getPlateColor(weight),
                borderRadius: BorderRadius.circular(2),
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
            );
          }),
          // Bar middle
          Expanded(child: Container(height: 14, color: Colors.grey[700])),
          // Mirror plates (smallest to largest)
          ...individualPlates.reversed.map((weight) {
            return Container(
              width: 12,
              height: _getPlateHeight(weight),
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: _getPlateColor(weight),
                borderRadius: BorderRadius.circular(2),
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
            );
          }),
          // Bar
          Container(width: 30, height: 14, color: Colors.grey[700]),
          // Bar end (right)
          Container(
            width: 8,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  double _getPlateHeight(double weight) {
    if (_isMetric) {
      // Metric plates (kg)
      switch (weight) {
        case 25.0:
          return 70;
        case 20.0:
          return 65;
        case 15.0:
          return 55;
        case 10.0:
          return 50;
        case 5.0:
          return 42;
        case 2.5:
          return 35;
        case 1.25:
          return 28;
        default:
          return 40;
      }
    } else {
      // Imperial plates (lb)
      switch (weight) {
        case 45.0:
          return 70;
        case 35.0:
          return 62;
        case 25.0:
          return 55;
        case 10.0:
          return 45;
        case 5.0:
          return 38;
        case 2.5:
          return 30;
        default:
          return 40;
      }
    }
  }

  Color _getPlateColor(double weight) {
    if (_isMetric) {
      // Olympic color coding (kg)
      switch (weight) {
        case 25.0:
          return Colors.red;
        case 20.0:
          return Colors.blue;
        case 15.0:
          return Colors.yellow;
        case 10.0:
          return Colors.green;
        case 5.0:
          return Colors.white;
        case 2.5:
          return Colors.red[300]!;
        case 1.25:
          return Colors.grey[400]!;
        default:
          return Colors.grey;
      }
    } else {
      // Standard gym plate colors (lb)
      switch (weight) {
        case 45.0:
          return Colors.blue;
        case 35.0:
          return Colors.yellow;
        case 25.0:
          return Colors.green;
        case 10.0:
          return Colors.white;
        case 5.0:
          return Colors.red[300]!;
        case 2.5:
          return Colors.grey[400]!;
        default:
          return Colors.grey;
      }
    }
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String suffix,
    VoidCallback? onSuffixTap,
    bool isInteger = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: isInteger
                      ? TextInputType.number
                      : const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onSuffixTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(6),
                    border: onSuffixTap != null
                        ? Border.all(
                            color: const Color(
                              0xFF39FF14,
                            ).withValues(alpha: 0.3),
                          )
                        : null,
                  ),
                  child: Text(
                    suffix,
                    style: TextStyle(
                      color: const Color(0xFF39FF14),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      decoration: onSuffixTap != null
                          ? TextDecoration.underline
                          : TextDecoration.none,
                      decorationColor: const Color(0xFF39FF14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
