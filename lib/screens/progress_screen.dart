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

class _ProgressScreenState extends State<ProgressScreen> {
  final _db = GymDatabase();

  @override
  Widget build(BuildContext context) {
    // Get data
    final records = _db.getAllInBodyRecords();
    // Sort oldest first for the chart
    final chartData = List<InBodyRecord>.from(records)
      ..sort((a, b) => a.date.compareTo(b.date));

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
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: "SMM",
                      value: current?.smm.toString() ?? "--",
                      unit: "kg",
                      change: _calculateChange(current?.smm, previous?.smm),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: "PBF",
                      value: current?.pbf.toString() ?? "--",
                      unit: "%",
                      change: _calculateChange(current?.pbf, previous?.pbf),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // 2. Chart Section
              Container(
                height: 300,
                padding: const EdgeInsets.only(right: 16, top: 10),
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
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ), // Clean look
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 5,
                                reservedSize: 40,
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
                              (chartData
                                          .map((e) => e.weight)
                                          .reduce((a, b) => a < b ? a : b) -
                                      5)
                                  .toDouble(),
                          maxY:
                              (chartData
                                          .map((e) => e.weight)
                                          .reduce((a, b) => a > b ? a : b) +
                                      5)
                                  .toDouble(),
                          lineBarsData: [
                            LineChartBarData(
                              spots: chartData.asMap().entries.map((e) {
                                return FlSpot(e.key.toDouble(), e.value.weight);
                              }).toList(),
                              isCurved: true,
                              color: const Color(0xFF39FF14),
                              barWidth: 3,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    const Color(
                                      0xFF39FF14,
                                    ).withValues(alpha: 0.2),
                                    const Color(
                                      0xFF39FF14,
                                    ).withValues(alpha: 0.0),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),

              const SizedBox(height: 32),

              // 3. History List Header
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

              // 4. History List
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentRecords.length,
                itemBuilder: (context, index) {
                  final record = recentRecords[index];
                  return Container(
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
                            Text(
                              "SMM: ${record.smm}  PBF: ${record.pbf}%",
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          "${record.weight} kg",
                          style: const TextStyle(
                            color: Color(0xFF39FF14),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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

  double? _calculateChange(double? current, double? previous) {
    if (current == null || previous == null) return null;
    return current - previous;
  }

  void _showAddDialog(BuildContext context) {
    final weightCtrl = TextEditingController();
    final smmCtrl = TextEditingController();
    final pbfCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text("Log InBody", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final w = double.tryParse(weightCtrl.text);
              final s = double.tryParse(smmCtrl.text);
              final p = double.tryParse(pbfCtrl.text);

              if (w != null && s != null && p != null) {
                final record = InBodyRecord(
                  date: DateTime.now(),
                  weight: w,
                  smm: s,
                  pbf: p,
                );
                await _db.addInBodyRecord(record);
                if (!context.mounted) return;
                Navigator.pop(context);
                setState(() {});
              }
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

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final double? change;

  const _StatCard({
    required this.label,
    required this.value,
    required this.unit,
    this.change,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
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
