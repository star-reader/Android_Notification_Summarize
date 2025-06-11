// 单个通知的内容
class NotificationItemModel {
  String? title;
  String? content;
  String? packageName;
  String? id;
  bool? hasRemoved;
  String? time;

  NotificationItemModel({
    this.title,
    this.content,
    this.packageName,
    this.id,
    this.hasRemoved,
    this.time,
  });
}

// 主要存储的通知列表
class NotificationListModel {
  // {packageName: '', data: {}}
  List<Map<String, dynamic>> notificationList = [];
}

