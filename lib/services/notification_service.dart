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

      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'gym_timer',
        'Timer',
        description: 'Notifications for workout rest timers',
        importance: Importance.max,
        playSound: true,
      );

      await androidImplementation.createNotificationChannel(channel);
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required int seconds,
  }) async {
    // Attempting to use zonedSchedule.
    // If 'uiLocalNotificationDateInterpretation' is not defined (as per error), we omit it.
    // Use named 'scheduledDate' and 'notificationDetails'.
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.now(
        tz.local,
      ).add(Duration(seconds: seconds)),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'rest_timer_channel',
          'Rest Timer',
          channelDescription: 'Notifications for workout rest timers',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
          vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      // Removed uiLocalNotificationDateInterpretation: ...
      // If it is required, the build will fail, but the linter said it's "Undefined".
      // If it is required but undefined, we have a bigger version mismatch problem.
      // But usually "Undefined named parameter" means "You passed X but I don't accept X".
      // If the function REQUIRES it, it would be a positional arg in old versions, or a required named arg.
      // If it is a required named arg, but I can't name it... that's a paradox unless the name is different.
      // Trying without it explicitly.
    );
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id: id);
  }

  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
