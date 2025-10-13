import 'dart:math';

import 'package:flutter/material.dart';

import 'pop_tile.dart';

class FlipTile extends TileAnimation {
  const FlipTile({super.key, required super.oldChild, required super.newChild, super.animationDuration});

  @override
  FlipTileState createState() => FlipTileState();
}

class FlipTileState extends State<FlipTile> with TickerProviderStateMixin {
  late AnimationController animationController;
  late Animation<double> animation;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(duration: widget.animationDuration, vsync: this);

    animation = Tween(begin: 0.0, end: -pi).chain(CurveTween(curve: Curves.easeInOut)).animate(animationController);

    WidgetsBinding.instance.addPostFrameCallback((_) => animationController.forward(from: 0));
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animationController,
    builder: (context, child) {
      double angle = animation.value;

      var tilt = ((animationController.value - 0.5).abs() - 0.5) * -0.003;

      final transform = Matrix4.rotationX(angle)..setEntry(3, 1, tilt);

      return Transform(
        alignment: Alignment.center,
        transform: transform,
        child: animationController.value < 0.5
            ? widget.oldChild
            : Transform(transform: Matrix4.rotationX(pi), alignment: Alignment.center, child: widget.newChild),
      );
    },
  );
}
