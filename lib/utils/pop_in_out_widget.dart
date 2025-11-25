import 'package:flutter/material.dart';

class PopInOutWidget extends StatefulWidget {
  final Widget child;

  const PopInOutWidget(this.child, {super.key});

  @override
  State<PopInOutWidget> createState() => _PopInOutWidgetState();
}

class _PopInOutWidgetState extends State<PopInOutWidget> {
  double scale = 0.1;
  double opacity = 0.0;
  Duration duration = Duration(milliseconds: 150);

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        scale = 1.0;
        opacity = 1.0;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) => AnimatedScale(
    scale: scale,
    duration: duration,
    curve: Curves.fastOutSlowIn,
    child: AnimatedOpacity(opacity: opacity, duration: duration, curve: Curves.fastOutSlowIn, child: widget.child),
  );
}
