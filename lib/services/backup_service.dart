import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/gym_models.dart';

class BackupService {
  static const int _backupVersion = 1;

  // Singleton
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  /// Creates a JSON backup of all app data and shares it
  Future<bool> createBackup() async {
    try {
      // Get all boxes
      final exerciseBox = Hive.box<Exercise>('exercises');
      final routineBox = Hive.box<Routine>('routines');
      final sessionBox = Hive.box<WorkoutSession>('sessions');
      final inBodyBox = Hive.box<InBodyRecord>('inbody');
      final settingsBox = Hive.box('settings');

      // Build backup data
      final Map<String, dynamic> backupData = {
        'version': _backupVersion,
        'timestamp': DateTime.now().toIso8601String(),
        'appName': 'GymBrain',
        'exercises': exerciseBox.values.map((e) => e.toJson()).toList(),
        'routines': routineBox.values.map((r) => r.toJson()).toList(),
        'sessions': sessionBox.values.map((s) => s.toJson()).toList(),
        'inbody': inBodyBox.values.map((i) => i.toJson()).toList(),
        'settings': _serializeSettings(settingsBox),
      };

      // Convert to JSON
      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);

      // Get temp directory and create file
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      final filePath = '${directory.path}/gym_brain_backup_$timestamp.json';
      final file = File(filePath);
      await file.writeAsString(jsonString);

      // Share the file
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'My Gym Brain Backup',
        subject: 'Gym Brain Backup - $timestamp',
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Restores data from a JSON backup file
  Future<RestoreResult> restoreBackup() async {
    try {
      // Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        return RestoreResult(success: false, message: 'No file selected');
      }

      final filePath = result.files.single.path;
      if (filePath == null) {
        return RestoreResult(success: false, message: 'Invalid file path');
      }

      // Read and parse JSON
      final file = File(filePath);
      final jsonString = await file.readAsString();
      final Map<String, dynamic> backupData = jsonDecode(jsonString);

      // Validate backup structure
      if (!_validateBackup(backupData)) {
        return RestoreResult(
          success: false,
          message: 'Invalid backup file format',
        );
      }

      // Get all boxes
      final exerciseBox = Hive.box<Exercise>('exercises');
      final routineBox = Hive.box<Routine>('routines');
      final sessionBox = Hive.box<WorkoutSession>('sessions');
      final inBodyBox = Hive.box<InBodyRecord>('inbody');
      final settingsBox = Hive.box('settings');

      // Clear all existing data
      await exerciseBox.clear();
      await routineBox.clear();
      await sessionBox.clear();
      await inBodyBox.clear();
      await settingsBox.clear();

      // Restore Exercises
      final exercisesList = backupData['exercises'] as List? ?? [];
      for (final item in exercisesList) {
        final exercise = Exercise.fromJson(item as Map<String, dynamic>);
        await exerciseBox.put(exercise.id, exercise);
      }

      // Restore Routines
      final routinesList = backupData['routines'] as List? ?? [];
      for (final item in routinesList) {
        final routine = Routine.fromJson(item as Map<String, dynamic>);
        await routineBox.put(routine.id, routine);
      }

      // Restore Sessions
      final sessionsList = backupData['sessions'] as List? ?? [];
      for (final item in sessionsList) {
        final session = WorkoutSession.fromJson(item as Map<String, dynamic>);
        await sessionBox.put(session.id, session);
      }

      // Restore InBody Records
      final inBodyList = backupData['inbody'] as List? ?? [];
      for (final item in inBodyList) {
        final record = InBodyRecord.fromJson(item as Map<String, dynamic>);
        await inBodyBox.add(record);
      }

      // Restore Settings
      final settingsMap = backupData['settings'] as Map<String, dynamic>? ?? {};
      for (final entry in settingsMap.entries) {
        await settingsBox.put(entry.key, entry.value);
      }

      final stats =
          'Restored: ${exercisesList.length} exercises, '
          '${routinesList.length} routines, '
          '${sessionsList.length} sessions, '
          '${inBodyList.length} InBody records';

      return RestoreResult(success: true, message: stats);
    } catch (e) {
      return RestoreResult(
        success: false,
        message: 'Restore failed: ${e.toString()}',
      );
    }
  }

  bool _validateBackup(Map<String, dynamic> data) {
    // Check for required keys
    if (!data.containsKey('appName') || data['appName'] != 'GymBrain') {
      // Allow missing appName for flexibility
    }

    // At minimum, we need exercises or routines to be present
    final hasExercises =
        data.containsKey('exercises') && data['exercises'] is List;
    final hasRoutines =
        data.containsKey('routines') && data['routines'] is List;

    return hasExercises || hasRoutines;
  }

  Map<String, dynamic> _serializeSettings(Box settingsBox) {
    final Map<String, dynamic> settings = {};
    for (final key in settingsBox.keys) {
      final value = settingsBox.get(key);
      // Only serialize primitive types
      if (value is String || value is int || value is double || value is bool) {
        settings[key.toString()] = value;
      }
    }
    return settings;
  }
}

class RestoreResult {
  final bool success;
  final String message;

  RestoreResult({required this.success, required this.message});
}
