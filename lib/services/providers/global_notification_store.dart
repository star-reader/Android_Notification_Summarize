import 'package:flutter/material.dart';
import '../../models/notifications_model.dart';

class NotificationStore extends ChangeNotifier {
  // 单例模式实现
  static final NotificationStore _instance = NotificationStore._internal();
  factory NotificationStore() => _instance;
  NotificationStore._internal();

  final NotificationListModel _notificationList = NotificationListModel();
  
  List<Map<String, dynamic>> get notificationList => _notificationList.notificationList;

  // 修复 getNotificationsByPackageName 方法
  List<NotificationItemModel> getNotificationsByPackageName(String packageName) {
    final matchingPackages = _notificationList.notificationList
        .where((n) => n['packageName'] == packageName)
        .toList();
    
    if (matchingPackages.isEmpty) return [];
    
    // 因为data现在是一个List
    return (matchingPackages.first['data'] as List).cast<NotificationItemModel>();
  }

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
    var existingPackage = _notificationList.notificationList
        .firstWhere(
          (element) => element['packageName'] == packageName,
          orElse: () => {
            'packageName': packageName,
            'data': <NotificationItemModel>[],
          },
        );

    if (!_notificationList.notificationList.contains(existingPackage)) {
      _notificationList.notificationList.add(existingPackage);
    }

    (existingPackage['data'] as List<NotificationItemModel>).add(notification);
    notifyListeners(); // 通知监听器数据已更新
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