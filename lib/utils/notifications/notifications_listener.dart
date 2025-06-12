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

  bool _isRequestingPermission = false;  // 添加标志位防止重复请求

  void startPeriodicAnalysis() {
    _periodicAnalysisTimer?.cancel();
    _periodicAnalysisTimer = Timer.periodic(const Duration(minutes: 3), (timer) {
      SummarizeTasks().startSummarizeTask();
    });
  }

  void startListening() async {
    try {
      if (_isRequestingPermission) return;  // 如果正在请求权限，直接返回

      final bool status = await NotificationListenerService.isPermissionGranted();
      MessageFiles messageFiles = MessageFiles();

      if (!status) {
        _isRequestingPermission = true;
        try {
          await NotificationListenerService.requestPermission();
          final bool newStatus = await NotificationListenerService.isPermissionGranted();
          if (!newStatus) {
            _isRequestingPermission = false;
            return;
          }
        } catch (e) {
          _isRequestingPermission = false;
          return;
        }
        _isRequestingPermission = false;
      }

      // 启动定时分析（作为备份机制）
      startPeriodicAnalysis();

      NotificationListenerService.notificationsStream.listen(
        (event) async {  // 修改为 async 回调
          try {
            if (event.title == null ||
                event.content == null ||
                event.packageName == null) {
              return;
            }

            if (event.hasRemoved ?? false) {
              return;
            }

            // 忽略自己的消息通知
            if (event.packageName == 'top.usagijin.notification_summarize') {
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

            // 使用 Future.microtask 来处理事件发送
            await Future.microtask(() {
              // 1. 发送到 EventBus
              eventBus.fire(notificationItemModel);

              eventBus.fire(NotificationReceivedEvent(
                title: event.title,
                content: event.content,
                packageName: event.packageName,
                id: event.id?.toString() ?? '0',
                time: DateTime.now().toString(),
              ));
            });

            // 2. 存储到临时存储
            notificationStore.addNotificationByPackageName(
              event.packageName ?? '',
              notificationItemModel
            );

            // 3. 保存到本地数据库
            await _saveToLocalDatabase(notificationItemModel, messageFiles);

            // 4. 立即检查是否需要分析
            _checkAndTriggerAnalysis(event.packageName ?? '');
          } catch (e) {
            print('处理通知时出错: $e');
          }
        },
        onError: (error) {
          print('通知监听出错: $error');
          _isRequestingPermission = false;
        },
        cancelOnError: false,  // 防止因错误而停止监听
      );
    } catch (e) {
      print('启动通知监听服务出错: $e');
      _isRequestingPermission = false;
    }
  }

  Future<void> _saveToLocalDatabase(
    NotificationItemModel notification,
    MessageFiles messageFiles
  ) async {
    try {
      NotificationListModel tempNotificationListModel = NotificationListModel();
      tempNotificationListModel.notificationList.add({
        'packageName': notification.packageName ?? '',
        'data': notification,
      });
      await messageFiles.writeNotifications(tempNotificationListModel);
    } catch (e) {
      print('保存通知到本地数据库时出错: $e');
    }
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
    final minNotifications = 3;  // 最小通知数量阈值
    
    // 获取最近时间窗口内的未分析通知
    final recentUnanalyzed = notifications.where((notification) {
      if (notification.hasAnalyzed ?? false) return false;
      
      final notificationTime = DateTime.parse(notification.time ?? now.toString());
      final timeDiff = now.difference(notificationTime);
      
      return timeDiff <= timeWindow;
    }).toList();

    // 调试输出
    print('未分析的通知数量: ${recentUnanalyzed.length}');
    if (recentUnanalyzed.isNotEmpty) {
      print('第一条未分析通知内容长度: ${recentUnanalyzed[0].content?.length}');
    }

    // 如果只有一条消息，检查内容长度
    if (recentUnanalyzed.length == 1) {
      final contentLength = recentUnanalyzed[0].content?.length ?? 0;
      print('单条消息长度: $contentLength');
      return contentLength >= 16; // 只有内容长度大于等于16才触发分析
    }

    // 如果有多条消息，使用原有逻辑
    if (recentUnanalyzed.length >= 2) {
      return true; // 两条或以上直接触发分析
    }
  
    return false;
  }
}

