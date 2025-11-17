import 'package:flutter/material.dart';

Future showDialogOrBottomSheet(BuildContext context, Widget widget) async {
  if (MediaQuery.of(context).size.width < 500) {
    await showModalBottomSheet(context: context, builder: (context) => widget);
  } else {
    await showDialog(
      context: context,
      builder: (c) => Dialog(child: widget),
    );
  }
}
