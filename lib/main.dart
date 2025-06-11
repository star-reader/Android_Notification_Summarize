import 'dart:async';
import 'package:flutter/material.dart';
import 'widgets/navigations/navigation_mobile.dart';
import 'package:provider/provider.dart';
import 'utils/demo_notifications.dart';
import 'utils/demo_notification_listener.dart';
import 'services/providers/demo_event_bus.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'utils/notifications/notifications_listener.dart';
import 'services/providers/global_notification_store.dart';
import 'services/providers/navigation_store.dart';
import 'pages/notifications_data/notifications_data_index.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => NotificationStore()),
        ChangeNotifierProvider(create: (context) => NavigationStore()),
      ],
      child: const MyApp(),
    )
  );  
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  void sendNotification() async {
    DemoNotifications demoNotifications = DemoNotifications(10, 6);
    demoNotifications.startSendNotifications();
  }

  void grantPermission() async {
    final status = await NotificationListenerService.isPermissionGranted();
    if (!status) {
      await NotificationListenerService.requestPermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    final navigationStore = context.watch<NavigationStore>();

    grantPermission();

    // 进入就开始监听通知
    NotificationsListener notificationListener = NotificationsListener();
    notificationListener.startListening();

    sendNotification();

    return MaterialApp(
      home: Scaffold(
        body: IndexedStack(
          index: navigationStore.currentPageIndex,
          children: const [
            DemoContentArea(),
            NotificationsDataIndex(),
            DemoContentArea(),
          ],
        ),
        bottomNavigationBar: const NavigationMobile(),
      ),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      themeMode: ThemeMode.system,
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