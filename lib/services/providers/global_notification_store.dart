import 'package:flutter/material.dart';
import '../../models/notifications_model.dart';

class NotificationStore extends ChangeNotifier {
  final NotificationListModel _notificationList = NotificationListModel();

  List<Map<String, dynamic>> get notificationList => _notificationList.notificationList;


  // 添加通知
  @Deprecated('不能这样加通知，否则包名相同的会重复添加，请使用addNotificationByPackageName')
  void addNotification(NotificationItemModel notification) {
    _notificationList.notificationList.add({
      'packageName': notification.packageName,
      'data': notification,
    });
  }

  // 添加通知
  void addNotificationByPackageName(String packageName, NotificationItemModel notification) {
    // 如果list的对应packageName不存在，就调用addNotification， 否则在对应的data下append
    if (_notificationList.notificationList.any((element) => element['packageName'] == packageName)) {
      _notificationList.notificationList.firstWhere((element) => element['packageName'] == packageName)['data'].add(notification);
    } else {
      _notificationList.notificationList.add({
        'packageName': packageName,
        'data': [notification],
      });
    }
  }

  // 删除通知
  void removeNotification(String packageName) {
    _notificationList.notificationList.removeWhere((element) => element['packagename'] == packageName);
  }

  // 清除全部通知
  void clearAllNotifications() {
    _notificationList.notificationList.clear();
  }

}