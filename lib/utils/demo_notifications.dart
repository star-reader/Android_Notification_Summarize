import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../configs/demo/notifications_demo.dart';

class DemoNotifications {
  int timeout = 6;
  int interval = 10;

  int count = 0;

  Timer? timer;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  DemoNotifications(this.interval, this.timeout);

  void startSendNotifications() async {
    await init();
    count = 0;
    for (int i = 0; i <= interval; i++) {
      count++;
      await Future.delayed(Duration(seconds: timeout));
      await sendNotification(count);
    }
    timer?.cancel();
  }

  Future<void> sendNotification(int count) async {
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

    var notification = NotificationsDemo.getNotifications(count - 1);
    
    await flutterLocalNotificationsPlugin.show(
      0,
      notification['title'],
      notification['content'],
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