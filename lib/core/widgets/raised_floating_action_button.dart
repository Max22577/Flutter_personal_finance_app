import 'package:flutter/material.dart';

class RaisedFloatingActionButtonLocation extends FloatingActionButtonLocation {
  const RaisedFloatingActionButtonLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    // Standard center horizontal position
    final double x = (scaffoldGeometry.scaffoldSize.width - scaffoldGeometry.floatingActionButtonSize.width) / 2;
    
    // Position it above the bottom navbar (adjust -90 as needed based on your navbar height)
    final double y = scaffoldGeometry.scaffoldSize.height - scaffoldGeometry.floatingActionButtonSize.height - 115;
    
    return Offset(x, y);
  }
}