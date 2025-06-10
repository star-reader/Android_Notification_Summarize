import 'package:notification_listener_service/notification_listener_service.dart';

import 'package:notification_summarize/services/providers/demo_event_bus.dart';

class DemoNotificationListener {
  void startListening() async {
    try {
      // 检查当前权限状态
      final bool status = await NotificationListenerService.isPermissionGranted();
      
      if (!status) {
        await NotificationListenerService.requestPermission();
        final bool newStatus = await NotificationListenerService.isPermissionGranted();
        if (!newStatus) {
          return;
        }
      }
      
      NotificationListenerService.notificationsStream.listen((event) {

        if (event.title == null || event.content == null) {
          return;
        }
        eventBus.fire(NotificationReceivedEvent(
          title: event.title ?? '无标题',
          content: event.content ?? '无内容',
          packageName: event.packageName ?? '未知应用',
          id: event.id?.toString() ?? '0',
        ));
      }, onError: (error) {
      });
      
    // ignore: empty_catches
    } catch (exception) { }
  }
}