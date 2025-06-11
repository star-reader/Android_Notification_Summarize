import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/files/message_files.dart';
import '../../models/notifications_model.dart';
import '../../services/providers/demo_event_bus.dart';
import '../../widgets/notifications/notification_list.dart';
import '../../widgets/notifications/notification_detail_dialog.dart';
import '../../widgets/notifications/loading_state.dart';
import '../../widgets/notifications/error_state.dart';

class NotificationsDataIndex extends StatefulWidget {
  const NotificationsDataIndex({super.key});

  @override
  State<NotificationsDataIndex> createState() => _NotificationsDataIndexState();
}

class _NotificationsDataIndexState extends State<NotificationsDataIndex> {
  final MessageFiles messageFiles = MessageFiles();
  late StreamSubscription _notificationSubscription;
  List<Map<String, dynamic>> notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // 初始加载数据
    _loadNotifications();
    
    // 设置事件监听
    _notificationSubscription = eventBus.on<NotificationItemModel>().listen((event) async {
        await _loadNotifications();
    });
  }

  Future<void> _loadNotifications() async {
    try {
      final result = await messageFiles.readNotifications();
      setState(() {
        notifications = result.notificationList;
        notifications.sort((a, b) {
          final timeA = DateTime.parse(a['data']['time'] as String);
          final timeB = DateTime.parse(b['data']['time'] as String);
          return timeB.compareTo(timeA);
        });
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _onRefresh() async {
    await _loadNotifications();
  }

  String _formatDateTime(String dateTimeStr) {
    final dateTime = DateTime.parse(dateTimeStr);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference.inDays == 1) {
      return '昨天 ${DateFormat('HH:mm').format(dateTime)}';
    } else {
      return DateFormat('MM-dd HH:mm').format(dateTime);
    }
  }

  Future<void> _showDeleteConfirmation() async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除通知'),
        content: const Text('是否要清除两天前的通知？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await messageFiles.clearOldNotifications();
      await _loadNotifications();
    }
  }

  void _showNotificationDetail(Map<String, dynamic> notification) {
    showDialog(
      context: context,
      builder: (context) => NotificationDetailDialog(
        notification: notification,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('通知记录'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _showDeleteConfirmation,
            tooltip: '清除旧通知',
          ),
        ],
      ),
      body: _isLoading 
        ? const LoadingState()
        : RefreshIndicator(
            onRefresh: _onRefresh,
            child: NotificationList(
              notifications: notifications,
              onNotificationTap: _showNotificationDetail,
              formatDateTime: _formatDateTime,
            ),
          ),
    );
  }

  @override
  void dispose() {
    _notificationSubscription.cancel();
    super.dispose();
  }
}