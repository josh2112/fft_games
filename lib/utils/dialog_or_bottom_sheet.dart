import 'package:flutter/material.dart';

void showDialogOrBottomSheet(BuildContext context, Widget widget) {
  if (MediaQuery.of(context).size.width < 500) {
    showModalBottomSheet(context: context, builder: (context) => widget);
  } else {
    showDialog(
      context: context,
      builder: (c) => Dialog(child: widget),
    );
  }
}
