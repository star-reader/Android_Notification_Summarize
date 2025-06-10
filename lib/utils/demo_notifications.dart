import 'dart:async';
import 'package:easy_notifications/easy_notifications.dart';

class DemoNotifications {
  int timeout = 6;
  int interval = 10;

  Timer? timer;

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
    await EasyNotifications.showMessage(
      title: 'test', body: 'test body'
    );
  }

  Future<void> init() async {
    await EasyNotifications.init();
  }

  void stopSendNotifications() {
    timer?.cancel();
  }
}