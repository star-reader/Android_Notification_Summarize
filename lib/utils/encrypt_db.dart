import 'dart:convert';
import 'package:encrypt/encrypt.dart';
import '../configs/private/key_store.dart';

class EncryptionUtils {
  static final key = Key.fromUtf8(KeyStore.key);
  static final iv = IV.fromUtf8(KeyStore.iv);
  static final encrypter = Encrypter(AES(key));

  /// 加密对象或字符串
  static String encrypt(dynamic data) {
    try {
      // 如果是对象，先转换成 JSON 字符串
      final String stringData = data is String ? data : json.encode(data);
      
      // 加密
      final encrypted = encrypter.encrypt(stringData, iv: iv);
      
      // 返回 base64 编码的加密字符串
      return encrypted.base64;
    } catch (e) {
      throw Exception('加密失败: $e');
    }
  }

  /// 解密字符串并转换为对象
  static T decrypt<T>(String encryptedString, T Function(Map<String, dynamic>) fromJson) {
    try {
      // 解密
      final decrypted = encrypter.decrypt64(encryptedString, iv: iv);
      
      // 解析 JSON
      final Map<String, dynamic> jsonMap = json.decode(decrypted);
      
      // 使用传入的 fromJson 函数转换为对象
      return fromJson(jsonMap);
    } catch (e) {
      throw Exception('解密失败: $e');
    }
  }

  /// 解密字符串（如果原数据就是字符串）
  static String decryptString(String encryptedString) {
    try {
      return encrypter.decrypt64(encryptedString, iv: iv);
    } catch (e) {
      throw Exception('解密失败: $e');
    }
  }
}