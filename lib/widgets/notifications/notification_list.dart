import 'package:flutter/material.dart';
import 'notification_list_item.dart';
import 'empty_notification_state.dart';

class NotificationList extends StatelessWidget {
  final List<Map<String, dynamic>> notifications;
  final Function(Map<String, dynamic>) onNotificationTap;
  final String Function(String) formatDateTime;

  const NotificationList({
    super.key,
    required this.notifications,
    required this.onNotificationTap,
    required this.formatDateTime,
  });

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) {
      return const EmptyNotificationState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        final DateTime notificationTime = DateTime.parse(
          notification['data']['time'] as String,
        );

        // 添加日期分隔符
        Widget? dateHeader;
        if (index == 0 || _shouldShowDateHeader(notifications[index - 1], notification)) {
          dateHeader = _buildDateHeader(context, notificationTime);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (dateHeader != null) dateHeader,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                elevation: 1,
                margin: const EdgeInsets.symmetric(vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: NotificationListItem(
                  notification: notification,
                  formattedTime: formatDateTime(notification['data']['time'] as String),
                  onTap: () => onNotificationTap(notification),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  bool _shouldShowDateHeader(Map<String, dynamic> previous, Map<String, dynamic> current) {
    final DateTime previousDate = DateTime.parse(previous['data']['time'] as String);
    final DateTime currentDate = DateTime.parse(current['data']['time'] as String);
    return !_isSameDay(previousDate, currentDate);
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  Widget _buildDateHeader(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    String dateText;

    if (_isSameDay(date, now)) {
      dateText = '今天';
    } else if (_isSameDay(date, yesterday)) {
      dateText = '昨天';
    } else {
      dateText = '${date.month}月${date.day}日';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        dateText,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Colors.grey[700],
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
} 