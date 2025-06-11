import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../models/notifications_model.dart';

class MessageFiles {
  static const String _fileName = 'msg.db';
  static const String _folderName = 'msg';
  
  // 获取消息文件路径
  Future<String> _getMessageFilePath() async {
    Directory appDir;
    
    if (Platform.isAndroid) {
      // Android平台使用应用程序包目录
      appDir = await getApplicationDocumentsDirectory();
    } else if (Platform.isWindows) {
      // Windows平台使用AppData/Roaming目录
      appDir = await getApplicationSupportDirectory();
    } else {
      // 其他平台默认使用应用文档目录
      appDir = await getApplicationDocumentsDirectory();
    }
    
    // 创建msg文件夹
    final msgDir = Directory(path.join(appDir.path, _folderName));
    if (!await msgDir.exists()) {
      await msgDir.create(recursive: true);
    }
    
    return path.join(msgDir.path, _fileName);
  }
  
  // 合并通知数据
  NotificationListModel _mergeNotifications(NotificationListModel existingData, NotificationListModel newData) {
    NotificationListModel mergedModel = NotificationListModel();
    
    // 创建一个Map来存储已有的packageName数据
    Map<String, List<Map<String, dynamic>>> packageMap = {};
    
    // 处理现有数据
    for (var item in existingData.notificationList) {
      String packageName = item['packageName'] as String;
      if (!packageMap.containsKey(packageName)) {
        packageMap[packageName] = [];
      }
      // 确保 data 是 Map<String, dynamic> 格式
      Map<String, dynamic> dataMap = (item['data'] is NotificationItemModel) 
          ? (item['data'] as NotificationItemModel).toJson()
          : (item['data'] as Map<String, dynamic>);
      packageMap[packageName]!.add(dataMap);
    }
    
    // 合并新数据
    for (var item in newData.notificationList) {
      String packageName = item['packageName'] as String;
      if (!packageMap.containsKey(packageName)) {
        packageMap[packageName] = [];
      }
      // 确保 data 是 Map<String, dynamic> 格式
      Map<String, dynamic> dataMap = (item['data'] is NotificationItemModel) 
          ? (item['data'] as NotificationItemModel).toJson()
          : (item['data'] as Map<String, dynamic>);
      packageMap[packageName]!.add(dataMap);
    }
    
    // 转换回列表格式
    for (var entry in packageMap.entries) {
      for (var data in entry.value) {
        mergedModel.notificationList.add({
          'packageName': entry.key,
          'data': data,
        });
      }
    }
    
    return mergedModel;
  }
  
  // 写入通知数据（合并模式）
  Future<void> writeNotifications(NotificationListModel notifications) async {
    try {
      print('进入写入数据的函数');
      final filePath = await _getMessageFilePath();
      final file = File(filePath);
      
      NotificationListModel existingData = NotificationListModel();
      
      // 如果文件存在，先读取现有数据
      if (await file.exists()) {
        String content = await file.readAsString();
        if (content.isNotEmpty) {
          Map<String, dynamic> jsonData = json.decode(content);
          existingData.notificationList = List<Map<String, dynamic>>.from(
            (jsonData['notificationList'] as List).map((item) => {
              'packageName': item['packageName'],
              'data': item['data'],
            })
          );
        }
      }
      
      // 准备新数据，确保所有 NotificationItemModel 都转换为 Map
      NotificationListModel preparedNotifications = NotificationListModel();
      for (var item in notifications.notificationList) {
        preparedNotifications.notificationList.add({
          'packageName': item['packageName'],
          'data': (item['data'] is NotificationItemModel) 
              ? (item['data'] as NotificationItemModel).toJson()
              : item['data'],
        });
      }
      
      // 合并数据
      NotificationListModel mergedData = _mergeNotifications(existingData, preparedNotifications);
      
      // 转换为JSON并写入文件
      final jsonString = json.encode({
        'notificationList': mergedData.notificationList,
      });
      
      await file.writeAsString(jsonString);
      print('写入通知数据成功');
    } catch (e) {
      print('写入错误详情: $e');
      throw Exception('写入通知数据失败: $e');
    }
  }
  
  // 读取通知数据
  Future<NotificationListModel> readNotifications() async {
    try {
      final filePath = await _getMessageFilePath();
      final file = File(filePath);
      
      // 如果文件不存在或为空，返回空模型
      if (!await file.exists()) {
        return NotificationListModel();
      }
      
      String content = await file.readAsString();
      if (content.isEmpty) {
        return NotificationListModel();
      }
      
      // 解析JSON数据
      Map<String, dynamic> jsonData = json.decode(content);
      NotificationListModel model = NotificationListModel();
      model.notificationList = List<Map<String, dynamic>>.from(
        (jsonData['notificationList'] as List).map((item) => {
          'packageName': item['packageName'],
          'data': item['data'],
        })
      );
      
      return model;
    } catch (e) {
      throw Exception('读取通知数据失败: $e');
    }
  }
  
  // 清空通知数据
  Future<void> clearNotifications() async {
    try {
      final filePath = await _getMessageFilePath();
      final file = File(filePath);
      
      if (await file.exists()) {
        await file.writeAsString(json.encode({
          'notificationList': [],
        }));
      }
    } catch (e) {
      throw Exception('清空通知数据失败: $e');
    }
  }
  
  // 删除数据库文件
  Future<void> deleteDatabase() async {
    try {
      final filePath = await _getMessageFilePath();
      final file = File(filePath);
      
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('删除数据库文件失败: $e');
    }
  }
  
  // 获取数据库文件大小（以字节为单位）
  Future<int> getDatabaseSize() async {
    try {
      final filePath = await _getMessageFilePath();
      final file = File(filePath);
      
      if (!await file.exists()) {
        return 0;
      }
      
      return await file.length();
    } catch (e) {
      throw Exception('获取数据库大小失败: $e');
    }
  }
  
  // 检查数据库文件是否存在
  Future<bool> databaseExists() async {
    try {
      final filePath = await _getMessageFilePath();
      return await File(filePath).exists();
    } catch (e) {
      return false;
    }
  }
}