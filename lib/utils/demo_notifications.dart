import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:notification_summarize/utils/random_uuid.dart';

class DemoNotifications {
  int timeout = 6;
  int interval = 10;

  Timer? timer;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  DemoNotifications(this.interval, this.timeout);

  void startSendNotifications() async {
    await init();
    for (int i = 0; i < interval; i++) {
      await Future.delayed(Duration(seconds: timeout));
      await sendNotification();
    }
    timer?.cancel();
  }

  Future<void> sendNotification() async {
    const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      'usagi push channel',
      'Usagi Push Channel',
      channelDescription: 'Usagi Push Channel',
      importance: Importance.max,
      priority: Priority.high,
    );
    
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );
    
    await flutterLocalNotificationsPlugin.show(
      0,
      '测试通知滚动5',
      RandomUuid.generateRandomString(6),
      notificationDetails,
    );
  }

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void stopSendNotifications() {
    timer?.cancel();
  }
}