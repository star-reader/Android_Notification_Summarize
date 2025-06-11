import 'dart:async';

import 'package:flutter/material.dart';
import 'utils/demo_notifications.dart';
import 'utils/demo_notification_listener.dart';
import 'services/providers/demo_event_bus.dart';
import 'package:notification_listener_service/notification_listener_service.dart';

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
        appBar: AppBar(
          title: const Text('通知汇总'),
          actions: [
            FutureBuilder<bool>(
              future: NotificationListenerService.isPermissionGranted(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Icon(
                    snapshot.data! ? Icons.check_circle : Icons.error,
                    color: snapshot.data! ? Colors.green : Colors.red,
                  );
                }
                return const Icon(Icons.help);
              },
            ),
          ],
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: ElevatedButton(
                onPressed: () => sendNotification(), 
                child: const Text('Send Notification')
              )
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final status = await NotificationListenerService.isPermissionGranted();
                if (!status) {
                  await NotificationListenerService.requestPermission();
                }
              },
              child: const Text('检查/请求权限'),
            ),
            const SizedBox(height: 20),
            const DemoContentArea(),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text('Title: ${notificationReceivedEvent?.title ?? ''}'),
          Text('Content: ${notificationReceivedEvent?.content ?? ''}'),
          Text('Package Name: ${notificationReceivedEvent?.packageName ?? ''}'),
          Text('ID: ${notificationReceivedEvent?.id ?? ''}'),
          Text('Time: ${notificationReceivedEvent?.time ?? ''}')
        ],
      ),
    );
  }
}