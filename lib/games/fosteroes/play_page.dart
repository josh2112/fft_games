import 'package:defer_pointer/defer_pointer.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'board.dart';
import 'board_state.dart';
import 'hand.dart';
import 'stats_page.dart';

class PlayPage extends StatefulWidget {
  const PlayPage({super.key});

  @override
  State<PlayPage> createState() => _PlayPageState();
}

class _PlayPageState extends State<PlayPage> {
  late final BoardState boardState;

  @override
  void initState() {
    super.initState();
    boardState = BoardState(_onPlayerWon);
  }

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
                    child: DeferredPointerHandler(
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
    ),
  );

  void _onPlayerWon() => context.go('/fosteroes/stats', extra: StatsPageWinLoseData());
}
