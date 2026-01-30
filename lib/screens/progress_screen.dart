import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/gym_models.dart';
import '../services/database_service.dart';
import '../widgets/metric_toggle.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

enum ChartRange { oneMonth, threeMonths, all }

enum ChartMetric { maxWeight, volume }

enum BodyMetric { weight, smm, pbf }

class _ProgressScreenState extends State<ProgressScreen>
    with SingleTickerProviderStateMixin {
  final _db = GymDatabase();
  ChartRange _selectedRange = ChartRange.all;
  late TabController _tabController;

  // For Exercise Tab
  // For Exercise Tab
  String? _selectedExerciseName;
  List<Map<String, dynamic>> _exerciseHistory = [];
  ChartMetric _selectedMetric = ChartMetric.maxWeight;
  ChartRange _selectedExerciseRange = ChartRange.all;

  // For Body Stats Tab
  BodyMetric? _selectedBodyMetric; // Null means "Show All"

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadHistory(String selectedName) {
    setState(() {
      _selectedExerciseName = selectedName;
      if (selectedName.startsWith("[Routine] ")) {
        // It's a Routine
        final routineName = selectedName.replaceAll("[Routine] ", "");
        _exerciseHistory = _db.getHistoryForRoutine(routineName);
        _selectedMetric = ChartMetric.volume; // Default to Volume for Routines
      } else {
        // It's an Exercise
        _exerciseHistory = _db.getHistoryForExerciseName(selectedName);
      }
    });
  }

  FlGridData _getCyberGrid(double interval) {
    return FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: interval,
      verticalInterval: 1,
      getDrawingHorizontalLine: (value) {
        return const FlLine(
          color: Colors.white12,
          strokeWidth: 1,
          dashArray: [5, 5],
        );
      },
      getDrawingVerticalLine: (value) {
        return const FlLine(color: Colors.white24, strokeWidth: 1);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get data for Body Stats
    final records = _db.getAllInBodyRecords();

    // Sort oldest first for the chart
    final allChartData = List<InBodyRecord>.from(records)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Filter Data
    final chartData = _filterData(allChartData, _selectedRange);

    // Calculate Dynamic Interval for Body Stats
    double maxY = 0;
    double minY = double.infinity;

    if (chartData.isNotEmpty) {
      for (var rec in chartData) {
        if (_selectedBodyMetric == null ||
            _selectedBodyMetric == BodyMetric.weight) {
          if (rec.weight > maxY) maxY = rec.weight;
          if (rec.weight < minY) minY = rec.weight;
        }
        if (_selectedBodyMetric == null ||
            _selectedBodyMetric == BodyMetric.smm) {
          if (rec.smm > maxY) maxY = rec.smm;
          if (rec.smm < minY) minY = rec.smm;
        }
        if (_selectedBodyMetric == null ||
            _selectedBodyMetric == BodyMetric.pbf) {
          if (rec.pbf > maxY) maxY = rec.pbf;
          if (rec.pbf < minY) minY = rec.pbf;
        }
      }
    } else {
      minY = 0;
    }

    // Safety check
    if (minY == double.infinity) minY = 0;

    // Single Views (Zoomed) vs Combined (0-based)
    if (_selectedBodyMetric == null) {
      minY = 0;
    } else {
      // Avoid flat line in zoomed view
      if (maxY == minY) {
        maxY += 2.5;
        minY -= 2.5;
      }
    }

    if (minY < 0) minY = 0;

    double interval = (maxY - minY) / 5;
    if (interval <= 0) interval = 1;

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
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        actions: [
          if (_tabController.index == 0)
            IconButton(
              icon: const Icon(Icons.add, color: Color(0xFF39FF14)),
              onPressed: () => _showAddDialog(context),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF39FF14),
          labelColor: const Color(0xFF39FF14),
          unselectedLabelColor: Colors.grey,
          onTap: (index) => setState(() {}),
          tabs: const [
            Tab(text: "Body Stats"),
            Tab(text: "Exercise Progress"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: BODY STATS (Original Content)
          SingleChildScrollView(
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
                          trendColor: Colors.white, // Neutral for Weight
                          color: Colors.white,
                          isSelected: _selectedBodyMetric == BodyMetric.weight,
                          onTap: () => setState(() {
                            if (_selectedBodyMetric == BodyMetric.weight) {
                              _selectedBodyMetric = null; // Deselect
                            } else {
                              _selectedBodyMetric = BodyMetric.weight;
                            }
                          }),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: "SMM",
                          value: current?.smm.toString() ?? "--",
                          unit: "kg",
                          change: _calculateChange(current?.smm, previous?.smm),
                          // SMM: Increase (Green/Good), Decrease (Red/Bad)
                          trendColor:
                              (_calculateChange(current?.smm, previous?.smm) ??
                                      0) >=
                                  0
                              ? const Color(0xFF39FF14)
                              : Colors.redAccent,
                          color: const Color(0xFF39FF14),
                          isSelected: _selectedBodyMetric == BodyMetric.smm,
                          onTap: () => setState(() {
                            if (_selectedBodyMetric == BodyMetric.smm) {
                              _selectedBodyMetric = null; // Deselect
                            } else {
                              _selectedBodyMetric = BodyMetric.smm;
                            }
                          }),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: "PBF",
                          value: current?.pbf.toString() ?? "--",
                          unit: "%",
                          change: _calculateChange(current?.pbf, previous?.pbf),
                          // PBF: Decrease (Green/Good), Increase (Red/Bad)
                          trendColor:
                              (_calculateChange(current?.pbf, previous?.pbf) ??
                                      0) <=
                                  0
                              ? const Color(0xFF39FF14)
                              : Colors.redAccent,
                          color: Colors.orangeAccent,
                          isSelected: _selectedBodyMetric == BodyMetric.pbf,
                          onTap: () => setState(() {
                            if (_selectedBodyMetric == BodyMetric.pbf) {
                              _selectedBodyMetric = null; // Deselect
                            } else {
                              _selectedBodyMetric = BodyMetric.pbf;
                            }
                          }),
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
                          onTap: () => setState(
                            () => _selectedRange = ChartRange.oneMonth,
                          ),
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
                    padding: const EdgeInsets.only(
                      right: 16,
                      top: 24,
                      bottom: 12,
                    ),
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
                        : Builder(
                            builder: (context) {
                              return LineChart(
                                LineChartData(
                                  gridData: _getCyberGrid(interval),
                                  titlesData: FlTitlesData(
                                    rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 22,
                                        interval: (chartData.length / 4)
                                            .ceilToDouble(),
                                        getTitlesWidget: (value, meta) {
                                          final index = value.toInt();
                                          if (index >= 0 &&
                                              index < chartData.length) {
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                top: 8.0,
                                              ),
                                              child: Text(
                                                DateFormat(
                                                  'MM/dd',
                                                ).format(chartData[index].date),
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            );
                                          }
                                          return const Text('');
                                        },
                                      ),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        interval: interval,
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
                                  minY: minY,
                                  maxY: maxY,
                                  lineBarsData: [
                                    if (_selectedBodyMetric == null ||
                                        _selectedBodyMetric ==
                                            BodyMetric.weight)
                                      LineChartBarData(
                                        spots: chartData.asMap().entries.map((
                                          e,
                                        ) {
                                          return FlSpot(
                                            e.key.toDouble(),
                                            e.value.weight,
                                          );
                                        }).toList(),
                                        isCurved: true,
                                        color: Colors.white,
                                        barWidth: 3,
                                        dotData: const FlDotData(show: true),
                                      ),
                                    if (_selectedBodyMetric == null ||
                                        _selectedBodyMetric == BodyMetric.smm)
                                      LineChartBarData(
                                        spots: chartData.asMap().entries.map((
                                          e,
                                        ) {
                                          return FlSpot(
                                            e.key.toDouble(),
                                            e.value.smm,
                                          );
                                        }).toList(),
                                        isCurved: true,
                                        color: const Color(0xFF39FF14),
                                        barWidth: 3,
                                        dotData: const FlDotData(show: true),
                                      ),
                                    if (_selectedBodyMetric == null ||
                                        _selectedBodyMetric == BodyMetric.pbf)
                                      LineChartBarData(
                                        spots: chartData.asMap().entries.map((
                                          e,
                                        ) {
                                          return FlSpot(
                                            e.key.toDouble(),
                                            e.value.pbf,
                                          );
                                        }).toList(),
                                        isCurved: true,
                                        color: Colors.orangeAccent,
                                        barWidth: 3,
                                        dotData: const FlDotData(show: true),
                                      ),
                                  ],
                                  lineTouchData: LineTouchData(
                                    touchTooltipData: LineTouchTooltipData(
                                      getTooltipItems: (touchedSpots) {
                                        return touchedSpots.map((spot) {
                                          final val = spot.y;
                                          final metricName = spot.barIndex == 0
                                              ? "Weight"
                                              : spot.barIndex == 1
                                              ? "SMM"
                                              : "PBF";

                                          // Find date from index (x)
                                          final dateIndex = spot.x.toInt();
                                          String dateStr = "";
                                          if (dateIndex >= 0 &&
                                              dateIndex < chartData.length) {
                                            dateStr = DateFormat(
                                              'MM/dd',
                                            ).format(chartData[dateIndex].date);
                                          }

                                          return LineTooltipItem(
                                            "$metricName: $val\n$dateStr",
                                            const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          );
                                        }).toList();
                                      },
                                      tooltipPadding: const EdgeInsets.all(8),
                                      fitInsideHorizontally: true,
                                      fitInsideVertically: true,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  // Legend for Body Stats
                  const SizedBox(height: 16),
                  if (_selectedBodyMetric == null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _LegendItem(color: Colors.white, text: "Weight"),
                        const SizedBox(width: 16),
                        _LegendItem(
                          color: const Color(0xFF39FF14),
                          text: "SMM",
                        ),
                        const SizedBox(width: 16),
                        _LegendItem(color: Colors.orangeAccent, text: "PBF"),
                      ],
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
                                  onPressed: () =>
                                      Navigator.pop(context, false),
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
                                    DateFormat(
                                      'MMM d, yyyy',
                                    ).format(record.date),
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
                                        "${record.smm} (SMM)",
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
                                        "${record.pbf}% (PBF)",
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
                                    "${record.weight} kg (Weight)",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
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

          // TAB 2: EXERCISE PROGRESS
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedExerciseName,
                      hint: const Text(
                        "Select Exercise or Routine",
                        style: TextStyle(color: Colors.grey),
                      ),
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1C1C1E),
                      style: const TextStyle(color: Colors.white),
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Color(0xFF39FF14),
                      ),
                      items: [
                        ..._db.getRoutineNamesFromHistory().map((name) {
                          return DropdownMenuItem(
                            value: "[Routine] $name",
                            child: Text(
                              "[Routine] $name",
                              style: const TextStyle(color: Colors.cyanAccent),
                            ),
                          );
                        }),
                        ..._db.getExerciseNamesFromHistory().map((name) {
                          return DropdownMenuItem(
                            value: name,
                            child: Text(name),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        if (val != null) _loadHistory(val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                if (_selectedExerciseName != null &&
                    _exerciseHistory.isNotEmpty)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Trend",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (!(_selectedExerciseName?.startsWith(
                                  "[Routine]",
                                ) ??
                                false))
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2C2C2E),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.all(2),
                                child: Row(
                                  children: [
                                    MetricToggle(
                                      text: "Max Weight",
                                      isSelected:
                                          _selectedMetric ==
                                          ChartMetric.maxWeight,
                                      onTap: () => setState(
                                        () => _selectedMetric =
                                            ChartMetric.maxWeight,
                                      ),
                                    ),
                                    MetricToggle(
                                      text: "Volume",
                                      isSelected:
                                          _selectedMetric == ChartMetric.volume,
                                      onTap: () => setState(
                                        () => _selectedMetric =
                                            ChartMetric.volume,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
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
                                isSelected:
                                    _selectedExerciseRange ==
                                    ChartRange.oneMonth,
                                onTap: () => setState(
                                  () => _selectedExerciseRange =
                                      ChartRange.oneMonth,
                                ),
                              ),
                              _FilterButton(
                                text: "3M",
                                isSelected:
                                    _selectedExerciseRange ==
                                    ChartRange.threeMonths,
                                onTap: () => setState(
                                  () => _selectedExerciseRange =
                                      ChartRange.threeMonths,
                                ),
                              ),
                              _FilterButton(
                                text: "ALL",
                                isSelected:
                                    _selectedExerciseRange == ChartRange.all,
                                onTap: () => setState(
                                  () => _selectedExerciseRange = ChartRange.all,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          height: 300,
                          padding: const EdgeInsets.only(
                            right: 16,
                            top: 24,
                            bottom: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1C1E),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Builder(
                            builder: (context) {
                              final filteredHistory = _filterExerciseHistory(
                                _exerciseHistory,
                                _selectedExerciseRange,
                              );
                              double maxVal = 0;
                              double minVal = double.infinity;

                              if (filteredHistory.isNotEmpty) {
                                for (var h in filteredHistory) {
                                  double val =
                                      _selectedMetric == ChartMetric.maxWeight
                                      ? h['weight']
                                      : h['volume'];
                                  if (val > maxVal) maxVal = val;
                                  if (val < minVal) minVal = val;
                                }
                              } else {
                                minVal = 0;
                              }

                              if (maxVal == minVal) {
                                maxVal += 5;
                                minVal -= 5;
                                if (minVal < 0) minVal = 0;
                              }

                              double exInterval = (maxVal - minVal) / 5;
                              if (exInterval <= 0) exInterval = 1;

                              return LineChart(
                                LineChartData(
                                  gridData: _getCyberGrid(exInterval),
                                  titlesData: FlTitlesData(
                                    rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 22,
                                        interval: (filteredHistory.length / 4)
                                            .ceilToDouble(),
                                        getTitlesWidget: (value, meta) {
                                          final index = value.toInt();
                                          if (index >= 0 &&
                                              index < filteredHistory.length) {
                                            final date =
                                                filteredHistory[index]['date']
                                                    as DateTime;
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                top: 8.0,
                                              ),
                                              child: Text(
                                                DateFormat(
                                                  'MM/dd',
                                                ).format(date),
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            );
                                          }
                                          return const Text('');
                                        },
                                      ),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        interval: exInterval,
                                        reservedSize: 30,
                                        getTitlesWidget: (value, meta) {
                                          return Text(
                                            _compactNumber(value),
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
                                  maxX: (filteredHistory.length - 1).toDouble(),
                                  minY: minVal,
                                  maxY: maxVal,
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: filteredHistory
                                          .asMap()
                                          .entries
                                          .map((e) {
                                            final val =
                                                _selectedMetric ==
                                                    ChartMetric.maxWeight
                                                ? e.value['weight']
                                                : e.value['volume'];
                                            return FlSpot(
                                              e.key.toDouble(),
                                              val,
                                            );
                                          })
                                          .toList(),
                                      isCurved: true,
                                      color:
                                          _selectedMetric ==
                                              ChartMetric.maxWeight
                                          ? const Color(0xFF39FF14)
                                          : Colors.cyanAccent,
                                      barWidth: 3,
                                      dotData: const FlDotData(show: true),
                                    ),
                                  ],
                                  lineTouchData: LineTouchData(
                                    touchTooltipData: LineTouchTooltipData(
                                      tooltipPadding: const EdgeInsets.all(8),
                                      getTooltipItems: (spots) {
                                        return spots.map((spot) {
                                          final h =
                                              filteredHistory[spot.x.toInt()];
                                          final date = h['date'] as DateTime;
                                          final dateStr = DateFormat(
                                            'MM/dd',
                                          ).format(date);
                                          final unit =
                                              _selectedMetric ==
                                                  ChartMetric.maxWeight
                                              ? "kg"
                                              : "vol";
                                          return LineTooltipItem(
                                            "${spot.y.toStringAsFixed(1)} $unit\n$dateStr",
                                            const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          );
                                        }).toList();
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _selectedMetric == ChartMetric.maxWeight
                                    ? const Color(0xFF39FF14)
                                    : Colors.cyanAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _selectedMetric == ChartMetric.maxWeight
                                  ? "Max Weight"
                                  : "Volume",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                else if (_selectedExerciseName != null)
                  const Expanded(
                    child: Center(
                      child: Text(
                        "No history for this exercise yet.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  const Expanded(
                    child: Center(
                      child: Text(
                        "Select an exercise above to see progress.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
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

  List<Map<String, dynamic>> _filterExerciseHistory(
    List<Map<String, dynamic>> history,
    ChartRange range,
  ) {
    if (history.isEmpty) return [];
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
        return history;
    }
    return history.where((h) {
      final date = h['date'] as DateTime;
      return date.isAfter(cutoff);
    }).toList();
  }

  void _showAddDialog(BuildContext context, {InBodyRecord? existingRecord}) {
    final weightCtrl = TextEditingController(
      text: existingRecord?.weight.toString(),
    );
    final smmCtrl = TextEditingController(text: existingRecord?.smm.toString());
    final pbfCtrl = TextEditingController(text: existingRecord?.pbf.toString());
    DateTime selectedDate = existingRecord?.date ?? DateTime.now();

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
                      date: selectedDate,
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

  String _compactNumber(double value) {
    if (value >= 1000) {
      return "${(value / 1000).toStringAsFixed(1)}k";
    }
    return value.toInt().toString();
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
  final Color? trendColor; // NEW: Custom trend color
  final bool isSelected;
  final VoidCallback? onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.unit,
    this.change,
    this.color = Colors.white,
    this.trendColor,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Determine effective trend color
    final effectiveTrendColor =
        trendColor ??
        ((change != null && change! < 0)
            ? const Color(0xFF39FF14) // Default fallback (Green for down)
            : Colors.redAccent);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
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
                    color: effectiveTrendColor,
                    size: 12,
                  ),
                  Text(
                    " ${change!.abs().toStringAsFixed(1)}",
                    style: TextStyle(
                      color: effectiveTrendColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;

  const _LegendItem({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
