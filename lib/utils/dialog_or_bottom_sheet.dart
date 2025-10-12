import 'package:flutter/material.dart';

void showDialogOrBottomSheet(BuildContext context, Widget widget) {
  if (MediaQuery.of(context).size.width < 500) {
    Scaffold.of(context).showBottomSheet((c) => widget);
  } else {
    showDialog(
      context: context,
      builder: (c) => Dialog(child: widget),
    );
  }
}
