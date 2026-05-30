import 'package:flutter/material.dart';

class NavigationProvider extends ChangeNotifier {
  int _selectedIndex = 0;
  List<Widget> _currentActions = [];
  
  
  final List<String> _pageTitlesKeys = ["dashboard", "transactions", "budgeting", "profile"];

  int get selectedIndex => _selectedIndex;
  List<Widget> get currentActions => _currentActions;
  String get currentTitle => _pageTitlesKeys[_selectedIndex];
  bool get isCurrentPageOverGradient => _selectedIndex == 0;

  void setPage(int index) {
    _selectedIndex = index;
    _currentActions = []; // Clear actions on switch
    notifyListeners();
  }

  void setActions(List<Widget> actions) {
    _currentActions = actions;
    notifyListeners();
    
  }
}