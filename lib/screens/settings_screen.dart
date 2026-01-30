import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/backup_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _db = GymDatabase();
  final _backupService = BackupService();

  late int _restSeconds;
  late bool _soundEnabled;
  late bool _notificationsEnabled;

  bool _isBackingUp = false;
  bool _isRestoring = false;

  @override
  void initState() {
    super.initState();
    _restSeconds = _db.defaultRestSeconds;
    _soundEnabled = _db.enableSound;
    _notificationsEnabled = _db.enableNotifications;
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return "$seconds sec";
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    if (secs == 0) return "$mins min";
    return "$mins min $secs sec";
  }

  Future<void> _handleBackup() async {
    setState(() => _isBackingUp = true);

    final success = await _backupService.createBackup();

    setState(() => _isBackingUp = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? "✅ Backup created and ready to share!"
                : "❌ Backup failed. Please try again.",
          ),
          backgroundColor: success ? Colors.green : Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _handleRestore() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "Restore Backup?",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        content: Text(
          "This will REPLACE all current data:\n\n"
          "• Exercises\n"
          "• Routines\n"
          "• Workout History\n"
          "• InBody Records\n"
          "• Settings\n\n"
          "This action CANNOT be undone!",
          style: TextStyle(color: Colors.grey[400], height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text("Restore"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isRestoring = true);

    final result = await _backupService.restoreBackup();

    setState(() => _isRestoring = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.success ? "✅ ${result.message}" : "❌ ${result.message}",
          ),
          backgroundColor: result.success ? Colors.green : Colors.redAccent,
          duration: const Duration(seconds: 4),
        ),
      );

      if (result.success) {
        // Navigate to home and clear stack to reflect changes
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "Settings",
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
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TIMER & FEEDBACK SECTION
              const Text(
                "⏱️ Timer & Feedback",
                style: TextStyle(
                  color: Color(0xFF39FF14),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Rest Duration Slider
              Text(
                "Default Rest Timer",
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(_restSeconds),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: const Color(0xFF39FF14),
                  inactiveTrackColor: Colors.grey[800],
                  thumbColor: Colors.white,
                  overlayColor: const Color(0xFF39FF14).withValues(alpha: 0.2),
                  trackHeight: 4,
                ),
                child: Slider(
                  value: _restSeconds.toDouble(),
                  min: 30,
                  max: 300,
                  divisions: (300 - 30) ~/ 15,
                  onChanged: (val) {
                    setState(() {
                      _restSeconds = val.toInt();
                    });
                    _db.setDefaultRestSeconds(_restSeconds);
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Sound Toggle
              SwitchListTile(
                title: const Text(
                  "Timer Sound Effect",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  "Play a beep when the timer ends",
                  style: TextStyle(color: Colors.grey[600]),
                ),
                value: _soundEnabled,
                activeThumbColor: const Color(0xFF39FF14),
                contentPadding: EdgeInsets.zero,
                onChanged: (val) {
                  setState(() => _soundEnabled = val);
                  _db.setEnableSound(val);
                },
              ),

              const SizedBox(height: 12),

              // Notification Toggle
              SwitchListTile(
                title: const Text(
                  "Background Alerts",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  "Send a notification if app is in background",
                  style: TextStyle(color: Colors.grey[600]),
                ),
                value: _notificationsEnabled,
                activeThumbColor: const Color(0xFF39FF14),
                contentPadding: EdgeInsets.zero,
                onChanged: (val) {
                  setState(() => _notificationsEnabled = val);
                  _db.setEnableNotifications(val);
                },
              ),

              const SizedBox(height: 40),
              const Divider(color: Colors.white10),
              const SizedBox(height: 24),

              // DATA MANAGEMENT SECTION
              const Text(
                "💾 Data Management",
                style: TextStyle(
                  color: Color(0xFF39FF14),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Backup your data to keep it safe or transfer to another device.",
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 24),

              // Export Backup Button
              _buildActionButton(
                icon: Icons.upload_file,
                label: "Export Backup",
                description: "Save all data as a JSON file",
                isLoading: _isBackingUp,
                color: const Color(0xFF39FF14),
                onTap: _handleBackup,
              ),

              const SizedBox(height: 16),

              // Restore Backup Button
              _buildActionButton(
                icon: Icons.download,
                label: "Restore Backup",
                description: "Import data from a backup file",
                isLoading: _isRestoring,
                color: Colors.orange,
                onTap: _handleRestore,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required String description,
    required bool isLoading,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    )
                  : Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }
}
