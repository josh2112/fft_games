import 'package:fft_games/games/fosteroes/board.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PlayPage extends StatefulWidget {
  const PlayPage({super.key});

  @override
  State<PlayPage> createState() => _PlayPageState();
}

class _PlayPageState extends State<PlayPage> {
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: BackButton(onPressed: () => context.pop()),
      title: Text('Fosteroes'),
      centerTitle: true,
    ),
    body: Board(),
  );
}
