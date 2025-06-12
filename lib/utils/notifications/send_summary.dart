import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class SendSummary {

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> sendSummaryNotification(dynamic summaryData) async {
    await init();
    const AndroidNotificationDetails normalNotificationChannel = AndroidNotificationDetails(
      'usagi push channel',
      'Usagi Push Channel',
      channelDescription: 'Usagi Push Channel',
      importance: Importance.high,
      priority: Priority.high,
    );

    const AndroidNotificationDetails priorityNotificationChannel = AndroidNotificationDetails(
      'usagi priority notification channel',
      'Usagi Priority Notification Channel',
      channelDescription: 'Usagi Priority Notification Channel',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails normalNotificationDetails = NotificationDetails(
      android: normalNotificationChannel,
    );

    const NotificationDetails priorityNotificationDetails = NotificationDetails(
      android: priorityNotificationChannel,
    );

    if (summaryData['importanceLevel'] == 5){
      await flutterLocalNotificationsPlugin.show(
        0,
        summaryData['title'],
        '📝 ${summaryData['summary']}',
        priorityNotificationDetails,
      );
    }else{
      await flutterLocalNotificationsPlugin.show(
        0,
        summaryData['title'],
        '📝 ${summaryData['summary']}',
        normalNotificationDetails,
      );
    }
  }
}