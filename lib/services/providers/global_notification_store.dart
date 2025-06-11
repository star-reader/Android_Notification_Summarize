import 'package:flutter/material.dart';
import '../../models/notifications_model.dart';

class NotificationStore extends ChangeNotifier {
  final NotificationListModel _notificationList = NotificationListModel();

  NotificationListModel get notificationList => _notificationList;

  void addNotification(NotificationItemModel notification) {
    _notificationList.notificationList.add({
      'packagename': notification.packageName,
      'data': notification,
    });
  }

  void removeNotification(String packageName) {
    _notificationList.notificationList.removeWhere((element) => element['packagename'] == packageName);
  }

  void clearAllNotifications() {
    _notificationList.notificationList.clear();
  }

}