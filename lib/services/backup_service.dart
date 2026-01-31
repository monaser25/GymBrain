import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../models/gym_models.dart';

class BackupService {
  static const int _backupVersion = 1;

  // Singleton
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  /// Creates a JSON backup of all app data and shares it
  /// Uses Uint8List bytes for universal Mobile/Web compatibility
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

      // 1. Generate JSON String (pretty printed)
      final String jsonString = const JsonEncoder.withIndent(
        '  ',
      ).convert(backupData);

      // 2. Convert to Bytes (Uint8List) - Universal approach
      final Uint8List bytes = Uint8List.fromList(utf8.encode(jsonString));

      // 3. Generate filename with timestamp
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      final fileName = 'gym_brain_backup_$timestamp.json';

      // 4. Create XFile directly from bytes (Works on Web & Mobile)
      final xFile = XFile.fromData(
        bytes,
        mimeType: 'application/json',
        name: fileName,
        lastModified: DateTime.now(),
      );

      // 5. Share - On Web triggers download, on Mobile opens Share Sheet
      await Share.shareXFiles(
        [xFile],
        text: 'My Gym Brain Backup',
        subject: 'Gym Brain Backup - $timestamp',
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Restores data from a JSON backup file
  /// Uses bytes for universal Mobile/Web compatibility
  Future<RestoreResult> restoreBackup() async {
    try {
      // Pick file - withData: true ensures we get bytes on all platforms
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true, // Critical for Web support
      );

      if (result == null || result.files.isEmpty) {
        return RestoreResult(success: false, message: 'No file selected');
      }

      final fileBytes = result.files.single.bytes;
      if (fileBytes == null) {
        return RestoreResult(
          success: false,
          message: 'Could not read file data',
        );
      }

      // Decode bytes to JSON string
      final jsonString = utf8.decode(fileBytes);
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
