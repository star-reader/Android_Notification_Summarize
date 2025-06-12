import 'dart:convert';

import 'package:notification_summarize/main.dart';
import 'package:notification_summarize/services/auth/fetch_token.dart';
import 'package:notification_summarize/services/files/message_files.dart';

import '../../models/notifications_model.dart';
import '../../utils/sha_utils.dart';
import '../providers/global_notification_store.dart';
import '../../configs/private/config_store.dart';
import 'package:dio/dio.dart';
import '../../utils/notifications/send_summary.dart';

// 这里主要就是接收temp通知，发到服务器去获取摘要的了
class SummarizeTasks {
  static final SummarizeTasks _instance = SummarizeTasks._internal();
  factory SummarizeTasks() => _instance;
  SummarizeTasks._internal();

  static const int minContentLength = 25;
  static const Duration timeWindow = Duration(minutes: 40);
  static const int minMessagesForAnalysis = 2;

  bool _isProcessing = false;
  
  Future<void> startSummarizeTask() async {
    if (_isProcessing) {
      print('已有分析任务在进行中，跳过');
      return;
    }

    try {
      _isProcessing = true;
      
      final notificationStore = NotificationStore();
      final notifications = notificationStore.notificationList;
      
      // 按包名分组的Map
      Map<String, List<NotificationItemModel>> packageGroups = {};

      // 第一步：按包名分组并提取NotificationItemModel
      for (var notification in notifications) {
        final packageName = notification['packageName'] as String;
        final data = notification['data'];
        
        if (data is List) {
          if (!packageGroups.containsKey(packageName)) {
            packageGroups[packageName] = [];
          }
          
          for (var item in data) {
            if (item is NotificationItemModel && !(item.hasAnalyzed ?? false)) {
              packageGroups[packageName]!.add(item);
            }
          }
        }
      }

      // 处理每个包的通知组
      for (var entry in packageGroups.entries) {
        var packageNotifications = entry.value;
        if (packageNotifications.isEmpty) continue;

        // 按时间排序
        packageNotifications.sort((a, b) {
          final timeA = DateTime.parse(a.time ?? DateTime.now().toString());
          final timeB = DateTime.parse(b.time ?? DateTime.now().toString());
          return timeA.compareTo(timeB);
        });

        // 去重处理
        final uniqueNotifications = _removeDuplicateMessages(packageNotifications);
        
        if (uniqueNotifications.length == 1) {
          // 单条消息处理
          final content = uniqueNotifications[0].content ?? '';
          if (content.length >= 16) {
            await sendToAnalysisServer(entry.key, uniqueNotifications);
            await updateAnalysisStatus(uniqueNotifications);
          } else {
            await updateAnalysisStatus(uniqueNotifications);
          }
        } else if (uniqueNotifications.length >= 2) {
          // 多条消息处理
          await sendToAnalysisServer(entry.key, uniqueNotifications);
          await updateAnalysisStatus(uniqueNotifications);
        }
      }
    } finally {
      _isProcessing = false;
    }
  }

  List<NotificationItemModel> _removeDuplicateMessages(List<NotificationItemModel> messages) {
    final uniqueMessages = <NotificationItemModel>[];
    final seenContents = <String>{};

    for (var message in messages) {
      final contentKey = '${message.title}_${message.content}';
      if (!seenContents.contains(contentKey)) {
        seenContents.add(contentKey);
        uniqueMessages.add(message);
      }
    }

    print('去重前消息数: ${messages.length}, 去重后消息数: ${uniqueMessages.length}');
    return uniqueMessages;
  }

  List<Map<String, String>> _prepareMessages(List<NotificationItemModel> notifications) {
    return notifications.map((notification) => {
      'title': notification.title ?? '',
      'content': notification.content ?? '',
      'time': notification.time ?? '',
    }).toList();
  }

  Future<void> sendToAnalysisServer(String packageName, List<NotificationItemModel> messages) async {
    if (messages.isEmpty) {
      print('没有消息需要发送');
      return;
    }

    // 去重处理
    final uniqueMessages = _removeDuplicateMessages(messages);
    if (uniqueMessages.isEmpty) {
      print('去重后没有消息需要发送');
      return;
    }

    // 转换为API需要的格式
    final preparedMessages = _prepareMessages(uniqueMessages);

    try {
      var token = await FetchToken.fetchToken();
      
      final applyIdResponse = await dio.post(
        '${ConfigStore.apiEndpoint}/api/connect',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final applyId = applyIdResponse.data['applyId'];
      
      // 构建单个请求对象
      final requestData = {
        'currentTime': DateTime.now().toString(),
        'data': preparedMessages,  // 使用转换后的消息数组
      };

      print('发送数据到服务器: ${jsonEncode(requestData)}');
      
      // 发送请求
      final response = await dio.post(
        '${ConfigStore.apiEndpoint}/api/generate',
        data: {
          'data': jsonEncode(requestData),
          'applyId': applyId,
          'verify': calculateSHA256(jsonEncode(requestData)),
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