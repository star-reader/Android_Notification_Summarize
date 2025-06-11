import 'package:dio/dio.dart';
import '../../main.dart';
import '../../configs/private/config_store.dart';

class FetchToken {

  static Future<String> fetchToken() async {
    try {
      final response = await dio.post(
        '${ConfigStore.apiEndpoint}/auth/token',
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