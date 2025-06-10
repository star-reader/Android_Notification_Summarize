import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:event_bus/event_bus.dart';


import 'package:notification_summarize/services/providers/demo_event_bus.dart';class DemoNotificationListener {
  void startListening() async {
      try {
        print('startListening');
        final bool status = await NotificationListenerService.isPermissionGranted();
        if (!status) {
          await NotificationListenerService.requestPermission();
        }
        print('permission status: $status');
        NotificationListenerService.notificationsStream.listen((event) {
          print("Current notification: $event");
          eventBus.fire(NotificationReceivedEvent(
            title: event.title,
            content: event.content,
            packageName: event.packageName,
            id: event.id.toString(),
          ));
        }, onError: (error) {
          print('listener error: ${error.toString()}');
        }, onDone: () {
          print('listener done');
        });
      } catch (exception) {
        print('listener error: ${exception.toString()}');
      }
  }
 
}