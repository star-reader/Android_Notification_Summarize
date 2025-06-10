import 'dart:async';

import 'package:flutter/material.dart';
import 'utils/demo_notifications.dart';
import 'utils/demo_notification_listener.dart';
import 'services/providers/demo_event_bus.dart';

void main() {
  runApp(const MyApp());  
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  void sendNotification() async {
    DemoNotifications demoNotifications = DemoNotifications(10, 6);
    demoNotifications.startSendNotifications();
  }

  @override
  Widget build(BuildContext context) {

    DemoNotificationListener notificationListener = DemoNotificationListener();
    notificationListener.startListening();

    return MaterialApp(
      home: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: ElevatedButton(onPressed: () => sendNotification() , child: Text('Send Notification'))
            ),
            DemoContentArea(),
          ],
        ),
      ),
    );
    
  }
}

class DemoContentArea extends StatefulWidget {
  const DemoContentArea({super.key});

  @override
  State<DemoContentArea> createState() => _DemoContentAreaState();
}

class _DemoContentAreaState extends State<DemoContentArea> {

  NotificationReceivedEvent? notificationReceivedEvent;

  late StreamSubscription<NotificationReceivedEvent> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = eventBus.on<NotificationReceivedEvent>().listen((event) {
      setState(() {
        notificationReceivedEvent = event;
      });
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Text('Title: ${notificationReceivedEvent?.title}'),
          Text('Content: ${notificationReceivedEvent?.content}'),
          Text('Package Name: ${notificationReceivedEvent?.packageName}'),
          Text('ID: ${notificationReceivedEvent?.id}'),
        ],
      ),
    );
  }
}