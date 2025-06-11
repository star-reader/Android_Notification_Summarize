import 'package:crypto/crypto.dart';
import 'dart:convert';

String calculateSHA256(String input) {
  // 将输入字符串转换为字节
  var bytes = utf8.encode(input);
  // 计算SHA256哈希
  var digest = sha256.convert(bytes);
  // 返回十六进制字符串
  return digest.toString();
}
