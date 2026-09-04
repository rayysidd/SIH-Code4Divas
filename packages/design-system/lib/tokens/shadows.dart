import 'package:flutter/material.dart';

class LabelLensShadows {
  static const List<BoxShadow> elev0 = [];
  
  static const List<BoxShadow> elev1 = [
    BoxShadow(
      color: Color(0x14000000), // rgba(0,0,0,0.08)
      offset: Offset(0, 1),
      blurRadius: 3,
    )
  ];
  
  static const List<BoxShadow> elev2 = [
    BoxShadow(
      color: Color(0x1A000000), // rgba(0,0,0,0.10)
      offset: Offset(0, 4),
      blurRadius: 12,
    )
  ];
  
  static const List<BoxShadow> elev3 = [
    BoxShadow(
      color: Color(0x24000000), // rgba(0,0,0,0.14)
      offset: Offset(0, 8),
      blurRadius: 24,
    )
  ];
  
  static const List<BoxShadow> elev4 = [
    BoxShadow(
      color: Color(0x33000000), // rgba(0,0,0,0.20)
      offset: Offset(0, 16),
      blurRadius: 48,
    )
  ];
}
