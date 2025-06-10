import 'package:event_bus/event_bus.dart';

EventBus eventBus = EventBus();

class NotificationReceivedEvent {
  String? title;
  String? content;
  String? packageName;
  String? id;

  NotificationReceivedEvent({this.title, this.content, this.packageName, this.id});
}