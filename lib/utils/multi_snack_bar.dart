import 'dart:developer';

import 'package:flutter/material.dart';

class MultiSnackBarMessage {
  final String message;
  bool visible = true;

  MultiSnackBarMessage(this.message);
}

class MultiSnackBarMessenger with ChangeNotifier {
  final List<MultiSnackBarMessage> _items = [];

  void showSnackBar(String message, {Duration timeout = const Duration(milliseconds: 1500)}) {
    var item = MultiSnackBarMessage(message);
    _items.add(item);
    notifyListeners();

    Future.delayed(timeout, () {
      item.visible = false;
      notifyListeners();
    });
  }

  void _sweep() {
    _items.removeWhere((m) => !m.visible);
    notifyListeners();
  }
}

class MultiSnackBar extends StatefulWidget {
  final MultiSnackBarMessenger messenger;

  const MultiSnackBar({required this.messenger, super.key});

  @override
  State<MultiSnackBar> createState() => _MultiSnackBarState();
}

class _MultiSnackBarState extends State<MultiSnackBar> {
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.messenger,
    builder: (context, child) => Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 10,
        children: [for (final msg in widget.messenger._items) snackbar(msg)],
      ),
    ),
  );

  Widget snackbar(MultiSnackBarMessage msg) {
    final theme = Theme.of(context);
    return AnimatedOpacity(
      opacity: msg.visible ? 1.0 : 0.0,
      duration: Duration(milliseconds: 200),
      onEnd: !msg.visible ? () => widget.messenger._sweep() : null,
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(color: theme.colorScheme.inverseSurface, borderRadius: BorderRadius.circular(10)),
        child: Text(
          msg.message,
          style: theme.textTheme.bodyMedium!.copyWith(color: theme.colorScheme.onInverseSurface),
        ),
      ),
    );
  }
}
