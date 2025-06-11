import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';

class EncryptionUtils {
  static const String _keyStorageKey = '';
  static const String _defaultKey = '';
  static final _storage = FlutterSecureStorage();
  
  // 私有构造函数
  EncryptionUtils._();

  /// 初始化加密密钥
  static Future<void> initialize() async {
    // 检查是否已经存储了密钥
    String? storedKey = await _storage.read(key: _keyStorageKey);
    if (storedKey == null) {
      // 如果没有存储密钥，存储默认密钥
      await _storage.write(key: _keyStorageKey, value: _defaultKey);
    }
  }

  /// 更新加密密钥
  static Future<void> updateKey(String newKey) async {
    await _storage.write(key: _keyStorageKey, value: newKey);
  }

  /// 获取加密器实例
  static Future<Encrypter> _getEncrypter() async {
    final keyString = await _storage.read(key: _keyStorageKey) ?? _defaultKey;
    
    // 使用 SHA256 处理密钥字符串
    final keyBytes = sha256.convert(utf8.encode(keyString)).bytes;
    final key = Key(Uint8List.fromList(keyBytes));
    
    return Encrypter(AES(key));
  }

  /// 加密对象或字符串
  static Future<String> encrypt(dynamic data) async {
    try {
      final encrypter = await _getEncrypter();
      final iv = IV.fromLength(16);
      
      // 转换数据为字符串
      final String stringData = data is String ? data : json.encode(data);
      
      // 加密
      final encrypted = encrypter.encrypt(stringData, iv: iv);
      
      return encrypted.base64;
    } catch (e) {
      throw Exception('加密失败: $e');
    }
  }

  /// 解密字符串并转换为对象
  static Future<T> decrypt<T>(String encryptedString, T Function(Map<String, dynamic>) fromJson) async {
    try {
      final encrypter = await _getEncrypter();
      final iv = IV.fromLength(16);
      
      // 解密
      final decrypted = encrypter.decrypt64(encryptedString, iv: iv);
      
      // 解析 JSON
      final Map<String, dynamic> jsonMap = json.decode(decrypted);
      
      return fromJson(jsonMap);
    } catch (e) {
      throw Exception('解密失败: $e');
    }
  }

  /// 解密字符串
  static Future<String> decryptString(String encryptedString) async {
    try {
      final encrypter = await _getEncrypter();
      final iv = IV.fromLength(16);
      
      return encrypter.decrypt64(encryptedString, iv: iv);
    } catch (e) {
      throw Exception('解密失败: $e');
    }
  }

  /// 检查密钥是否已经初始化
  static Future<bool> isInitialized() async {
    return await _storage.read(key: _keyStorageKey) != null;
  }

  /// 删除密钥（如果需要重置）
  static Future<void> resetKey() async {
    await _storage.delete(key: _keyStorageKey);
  }
}