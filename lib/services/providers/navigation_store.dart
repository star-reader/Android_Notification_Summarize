import 'package:flutter/material.dart';

class NavigationStore extends ChangeNotifier {
  int currentPageIndex = 0;

  void setCurrentPageIndex(int index) {
    currentPageIndex = index;
    notifyListeners();
  }
}