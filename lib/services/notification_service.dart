import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
          macOS: initializationSettingsDarwin,
        );

    // Using 'settings' instead of 'initializationSettings' based on specific error feedback.
    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Handle notification tap
      },
    );

    final androidImplementation = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();

      // Channel 1: Sound Enabled
      const AndroidNotificationChannel soundChannel =
          AndroidNotificationChannel(
            'gym_brain_sound', // ID
            'Timer (Sound)', // Name
            description: 'Workout timer notifications with sound',
            importance: Importance.max,
            playSound: true,
          );

      // Channel 2: Silent (Vibrate Only)
      const AndroidNotificationChannel silentChannel =
          AndroidNotificationChannel(
            'gym_brain_silent', // ID
            'Timer (Silent)', // Name
            description: 'Silent workout timer notifications',
            importance: Importance.high,
            playSound: false,
            enableVibration: true,
          );

      await androidImplementation.createNotificationChannel(soundChannel);
      await androidImplementation.createNotificationChannel(silentChannel);
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required int seconds,
    required bool playSound, // New Parameter
  }) async {
    final String channelId = playSound ? 'gym_brain_sound' : 'gym_brain_silent';

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.now(
        tz.local,
      ).add(Duration(seconds: seconds)),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          playSound ? 'Timer (Sound)' : 'Timer (Silent)',
          channelDescription: 'Workout timer notifications',
          importance: playSound ? Importance.max : Importance.high,
          priority: Priority.high,
          ticker: 'ticker',
          playSound: playSound,
          // Vibration pattern for both (optional, but good for silent)
          vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
        ),
        iOS: DarwinNotificationDetails(presentSound: playSound),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id: id);
  }

  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
