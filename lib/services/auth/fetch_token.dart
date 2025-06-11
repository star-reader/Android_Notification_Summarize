import 'dart:io';
import 'package:dio/dio.dart';
import '../../main.dart';

class FetchToken {
  static String get baseUrl {
    // Android 设备/模拟器需要使用特殊地址访问主机
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3390';
    }
    return 'http://localhost:3390';
  }

  static Future<String> fetchToken() async {
    try {
      final response = await dio.post(
        '$baseUrl/auth/token',
        data: {
          'client_id': 'summarize.main.usagi',
          'client_secret': '2T6bC6KmnhuRt',
        },
        options: Options(
          // 禁用代理
          followRedirects: false,
          validateStatus: (status) => true,
          // 设置超时
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      return response.data['token'];
    } catch (e) {
      throw Exception('获取 token 失败: $e');
    }
  }
}