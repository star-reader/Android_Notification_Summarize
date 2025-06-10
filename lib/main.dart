import 'package:flutter/material.dart';
import 'utils/demo_notifications.dart';

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
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: ElevatedButton(onPressed: () => sendNotification() , child: Text('Send Notification'))
        ),
      ),
    );
  }
}