import 'package:fft_games/games/fosteroes/board.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'board_state.dart';
import 'hand.dart';

class PlayPage extends StatefulWidget {
  const PlayPage({super.key});

  @override
  State<PlayPage> createState() => _PlayPageState();
}

class _PlayPageState extends State<PlayPage> {
  late final BoardState boardState = BoardState();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: BackButton(onPressed: () => context.pop()),
      title: Text('Fosteroes'),
      centerTitle: true,
    ),
    body: Provider.value(
      value: boardState,
      builder: (context, child) => Center(
        child: ValueListenableBuilder(
          valueListenable: boardState.puzzle,
          builder: (context, puzzle, child) => puzzle == null
              ? CircularProgressIndicator()
              : ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 600),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      spacing: 10,
                      children: [
                        Expanded(
                          child: FittedBox(fit: BoxFit.contain, child: Board()),
                        ),
                        Divider(),
                        Hand(),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    ),
  );
}
