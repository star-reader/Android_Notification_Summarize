import 'dart:convert';

import 'package:notification_summarize/main.dart';
import 'package:notification_summarize/services/auth/fetch_token.dart';
import 'package:notification_summarize/services/files/message_files.dart';

import '../../models/notifications_model.dart';
import '../../utils/sha_utils.dart';
import '../providers/demo_event_bus.dart';
import '../providers/global_notification_store.dart';
import '../../configs/private/config_store.dart';
import 'package:dio/dio.dart';
import '../../utils/notifications/send_summary.dart';

// 这里主要就是接收temp通知，发到服务器去获取摘要的了
class SummarizeTasks {
  // 定义时间窗口（例如：3分钟内的消息视为一组）
  static const Duration timeWindow = Duration(minutes: 40);
  static const int minMessagesForAnalysis = 3; // 最小分析消息数

  void startSummarizeTask() {
    final notificationStore = NotificationStore();
    final notifications = notificationStore.notificationList;
    
    // 按包名分组的Map
    Map<String, List<NotificationItemModel>> packageGroups = {};

    // 第一步：按包名分组并提取NotificationItemModel
    for (var notification in notifications) {
      final packageName = notification['packageName'] as String;
      final data = notification['data'];
      
      // 由于我们现在的data是List<NotificationItemModel>
      if (data is List) {
        if (!packageGroups.containsKey(packageName)) {
          packageGroups[packageName] = [];
        }
        
        for (var item in data) {
          if (item is NotificationItemModel) {
            packageGroups[packageName]!.add(item);
          }
        }
      }
    }

    // 第二步：处理每个包的通知，按时间窗口和分析状态分组
    List<List<NotificationItemModel>> unAnalyzedGroups = [];

    for (var entry in packageGroups.entries) {
      var packageNotifications = entry.value;
      
      // 按时间排序
      packageNotifications.sort((a, b) {
        final timeA = DateTime.parse(a.time ?? DateTime.now().toString());
        final timeB = DateTime.parse(b.time ?? DateTime.now().toString());
        return timeA.compareTo(timeB);
      });
      

      List<NotificationItemModel> currentGroup = [];
      DateTime? lastMessageTime;

      for (var notification in packageNotifications) {
        final currentTime = DateTime.parse(notification.time ?? DateTime.now().toString());
        bool needsAnalysis = !(notification.hasAnalyzed ?? false);
        
        if (needsAnalysis) {
          if (lastMessageTime != null && 
              currentTime.difference(lastMessageTime!) > timeWindow && 
              currentGroup.isNotEmpty) {
            unAnalyzedGroups.add(List.from(currentGroup));
            currentGroup.clear();
          }
          
          currentGroup.add(notification);
          lastMessageTime = currentTime;
        }
      }

      if (currentGroup.isNotEmpty) {
        unAnalyzedGroups.add(List.from(currentGroup));
      }
    }
    
    if (unAnalyzedGroups.isEmpty) {
      return;
    }

    processUnanalyzedGroups(unAnalyzedGroups);
  }

  void processUnanalyzedGroups(List<List<NotificationItemModel>> groups) {
    
    for (var group in groups) {
      if (group.isEmpty) {
        continue;
      }

      final packageName = group[0].packageName;

      // 只处理符合最小数量要求的组
      if (group.length >= minMessagesForAnalysis) {
        
        List<Map<String, String>> messages = group.map((notification) => {
          'title': notification.title ?? '',
          'content': notification.content ?? '',
          'time': notification.time ?? '',
        }).toList();

        sendToAnalysisServer(packageName ?? '', messages);
        updateAnalysisStatus(group);
      }
    }
  }

  Future<void> sendToAnalysisServer(String packageName, List<Map<String, String>> messages) async {
    if (messages.length < minMessagesForAnalysis) {
      return;
    }
    eventBus.fire(DemoSummaryStart(
      title: '发送API啦，消息数量: ${messages.length}个！',
      content: jsonEncode(messages),
      time: DateTime.now().toString(),
    ));
    
    var token = await FetchToken.fetchToken();

    final applyIdResponse = await dio.post('${ConfigStore.apiEndpoint}/api/connect', options: Options(
      headers: {
        'Authorization': 'Bearer $token',
      },
    ));

    final applyId = applyIdResponse.data['applyId'];


    final data = {'currentTime': DateTime.now().toString(), 'data': messages};
    
    final response = await dio.post('${ConfigStore.apiEndpoint}/api/generate', data: {
      'data':  jsonEncode(data),
      'applyId': applyId,
      'verify': calculateSHA256(jsonEncode(data)),
      }, options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
        followRedirects: false,
        validateStatus: (status) => true,
      )
    );
    if (response.statusCode == 200) {
      SendSummary().sendSummaryNotification(response.data['summary']);
    }else{
      print('发送失败~~~~');
    }
     
  }

  Future<void> updateAnalysisStatus(List<NotificationItemModel> group) async {
    final notificationStore = NotificationStore();
    final messageFiles = MessageFiles();

    // 更新内存中的通知状态
    for (var notification in group) {
      if (notification.packageName == null) continue;
      
      // 获取包名对应的通知列表
      var notifications = notificationStore.getNotificationsByPackageName(notification.packageName!);
      
      // 找到并更新对应的通知
      for (var existingNotification in notifications) {
        if (existingNotification.uuid == notification.uuid) {
          existingNotification.hasAnalyzed = true;
          break;
        }
      }
    }

    // 读取当前本地存储的通知
    final localNotifications = await messageFiles.readNotifications();
    
    // 更新本地存储中的通知状态
    for (var item in localNotifications.notificationList) {
      final data = item['data'];
      if (data is Map<String, dynamic>) {
        // 检查是否是需要更新的通知
        for (var notification in group) {
          if (data['uuid'] == notification.uuid) {
            data['hasAnalyzed'] = true;
            break;
          }
        }
      }
    }

    // 保存更新后的通知到本地存储
    await messageFiles.writeNotifications(localNotifications);
  }
}