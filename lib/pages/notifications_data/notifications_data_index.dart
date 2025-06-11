import 'package:flutter/material.dart';
import '../../services/files/message_files.dart';
import '../../models/notifications_model.dart';
import 'package:intl/intl.dart'; // 添加日期格式化依赖

class NotificationsDataIndex extends StatefulWidget {
  const NotificationsDataIndex({super.key});

  @override
  State<NotificationsDataIndex> createState() => _NotificationsDataIndexState();
}

class _NotificationsDataIndexState extends State<NotificationsDataIndex> {
  final MessageFiles messageFiles = MessageFiles();

  // 格式化日期时间
  String _formatDateTime(String dateTimeStr) {
    final dateTime = DateTime.parse(dateTimeStr);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      // 今天的消息显示时间
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference.inDays == 1) {
      return '昨天 ${DateFormat('HH:mm').format(dateTime)}';
    } else {
      return DateFormat('MM-dd HH:mm').format(dateTime);
    }
  }

  // 获取应用图标
  Widget _getAppIcon(String packageName) {
    // 可以根据包名返回对应的图标，这里先用占位图标
    return CircleAvatar(
      backgroundColor: Colors.primaries[packageName.length % Colors.primaries.length],
      child: Text(
        packageName.split('.').last.substring(0, 1).toUpperCase(),
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              // 显示确认对话框
              final bool? confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('清除通知'),
                  content: const Text('是否要清除两天前的通知？'),
                  actions: [
                    TextButton(
                      child: const Text('取消'),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                    TextButton(
                      child: const Text('确定'),
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ],
                ),
              );
              
              if (confirm == true) {
                await messageFiles.clearOldNotifications();
                setState(() {}); // 刷新列表
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<NotificationListModel>(
        future: messageFiles.readNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('加载失败: ${snapshot.error}'),
                ],
              ),
            );
          }

          final notifications = snapshot.data?.notificationList ?? [];

          print(notifications);
          
          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('暂无通知'),
                ],
              ),
            );
          }

          // 按时间排序（从新到旧）
          notifications.sort((a, b) {
            final timeA = DateTime.parse(a['data']['time'] as String);
            final timeB = DateTime.parse(b['data']['time'] as String);
            return timeB.compareTo(timeA);
          });

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final data = notification['data'] as Map<String, dynamic>;
              final packageName = notification['packageName'] as String;
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: _getAppIcon(packageName),
                  title: Text(
                    data['title'] ?? '无标题',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        data['text'] ?? '无内容',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDateTime(data['time']),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    // 点击显示完整内容
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(data['title'] ?? '无标题'),
                        content: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(data['text'] ?? '无内容'),
                              const SizedBox(height: 8),
                              Text(
                                '来自: ${packageName}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                '时间: ${data['time']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            child: const Text('关闭'),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}