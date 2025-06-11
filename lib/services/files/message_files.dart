import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../models/notifications_model.dart';
import '../../utils/encrypt_db.dart';

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
  
  // 写入通知数据（加密后写入）
  Future<void> writeNotifications(NotificationListModel notifications) async {
    try {
      print('进入写入数据的函数');
      final filePath = await _getMessageFilePath();
      final file = File(filePath);
      
      NotificationListModel existingData = NotificationListModel();
      
      // 如果文件存在，先读取并解密现有数据
      if (await file.exists()) {
        String encryptedContent = await file.readAsString();
        if (encryptedContent.isNotEmpty) {
          // 使用 EncryptionUtils 解密
          String decryptedContent = EncryptionUtils.decryptString(encryptedContent);
          Map<String, dynamic> jsonData = json.decode(decryptedContent);
          existingData.notificationList = List<Map<String, dynamic>>.from(
            (jsonData['notificationList'] as List).map((item) => {
              'packageName': item['packageName'],
              'data': item['data'],
            })
          );
        }
      }
      
      // 准备新数据
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
      
      // 转换为JSON，然后使用 EncryptionUtils 加密
      final jsonString = json.encode({
        'notificationList': mergedData.notificationList,
      });
      
      final encryptedData = EncryptionUtils.encrypt(jsonString);
      
      // 写入加密后的数据
      await file.writeAsString(encryptedData);
      print('写入加密数据成功');
    } catch (e) {
      print('写入错误详情: $e');
      throw Exception('写入通知数据失败: $e');
    }
  }
  
  // 读取通知数据（读取后解密）
  Future<NotificationListModel> readNotifications() async {
    try {
      final filePath = await _getMessageFilePath();
      final file = File(filePath);
      
      // 如果文件不存在或为空，返回空模型
      if (!await file.exists()) {
        return NotificationListModel();
      }
      
      String encryptedContent = await file.readAsString();
      if (encryptedContent.isEmpty) {
        return NotificationListModel();
      }
      
      // 使用 EncryptionUtils 解密
      String decryptedContent = EncryptionUtils.decryptString(encryptedContent);
      
      // 解析JSON数据
      Map<String, dynamic> jsonData = json.decode(decryptedContent);
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
  
  // 清空通知数据（加密空数据）
  Future<void> clearNotifications() async {
    try {
      final filePath = await _getMessageFilePath();
      final file = File(filePath);
      
      if (await file.exists()) {
        final emptyJson = json.encode({
          'notificationList': [],
        });
        // 使用 EncryptionUtils 加密空数据
        final encryptedEmpty = EncryptionUtils.encrypt(emptyJson);
        await file.writeAsString(encryptedEmpty);
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

  // 清除2天前的通知数据
  Future<void> clearOldNotifications() async {
    try {
      final filePath = await _getMessageFilePath();
      final file = File(filePath);
      
      // 如果文件不存在，直接返回
      if (!await file.exists()) {
        return;
      }
      
      // 读取并解密现有数据
      String encryptedContent = await file.readAsString();
      if (encryptedContent.isEmpty) {
        return;
      }
      
      // 解密数据
      String decryptedContent = EncryptionUtils.decryptString(encryptedContent);
      Map<String, dynamic> jsonData = json.decode(decryptedContent);
      
      // 获取2天前的时间
      final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
      
      // 过滤通知列表，只保留2天内的通知
      final List<dynamic> oldList = jsonData['notificationList'] as List;
      final List<Map<String, dynamic>> newList = [];
      
      for (var item in oldList) {
        // 从data中获取时间字符串并解析
        final timeStr = item['data']['time'] as String;
        final notificationTime = DateTime.parse(timeStr);
        
        // 如果通知时间在2天内，保留该通知
        if (notificationTime.isAfter(twoDaysAgo)) {
          newList.add(item as Map<String, dynamic>);
        }
      }
      
      // 创建新的JSON数据
      final newJsonData = {
        'notificationList': newList,
      };
      
      // 加密新数据
      final newEncryptedData = EncryptionUtils.encrypt(json.encode(newJsonData));
      
      // 写入文件
      await file.writeAsString(newEncryptedData);
      
      print('成功清除2天前的通知数据');
    } catch (e) {
      print('清除旧通知数据失败: $e');
      throw Exception('清除旧通知数据失败: $e');
    }
  }

}