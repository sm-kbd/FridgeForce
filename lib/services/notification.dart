import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:rxdart/rxdart.dart';

class NotificationService {
  static final NotificationService _notificationService =
      NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final BehaviorSubject<String?> onNotificationClick = BehaviorSubject();

  factory NotificationService() {
    return _notificationService;
  }

  NotificationService._internal();

  InitializationSettings _initAndroid() {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings(
          'app_icon',
        ); // Replace 'app_icon' with your actual app icon name in drawable
    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    return initializationSettings;
  }

  InitializationSettings _initIOS() {
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    final InitializationSettings initializationSettings =
        InitializationSettings(iOS: initializationSettingsIOS);
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return initializationSettings;
  }

  Future<void> init() async {
    tz.initializeTimeZones();
    // For example, set to America/New_York
    tz.setLocalLocation(tz.getLocation('America/New_York'));

    final InitializationSettings initializationSettings;
    if (Platform.isAndroid) {
      initializationSettings = _initAndroid();
    } else if (Platform.isIOS) {
      initializationSettings = _initIOS();
    } else {
      initializationSettings = InitializationSettings();
    }

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    // PERMISSIONS
    // For Android, permissions are generally handled at installation for basic notifications
    // For Android 13+, POST_NOTIFICATIONS permission is explicitly requested.
    // The permission_handler package can be used for explicit permission requests if needed. [24, 25]
  }

  NotificationDetails _notificationDetails() {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'your_channel_id', // Required for Android 8.0+ [1]
          'your_channel_name',
          channelDescription: 'your_channel_description',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
          icon: 'app_icon', //  Must be a drawable resource [7]
        );
    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    return const NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required int daysLater,
    String? payload,
  }) async {
    final scheduledDate = tz.TZDateTime.now(
      tz.local,
    ).add(Duration(days: daysLater));

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
      matchDateTimeComponents:
          DateTimeComponents.dateAndTime, // Ensure it matches date and time
    );
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      _notificationDetails(),
    );
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }
}
