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
  static const int minSingleMessageLength = 16; // 单条消息最小内容长度

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
    print('开始处理消息组，组数: ${groups.length}');
    
    for (var group in groups) {
      if (group.isEmpty) {
        print('跳过空组');
        continue;
      }

      final packageName = group[0].packageName;
      print('处理包名: $packageName 的消息组，消息数量: ${group.length}');
      
      // 去重处理
      group = _removeDuplicateMessages(group);
      print('去重后消息数量: ${group.length}');

      // 如果只有一条消息，检查内容长度
      if (group.length == 1) {
        final content = group[0].content ?? '';
        print('单条消息长度: ${content.length}');
        
        if (content.length >= 16) {
          print('发送单条长消息到服务器');
          sendToAnalysisServer(packageName ?? '', _prepareMessages(group));
          updateAnalysisStatus(group);
        } else {
          print('单条消息太短，标记为已分析');
          updateAnalysisStatus(group);
        }
        continue;
      }

      // 处理多条消息
      if (group.length >= 2) {  // 改为2条就触发
        print('发送多条消息到服务器');
        sendToAnalysisServer(packageName ?? '', _prepareMessages(group));
        updateAnalysisStatus(group);
      } else {
        print('消息数量不足，不处理');
      }
    }
  }

  List<NotificationItemModel> _removeDuplicateMessages(List<NotificationItemModel> messages) {
    final uniqueMessages = <NotificationItemModel>[];
    final seenContents = <String>{};

    for (var message in messages) {
      final content = message.content ?? '';
      final title = message.title ?? '';
      
      // 创建消息的唯一标识（标题+内容）
      final messageKey = '$title$content';
      
      // 如果这个内容之前没见过，就添加到结果中
      if (!seenContents.contains(messageKey)) {
        seenContents.add(messageKey);
        uniqueMessages.add(message);
      }
    }

    return uniqueMessages;
  }

  List<Map<String, String>> _prepareMessages(List<NotificationItemModel> group) {
    return group.map((notification) => {
      'title': notification.title ?? '',
      'content': notification.content ?? '',
      'time': notification.time ?? '',
    }).toList();
  }

  Future<void> sendToAnalysisServer(String packageName, List<Map<String, String>> messages) async {
    print('准备发送到服务器，消息数量: ${messages.length}');
    
    try {
      var token = await FetchToken.fetchToken();
      print('获取到token');

      final applyIdResponse = await dio.post(
        '${ConfigStore.apiEndpoint}/api/connect',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
      print('获取到applyId');

      final applyId = applyIdResponse.data['applyId'];
      final data = {'currentTime': DateTime.now().toString(), 'data': messages};
      
      print('发送数据到服务器');
      final response = await dio.post(
        '${ConfigStore.apiEndpoint}/api/generate',
        data: {
          'data': jsonEncode(data),
          'applyId': applyId,
          'verify': calculateSHA256(jsonEncode(data)),
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
          followRedirects: false,
          validateStatus: (status) => true,
        ),
      );

      print('服务器响应状态码: ${response.statusCode}');
      if (response.statusCode == 200) {
        print('发送成功，准备显示摘要通知');
        SendSummary().sendSummaryNotification(response.data['summary']);
      } else {
        print('发送失败: ${response.data}');
      }
    } catch (e) {
      print('发送过程中出错: $e');
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