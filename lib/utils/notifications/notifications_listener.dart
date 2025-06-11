import 'dart:async';

import 'package:notification_listener_service/notification_listener_service.dart';
import '../../models/notifications_model.dart';
import '../../services/providers/demo_event_bus.dart';
import '../../services/providers/global_notification_store.dart';
import '../../services/files/message_files.dart';
import '../../services/summarize/summarize_tasks.dart';
import '../random_uuid.dart';

class NotificationsListener {

  // 在 NotificationsListener 类中添加
  Timer? _periodicAnalysisTimer;

  final NotificationStore notificationStore = NotificationStore();

  void startPeriodicAnalysis() {
    _periodicAnalysisTimer?.cancel();
    _periodicAnalysisTimer = Timer.periodic(const Duration(minutes: 3), (timer) {
      SummarizeTasks().startSummarizeTask();
    });
  }

  void startListening() async {
    try {
      final bool status = await NotificationListenerService.isPermissionGranted();
      MessageFiles messageFiles = MessageFiles();

      if (!status) {
        await NotificationListenerService.requestPermission();
        final bool newStatus = await NotificationListenerService.isPermissionGranted();
        if (!newStatus) {
          return;
        }
      }

      // 启动定时分析（作为备份机制）
      startPeriodicAnalysis();

      NotificationListenerService.notificationsStream.listen((event) {
        if (event.title == null ||
            event.content == null ||
            event.packageName == null) {
          return;
        }

        if (event.hasRemoved ?? false) {
          return;
        }

        final notificationItemModel = NotificationItemModel(
          title: event.title,
          content: event.content,
          packageName: event.packageName,
          id: event.id?.toString() ?? '0',
          uuid: RandomUuid.generateRandomString(16),
          time: DateTime.now().toString(),
          hasAnalyzed: false,
        );

        // 1. 发送到 EventBus
        eventBus.fire(notificationItemModel);
        
        // 2. 存储到临时存储并打印日志确认
        notificationStore.addNotificationByPackageName(
          event.packageName ?? '', 
          notificationItemModel
        );
        
        // 3. 保存到本地数据库
        _saveToLocalDatabase(notificationItemModel, messageFiles);
        
        // 4. 立即检查是否需要分析
        _checkAndTriggerAnalysis(event.packageName ?? '');
      }, onError: (_) { }
      );
    } catch (_) { }
  }

  void _saveToLocalDatabase(
    NotificationItemModel notification, 
    MessageFiles messageFiles
  ) {
    NotificationListModel tempNotificationListModel = NotificationListModel();
    tempNotificationListModel.notificationList.add({
      'packageName': notification.packageName ?? '',
      'data': notification,
    });
    messageFiles.writeNotifications(tempNotificationListModel);
  }

  void _checkAndTriggerAnalysis(String packageName) {
    final notifications = notificationStore.getNotificationsByPackageName(packageName);
    
    if (_shouldAnalyzeNotifications(notifications)) {
      SummarizeTasks().startSummarizeTask();
    }
  }

  bool _shouldAnalyzeNotifications(List<NotificationItemModel> notifications) {
    if (notifications.isEmpty) return false;

    final now = DateTime.now();
    final timeWindow = const Duration(minutes: 40);
    final minNotifications = 2;  // 最小通知数量阈值

    // 获取最近时间窗口内的未分析通知
    final recentUnanalyzed = notifications.where((notification) {
      if (notification.hasAnalyzed ?? false) return false;
      
      final notificationTime = DateTime.parse(notification.time ?? now.toString());
      final timeDiff = now.difference(notificationTime);
      
      return timeDiff <= timeWindow;
    }).toList();

    // 检查通知数量和时间间隔
    if (recentUnanalyzed.length >= minNotifications) {
      // 检查最新两条通知的时间间隔
      final latestTime = DateTime.parse(recentUnanalyzed.last.time!);
      final previousTime = DateTime.parse(recentUnanalyzed[recentUnanalyzed.length - 2].time!);
      
      // 如果最新两条通知间隔小于1分钟，立即触发分析
      if (latestTime.difference(previousTime).inMinutes < 1) {
        return true;
      }
      
      // 如果累积了3条以上未分析的通知，也触发分析
      if (recentUnanalyzed.length >= 3) {
        return true;
      }
    }
  
    return false;
  }
}

