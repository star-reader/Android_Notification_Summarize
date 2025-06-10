import 'dart:async';
import 'package:easy_notifications/easy_notifications.dart';

class DemoNotifications {
  int timeout = 6;
  int interval = 10;

  Timer? timer;

  DemoNotifications(this.interval, this.timeout);

  void startSendNotifications() async {
    await init();
    print('startSendNotifications');
    for (int i = 0; i < interval; i++) {
      await Future.delayed(Duration(seconds: timeout));
      await sendNotification();
    }
    print('endSendNotifications');
    timer?.cancel();
  }

  Future<void> sendNotification() async {
    print('sendNotification');
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