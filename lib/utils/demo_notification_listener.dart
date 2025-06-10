import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/services.dart';

import 'package:notification_summarize/services/providers/demo_event_bus.dart';

class DemoNotificationListener {
  void startListening() async {
    try {
      print('开始初始化通知监听服务...');
      
      // 检查当前权限状态
      final bool status = await NotificationListenerService.isPermissionGranted();
      print('通知访问权限状态: $status');
      
      if (!status) {
        print('权限未授予，正在请求权限...');
        
        // 在小米手机上，这会打开设置页面让用户手动授权
        await NotificationListenerService.requestPermission();
        
        // 再次检查权限状态
        final bool newStatus = await NotificationListenerService.isPermissionGranted();
        print('权限请求后状态: $newStatus');
        
        if (!newStatus) {
          print('❌ 权限未授予，无法监听通知。请在设置中手动开启通知访问权限。');
          return;
        }
      }
      
      print('✅ 权限已授予，开始监听通知...');
      
      // 开始监听通知
      NotificationListenerService.notificationsStream.listen((event) {
        print("📱 收到新通知: ${event.title} - ${event.content}");
        print("📦 应用包名: ${event.packageName}");

        if (event.title == null || event.content == null) {
          return;
        }
        eventBus.fire(NotificationReceivedEvent(
          title: event.title ?? '无标题',
          content: event.content ?? '无内容',
          packageName: event.packageName ?? '未知应用',
          id: event.id?.toString() ?? '0',
        ));
      }, onError: (error) {
        print('❌ 监听器错误: ${error.toString()}');
      }, onDone: () {
        print('⏹️ 监听器结束');
      });
      
    } catch (exception) {
      print('❌ 监听器异常: ${exception.toString()}');
      
      // 如果是平台异常，可能是权限问题
      if (exception is PlatformException) {
        print('🔧 这可能是权限问题，请确保：');
        print('1. 在设置 > 应用管理 > ${exception.code} > 权限管理中开启所有必要权限');
        print('2. 在设置 > 特殊权限 > 通知访问权限中开启此应用');
        print('3. 关闭电池优化（设置 > 电池 > 应用电池管理）');
      }
    }
  }
}