import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/gym_models.dart';
import '../services/database_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

enum ChartRange { oneMonth, threeMonths, all }

class _ProgressScreenState extends State<ProgressScreen> {
  final _db = GymDatabase();
  ChartRange _selectedRange = ChartRange.all;

  @override
  Widget build(BuildContext context) {
    // Get data
    final records = _db.getAllInBodyRecords();

    // Sort oldest first for the chart
    final allChartData = List<InBodyRecord>.from(records)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Filter Data
    final chartData = _filterData(allChartData, _selectedRange);

    // Sort newest first for the list/stats
    final recentRecords = List<InBodyRecord>.from(records)
      ..sort((a, b) => b.date.compareTo(a.date));

    final current = recentRecords.isNotEmpty ? recentRecords.first : null;
    final previous = recentRecords.length > 1 ? recentRecords[1] : null;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "Progress",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF39FF14)),
            onPressed: () => _showAddDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // 1. Stats Row
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: "WEIGHT",
                      value: current?.weight.toString() ?? "--",
                      unit: "kg",
                      change: _calculateChange(
                        current?.weight,
                        previous?.weight,
                      ),
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: "SMM",
                      value: current?.smm.toString() ?? "--",
                      unit: "kg",
                      change: _calculateChange(current?.smm, previous?.smm),
                      color: const Color(0xFF39FF14),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: "PBF",
                      value: current?.pbf.toString() ?? "--",
                      unit: "%",
                      change: _calculateChange(current?.pbf, previous?.pbf),
                      color: Colors.orangeAccent,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // 2. Filter Buttons
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _FilterButton(
                      text: "1M",
                      isSelected: _selectedRange == ChartRange.oneMonth,
                      onTap: () =>
                          setState(() => _selectedRange = ChartRange.oneMonth),
                    ),
                    _FilterButton(
                      text: "3M",
                      isSelected: _selectedRange == ChartRange.threeMonths,
                      onTap: () => setState(
                        () => _selectedRange = ChartRange.threeMonths,
                      ),
                    ),
                    _FilterButton(
                      text: "ALL",
                      isSelected: _selectedRange == ChartRange.all,
                      onTap: () =>
                          setState(() => _selectedRange = ChartRange.all),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 3. Chart Section
              Container(
                height: 300,
                padding: const EdgeInsets.only(right: 16, top: 24, bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: chartData.isEmpty
                    ? const Center(
                        child: Text(
                          "Add data to see chart",
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: FlTitlesData(
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: const AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: false,
                              ), // Clean look, maybe add date labels later
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 10,
                                reservedSize: 30,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    value.toInt().toString(),
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 10,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          minX: 0,
                          maxX: (chartData.length - 1).toDouble(),
                          minY:
                              0, // Start from 0 to see perspective, or autoscaling
                          // Let's settle for auto-range but with some padding
                          lineBarsData: [
                            // Weight
                            LineChartBarData(
                              spots: chartData.asMap().entries.map((e) {
                                return FlSpot(e.key.toDouble(), e.value.weight);
                              }).toList(),
                              isCurved: true,
                              color: Colors.white,
                              barWidth: 2,
                              dotData: const FlDotData(show: false),
                            ),
                            // SMM
                            LineChartBarData(
                              spots: chartData.asMap().entries.map((e) {
                                return FlSpot(e.key.toDouble(), e.value.smm);
                              }).toList(),
                              isCurved: true,
                              color: const Color(0xFF39FF14),
                              barWidth: 2,
                              dotData: const FlDotData(show: false),
                            ),
                            // PBF
                            LineChartBarData(
                              spots: chartData.asMap().entries.map((e) {
                                return FlSpot(e.key.toDouble(), e.value.pbf);
                              }).toList(),
                              isCurved: true,
                              color: Colors.orangeAccent,
                              barWidth: 2,
                              dotData: const FlDotData(show: false),
                            ),
                          ],
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipItems: (touchedSpots) {
                                return touchedSpots.map((spot) {
                                  String label;
                                  if (spot.barIndex == 0)
                                    label = "Weight";
                                  else if (spot.barIndex == 1)
                                    label = "SMM";
                                  else
                                    label = "PBF";

                                  return LineTooltipItem(
                                    "$label: ${spot.y}\n",
                                    const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                }).toList();
                              },
                              tooltipPadding: const EdgeInsets.all(8),
                              // tooltipBgColor: const Color(0xFF2C2C2E), // Deprecated/Removed in newer versions?
                              fitInsideHorizontally: true,
                              fitInsideVertically: true,
                            ),
                          ),
                        ),
                      ),
              ),

              const SizedBox(height: 32),

              // 4. History List Header
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "History",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 5. History List
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentRecords.length,
                itemBuilder: (context, index) {
                  final record = recentRecords[index];
                  // Hive keys are usually dynamic, but often int for auto-increment
                  final key = record.key;

                  return Dismissible(
                    key: ValueKey(key ?? record.date.toString()),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      color: Colors.redAccent,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (direction) async {
                      return await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: const Color(0xFF1C1C1E),
                          title: const Text(
                            "Delete Record?",
                            style: TextStyle(color: Colors.white),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text(
                                "Cancel",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text(
                                "Delete",
                                style: TextStyle(color: Colors.redAccent),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    onDismissed: (direction) {
                      _db.deleteInBodyRecord(key);
                      setState(() {
                        // UI update handled by re-fetching in build, but setState triggers it
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C1E),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('MMM d, yyyy').format(record.date),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF39FF14),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${record.smm} ",
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.orangeAccent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${record.pbf}%",
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                "${record.weight} kg",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 16),
                              InkWell(
                                onTap: () => _showAddDialog(
                                  context,
                                  existingRecord: record,
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<InBodyRecord> _filterData(List<InBodyRecord> allData, ChartRange range) {
    if (allData.isEmpty) return [];
    final now = DateTime.now();
    DateTime cutoff;

    switch (range) {
      case ChartRange.oneMonth:
        cutoff = now.subtract(const Duration(days: 30));
        break;
      case ChartRange.threeMonths:
        cutoff = now.subtract(const Duration(days: 90));
        break;
      case ChartRange.all:
        return allData;
    }

    return allData.where((rec) => rec.date.isAfter(cutoff)).toList();
  }

  double? _calculateChange(double? current, double? previous) {
    if (current == null || previous == null) return null;
    return current - previous;
  }

  void _showAddDialog(BuildContext context, {InBodyRecord? existingRecord}) {
    final weightCtrl = TextEditingController(
      text: existingRecord?.weight.toString(),
    );
    final smmCtrl = TextEditingController(text: existingRecord?.smm.toString());
    final pbfCtrl = TextEditingController(text: existingRecord?.pbf.toString());
    DateTime selectedDate = existingRecord?.date ?? DateTime.now();

    // Ensure we are working with correct context for Futures
    // State variable capture for async

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1C1C1E),
            title: Text(
              existingRecord == null ? "Log InBody" : "Edit InBody",
              style: const TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Date Picker
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: Color(0xFF39FF14),
                              onPrimary: Colors.black,
                              surface: Color(0xFF1E1E1E),
                              onSurface: Colors.white,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setStateDialog(() => selectedDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat('MMM d, yyyy').format(selectedDate),
                          style: const TextStyle(color: Colors.white),
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_drop_down, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildInput(weightCtrl, "Weight (kg)"),
                const SizedBox(height: 12),
                _buildInput(smmCtrl, "SMM (kg)"),
                const SizedBox(height: 12),
                _buildInput(pbfCtrl, "PBF (%)"),
              ],
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
                  final w = double.tryParse(weightCtrl.text);
                  final s = double.tryParse(smmCtrl.text);
                  final p = double.tryParse(pbfCtrl.text);

                  if (w != null && s != null && p != null) {
                    final newRecord = InBodyRecord(
                      date: selectedDate, // Use user selected date
                      weight: w,
                      smm: s,
                      pbf: p,
                    );

                    if (existingRecord != null) {
                      // Update
                      await _db.updateInBodyRecord(
                        existingRecord.key,
                        newRecord,
                      );
                    } else {
                      // Create
                      await _db.addInBodyRecord(newRecord);
                    }

                    if (!context.mounted) return;
                    Navigator.pop(context);
                    setState(() {}); // Refresh parent
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
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFF2C2C2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterButton({
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF39FF14) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final double? change;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.unit,
    this.change,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (value != "--")
                Text(
                  unit,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
            ],
          ),
          if (change != null && change != 0) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  change! < 0 ? Icons.arrow_downward : Icons.arrow_upward,
                  color: change! < 0
                      ? const Color(0xFF39FF14)
                      : Colors.redAccent,
                  size: 12,
                ),
                Text(
                  " ${change!.abs().toStringAsFixed(1)}",
                  style: TextStyle(
                    color: change! < 0
                        ? const Color(0xFF39FF14)
                        : Colors.redAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
