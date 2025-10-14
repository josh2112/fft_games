import 'package:flutter/material.dart';

class PopTile extends StatefulWidget {
  final Widget child;
  final Duration animationDuration;

  const PopTile({super.key, required this.child, this.animationDuration = const Duration(milliseconds: 500)});

  @override
  PopTileState createState() => PopTileState();
}

class PopTileState extends State<PopTile> with TickerProviderStateMixin {
  late AnimationController animationController;
  late Animation<double> animation;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(duration: widget.animationDuration, vsync: this);

    // 1.0 -> 1.2 -> 1.0
    animation = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2).chain(CurveTween(curve: Curves.easeInOut)), weight: 50.0),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 50.0),
    ]).animate(animationController);

    WidgetsBinding.instance.addPostFrameCallback((_) => animationController.forward());
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animationController,
    builder: (context, child) =>
        Transform.scale(scale: animation.value, alignment: Alignment.center, child: widget.child),
  );
}
