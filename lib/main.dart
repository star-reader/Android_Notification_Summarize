import 'dart:async';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'widgets/navigations/navigation_mobile.dart';
import 'package:provider/provider.dart';
import 'utils/demo_notifications.dart';
import 'services/providers/demo_event_bus.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'utils/notifications/notifications_listener.dart';
import 'services/providers/global_notification_store.dart';
import 'services/providers/navigation_store.dart';
import 'pages/notifications_data/notifications_data_index.dart';
import 'services/providers/token_store.dart';

final dio = Dio();

Future<void> checkAndRequestPermissions() async {
  // 检查通知监听权限
  final bool notificationListenerStatus = 
      await NotificationListenerService.isPermissionGranted();
  
  if (!notificationListenerStatus) {
    // 打开系统设置页面，让用户手动开启通知访问权限
    await NotificationListenerService.requestPermission();
    // 提示用户需要手动开启权限
    // 这里可以使用对话框提示用户具体操作步骤
  }

  // 检查通知发送权限（Android 13及以上需要）
  if (Platform.isAndroid) {
    final status = await Permission.notification.status;
    if (status.isDenied) {
      await Permission.notification.request();
    }
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  checkAndRequestPermissions();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => NotificationStore()),
        ChangeNotifierProvider(create: (context) => NavigationStore()),
        ChangeNotifierProvider(create: (context) => TokenStore()),
      ],
      child: const MyApp(),
    )
  );  
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  void sendNotification() async {
    DemoNotifications demoNotifications = DemoNotifications(4, 6);
    demoNotifications.startSendNotifications();
  }

  void grantPermission() async {
    final status = await NotificationListenerService.isPermissionGranted();
    if (!status) {
      await NotificationListenerService.requestPermission();
    }
  }

  // // 删除两天前的旧消息
  // // todo  后续改成用户可以自定义时间
  // void clearOldNotifications() async {
  //   MessageFiles messageFiles = MessageFiles();
  //   await messageFiles.clearOldNotifications();
  // }

  // void fetchToken() async {
  //   String token = await FetchToken.fetchToken();
  //   TokenStore().setToken(token);
  // }

  @override
  Widget build(BuildContext context) {
    final navigationStore = context.watch<NavigationStore>();

    grantPermission();

    // 进入就开始监听通知
    NotificationsListener notificationListener = NotificationsListener();
    notificationListener.startListening();

    // 预准备工作
    // clearOldNotifications();
    // 测试的通知页面
    // sendNotification();

    return MaterialApp(
      home: Scaffold(
        body: IndexedStack(
          index: navigationStore.currentPageIndex,
          children: const [
            DemoContentArea(),
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