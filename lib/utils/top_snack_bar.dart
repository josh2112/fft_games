import 'package:flutter/material.dart';

// Shows a snackbar at the top of the screen, by moving up the snackbar to 100
// pixels away from the top of the screen.
void showTopSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).size.height - 100, right: 20, left: 20),
    ),
  );
}
