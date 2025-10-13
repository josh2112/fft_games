import 'dart:math';

import 'package:flutter/material.dart';

// Shows a snackbar at the top of the screen, by moving up the snackbar to 100
// pixels away from the top of the screen.
void showTopSnackBar(BuildContext context, String message, {int topMargin = 100, int maxWidth = 500}) {
  final pageSize = MediaQuery.sizeOf(context);
  final sideMargin = max((pageSize.width - maxWidth) / 2, 0.0);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: EdgeInsets.only(bottom: pageSize.height - topMargin, right: sideMargin, left: sideMargin),
    ),
  );
}
