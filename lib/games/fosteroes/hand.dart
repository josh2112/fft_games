import 'package:fft_games/games/fosteroes/domino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'board_state.dart';

class Hand extends StatefulWidget {
  const Hand({super.key});

  @override
  State<Hand> createState() => _HandState();
}

class _HandState extends State<Hand> {
  @override
  Widget build(BuildContext context) {
    final boardState = context.watch<BoardState>();

    return Wrap(
      spacing: 20,
      runSpacing: 20,
      children: [for (final d in boardState.hand) Domino(d)],
    );
  }
}
