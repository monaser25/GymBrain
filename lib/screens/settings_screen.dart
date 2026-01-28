import 'package:flutter/material.dart';
import '../services/database_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _db = GymDatabase();

  late int _restSeconds;
  late bool _soundEnabled;
  late bool _notificationsEnabled;

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
                  overlayColor: const Color(0xFF39FF14).withOpacity(0.2),
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
                activeColor: const Color(0xFF39FF14),
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
                activeColor: const Color(0xFF39FF14),
                contentPadding: EdgeInsets.zero,
                onChanged: (val) {
                  setState(() => _notificationsEnabled = val);
                  _db.setEnableNotifications(val);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
