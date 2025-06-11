import 'package:notification_listener_service/notification_listener_service.dart';
import '../../models/notifications_model.dart';
import '../../services/providers/global_notification_store.dart';
import '../../services/files/message_files.dart';
import '../random_uuid.dart';

class NotificationsListener {
  void startListening() async {
    try {
      // 检查当前权限状态
      final bool status = await NotificationListenerService.isPermissionGranted();

      MessageFiles messageFiles = MessageFiles();

      if (!status) {
        await NotificationListenerService.requestPermission();
        final bool newStatus = await NotificationListenerService.isPermissionGranted();
        if (!newStatus) {
          return;
        }
      }

      NotificationListenerService.notificationsStream.listen((event) {
        if (event.title == null ||
            event.content == null ||
            event.packageName == null) {
          return;
        }
        // @deprecated 不使用eventbus
        // 使用store将拦截的通知储存，然后调用通知分析和摘要的
        // 通知一共三份：临时的数据NotificationStore、存到本地数据库的、通知临时摘要数据库（不确定要不要存到本地）
        // todo 通知分析摘要在这里引用
        // todo 保存通知数据到本地数据库
        NotificationItemModel notificationItemModel = NotificationItemModel(
          title: event.title,
          content: event.content,
          packageName: event.packageName,
          id: event.id?.toString() ?? '0',
          uuid: RandomUuid.generateRandomString(16),
          time: DateTime.now().toString(),
        );
        // 临时储存用来做通知分析和摘要的
        NotificationStore().addNotificationByPackageName(event.packageName ?? '', notificationItemModel);
        // 存到本地数据库
        NotificationListModel tempNotificationListModel = NotificationListModel();
        tempNotificationListModel.notificationList.add({
          'packageName': event.packageName ?? '',
          'data': notificationItemModel,
        });
        // 写入本地数据库
        messageFiles.writeNotifications(tempNotificationListModel);
      }, onError: (_) {});
    } catch (_) {}
  }
}
