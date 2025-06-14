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
        if (event.title == null || event.content == null || event.packageName == null) {
          return;
        }
        eventBus.fire(NotificationReceivedEvent(
          title: event.title,
          content: event.content,
          packageName: event.packageName,
          id: event.id?.toString() ?? '0',
          time: DateTime.now().toString(),
        ));
      }, onError: (_) {
      }
    );
      
    } catch (_) { }
  }
}