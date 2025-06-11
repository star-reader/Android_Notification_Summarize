// 单个通知的内容
class NotificationItemModel {
  String? title;
  String? content;
  String? packageName;
  String? id;
  String? uuid;
  bool? hasRemoved;
  String? time;

  NotificationItemModel({
    this.title,
    this.content,
    this.packageName,
    this.id,
    this.uuid,
    this.hasRemoved,
    this.time,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'packageName': packageName,
      'id': id,
      'uuid': uuid,
      'hasRemoved': hasRemoved,
      'time': time,
    };
  }

  factory NotificationItemModel.fromJson(Map<String, dynamic> json) {
    return NotificationItemModel(
      title: json['title'],
      content: json['content'],
      packageName: json['packageName'],
      id: json['id'],
      uuid: json['uuid'],
      hasRemoved: json['hasRemoved'],
      time: json['time'],
    );
  }
}

// 主要存储的通知列表
class NotificationListModel {
  // {packageName: '', data: {}}
  List<Map<String, dynamic>> notificationList = [];

  Map<String, dynamic> toJson() {
    return {
      'notificationList': notificationList.map((item) => {
        'packageName': item['packageName'],
        'data': (item['data'] as NotificationItemModel).toJson(),
      }).toList(),
    };
  }

  void fromJson(Map<String, dynamic> json) {
    notificationList = (json['notificationList'] as List).map((item) {
      return {
        'packageName': item['packageName'],
        'data': NotificationItemModel.fromJson(item['data']),
      };
    }).toList();
  }
}

// 通知摘要类型(普通、重要、紧急)
enum NotificationsModel {
  normal,
  important,
  emergency,
}

// 通知摘要的内容
class NotificationSummaryModel {
  String? id;
  List<String>? messageUuid; // 它对应的message的uuid们

}