import 'package:flutter/material.dart';

class NavigationProvider extends ChangeNotifier {
  int _selectedIndex = 0;
  final Map<int, List<Widget>> _pageActions = {};
  
  final List<String> _pageTitlesKeys = ["dashboard", "transactions", "budgeting", "profile"];

  int get selectedIndex => _selectedIndex;

  List<Widget> get currentActions => _pageActions[_selectedIndex] ?? [];
  String get currentTitle => _pageTitlesKeys[_selectedIndex];
  
  bool get isCurrentPageOverGradient => _selectedIndex == 0;

  void setPage(int index) {
    if (_selectedIndex == index) return;
    _selectedIndex = index;
    notifyListeners();
  }

  void setActions(int pageIndex, List<Widget> actions) {
    _pageActions[pageIndex] = actions;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
}