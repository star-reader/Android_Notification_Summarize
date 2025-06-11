// 单个通知的内容
class NotificationItemModel {
  String? title;
  String? content;
  String? packageName;
  String? id;
  bool? hasRemoved;
  int? time;
}

// 主要存储的通知列表
class NotificationListModel {
  // {packageName: '', data: {}}
  List<Map<String, dynamic>> notificationList = [];
}

