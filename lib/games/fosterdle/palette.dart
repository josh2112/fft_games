import 'package:flutter/material.dart';

class Palette {
  Color get letterRightPlace => Color.fromARGB(255, 83, 141, 78);
  Color get letterWrongPlace => Color.fromARGB(255, 181, 159, 59);
  WidgetStateProperty<Color> get keyboardKey => WidgetStateProperty.all<Color>(Colors.grey[600]!);
  WidgetStateProperty<Color> get keyboardKeyNotInWord => WidgetStateProperty.all<Color>(Colors.grey[800]!);
}
