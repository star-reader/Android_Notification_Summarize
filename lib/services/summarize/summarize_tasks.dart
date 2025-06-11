import '../../models/notifications_model.dart';
import '../providers/global_notification_store.dart';

// 这里主要就是接收temp通知，发到服务器去获取摘要的了
class SummarizeTasks {
  // 定义时间窗口（例如：3分钟内的消息视为一组）
  static const Duration timeWindow = Duration(minutes: 3);
  static const int minMessagesForAnalysis = 2; // 最小分析消息数

  void startSummarizeTask() {
    print('开始分析通知任务...');
    final notificationStore = NotificationStore();
    final notifications = notificationStore.notificationList;
    
    print('当前存储的通知列表: $notifications');
    
    // 按包名分组的Map
    Map<String, List<NotificationItemModel>> packageGroups = {};

    // 第一步：按包名分组并提取NotificationItemModel
    for (var notification in notifications) {
      final packageName = notification['packageName'] as String;
      final data = notification['data'];
      
      print('处理包 $packageName 的通知数据: $data');
      
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
    
    print('按包名分组后的结果: $packageGroups');

    // 第二步：处理每个包的通知，按时间窗口和分析状态分组
    List<List<NotificationItemModel>> unAnalyzedGroups = [];

    for (var entry in packageGroups.entries) {
      print('开始处理包 ${entry.key} 的通知组...');
      var packageNotifications = entry.value;
      
      // 按时间排序
      packageNotifications.sort((a, b) {
        final timeA = DateTime.parse(a.time ?? DateTime.now().toString());
        final timeB = DateTime.parse(b.time ?? DateTime.now().toString());
        return timeA.compareTo(timeB);
      });
      
      print('该包的通知数量: ${packageNotifications.length}');

      List<NotificationItemModel> currentGroup = [];
      DateTime? lastMessageTime;

      for (var notification in packageNotifications) {
        final currentTime = DateTime.parse(notification.time ?? DateTime.now().toString());
        bool needsAnalysis = !(notification.hasAnalyzed ?? false);
        
        print('检查通知: ${notification.title} - 需要分析: $needsAnalysis');
        
        if (needsAnalysis) {
          if (lastMessageTime != null && 
              currentTime.difference(lastMessageTime!) > timeWindow && 
              currentGroup.isNotEmpty) {
            print('创建新的时间窗口组，当前组大小: ${currentGroup.length}');
            unAnalyzedGroups.add(List.from(currentGroup));
            currentGroup.clear();
          }
          
          currentGroup.add(notification);
          lastMessageTime = currentTime;
        }
      }

      if (currentGroup.isNotEmpty) {
        print('添加最后一组，大小: ${currentGroup.length}');
        unAnalyzedGroups.add(List.from(currentGroup));
      }
    }

    print('待分析的通知组数量: ${unAnalyzedGroups.length}');
    
    if (unAnalyzedGroups.isEmpty) {
      print('没有需要分析的通知组');
      return;
    }

    processUnanalyzedGroups(unAnalyzedGroups);
  }

  void processUnanalyzedGroups(List<List<NotificationItemModel>> groups) {
    print('开始处理未分析的通知组...');
    
    for (var group in groups) {
      if (group.isEmpty) {
        print('跳过空组');
        continue;
      }

      final packageName = group[0].packageName;
      final startTime = DateTime.parse(group[0].time!);
      final endTime = DateTime.parse(group.last.time!);
      
      print('===== 处理通知组 =====');
      print('应用包名: $packageName');
      print('时间范围: ${startTime.toString()} 到 ${endTime.toString()}');
      print('通知数量: ${group.length}');

      // 只处理符合最小数量要求的组
      if (group.length >= minMessagesForAnalysis) {
        print('该组满足最小通知数量要求，准备发送到服务器');
        
        List<Map<String, String>> messages = group.map((notification) => {
          'title': notification.title ?? '',
          'content': notification.content ?? '',
          'time': notification.time ?? '',
        }).toList();

        sendToAnalysisServer(packageName ?? '', messages);
        updateAnalysisStatus(group);
      } else {
        print('该组通知数量不足，跳过处理');
      }
    }
  }

  Future<void> sendToAnalysisServer(String packageName, List<Map<String, String>> messages) async {
    print('准备发送到服务器分析...');
    print('包名: $packageName');
    print('消息数量: ${messages.length}');
    print('消息内容: $messages');
    // TODO: 实现实际的服务器发送逻辑
  }

  Future<void> updateAnalysisStatus(List<NotificationItemModel> group) async {
    print('更新通知分析状态...');
    for (var notification in group) {
      notification.hasAnalyzed = true;
      print('已将通知 ${notification.title} 标记为已分析');
    }
    // TODO: 更新存储中的状态
  }
}