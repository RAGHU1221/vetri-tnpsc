import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Daily quiz reminder — local notification (Firebase thevai illa)
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    await _plugin.initialize(const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher')));
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Daily 7 PM reminder
  static Future<void> scheduleDailyQuizReminder() async {
    var when = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(tz.local, when.year, when.month, when.day, 19);
    if (next.isBefore(when)) next = next.add(const Duration(days: 1));
    await _plugin.zonedSchedule(
      1001,
      'வெற்றி TNPSC 📚',
      'இன்றைய Daily Quiz ready! 10 கேள்விகள் — 2 நிமிடம் போதும் 💪',
      next,
      const NotificationDetails(
          android: AndroidNotificationDetails('daily_quiz', 'Daily Quiz',
              importance: Importance.high)),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // repeat daily
    );
  }

  static Future<void> cancelReminder() => _plugin.cancel(1001);
}
