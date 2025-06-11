import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
      '突发！突然官宣！就在今年！关乎大湾区！',
      '目前，我们正加速推进东晓南路—广州南站联络线南段、五山路—广园路立交等工程。着力推动“轨道上的大湾区”建设，在全运会前计划建成开通广佛东环城际、穗莞深城际琶洲支线、新白广城际（白云机场T2至竹料段），届时可串联白云机场、金融城、琶洲、广州南站等重要商务区和交通枢纽；继续加快地铁10号线、12号线东段和西段、13号线二期、14号线二期等4条（5段）轨道交通线路的建设，力争全运会前通车，为市民和观赛群众提供更便捷的出行环境。',
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