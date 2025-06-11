import 'package:flutter/material.dart';

class TokenStore extends ChangeNotifier {
  String token = '';

  void setToken(String token) {
    this.token = token;
    notifyListeners();
  }
}