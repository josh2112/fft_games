import 'dart:async';

import 'package:defer_pointer/defer_pointer.dart';
import 'package:fft_games/main_menu/settings_dialog.dart';
import 'package:fft_games/utils/dialog_or_bottom_sheet.dart';
import 'package:fft_games/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'board.dart';
import 'board_state.dart';
import 'hand.dart';
import 'settings.dart';
import 'stats_page.dart';

class PlayPage extends StatefulWidget {
  const PlayPage({super.key});

  @override
  State<PlayPage> createState() => _PlayPageState();
}

class _PlayPageState extends State<PlayPage> {
  late final SettingsController settings;
  late final BoardState boardState;
  late final AppLifecycleListener appLifecycleListener;

  @override
  void initState() {
    super.initState();
    appLifecycleListener = AppLifecycleListener(onStateChange: onLifecycleStateChange);
    settings = context.read<SettingsController>();
    boardState = BoardState(_onPlayerWon);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await boardState.isLoaded;
      await settings.gameStateDate.isLoaded;
      await settings.gameState.isLoaded;
      await settings.gameStateIsCompleted.isLoaded;
      await settings.gameStateElapsedTime.isLoaded;
      await _maybeApplyBoardState();

      boardState.onBoard.addListener(() {
        settings.gameState.value = boardState.onBoard.dominoes.entries
            .map(
              (e) => SavedDominoPlacement(
                e.value.dx.toInt(),
                e.value.dy.toInt(),
                e.key.side1,
                e.key.side2,
                e.key.quarterTurns.value,
              ),
            )
            .toList();
        settings.gameStateDate.value = DateUtils.dateOnly(DateTime.now());
        settings.gameStateIsCompleted.value = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: BackButton(onPressed: () => context.pop()),
      title: Text('Fosteroes'),
      centerTitle: true,
      actions: [
        ValueListenableBuilder(
          valueListenable: boardState.elapsedTimeSecs,
          builder: (context, value, child) => Text(Duration(seconds: value).formatHHMMSS()),
        ),
        IconButton(
          icon: Icon(Icons.info),
          onPressed: () => {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Hey!'),
                content: SingleChildScrollView(
                  child: ListBody(
                    children: [
                      Text("You are playing a beta version of Fosteroes.\n"),
                      Text("Coming soon:"),
                      Text("• Daily puzzles"),
                      Text("• Stats tracking"),
                      Text("• ...more?"),
                    ],
                  ),
                ),
                actions: [TextButton(onPressed: () => context.pop(), child: const Text('OK'))],
              ),
            ),
          },
        ),
        IconButton(icon: Icon(Icons.settings), onPressed: () => showDialogOrBottomSheet(context, SettingsDialog())),
      ],
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
                    child: ValueListenableBuilder(
                      valueListenable: boardState.isInProgress,
                      builder: (context, inProgress, child) => IgnorePointer(
                        ignoring: !inProgress,
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
      ),
    ),
  );

  void _onPlayerWon() {
    settings.gameStateElapsedTime.value = boardState.elapsedTimeSecs.value;
    settings.gameStateIsCompleted.value = true;
    settings.numWon.value += 1;
    settings.currentStreak.value += 1;
    if (settings.currentStreak.value > settings.maxStreak.value) {
      settings.maxStreak.value = settings.currentStreak.value;
    }

    context.go('/fosteroes/stats', extra: StatsPageWinLoseData());
  }

  Future _maybeApplyBoardState() async {
    final today = DateUtils.dateOnly(DateTime.now());

    if (settings.gameStateDate.value != today) {
      // If the last saved-game state is for a different day, reset everything
      settings.numPlayed.value += 1;
      settings.gameStateDate.value = today;
      settings.gameStateIsCompleted.value = true;
      settings.gameStateElapsedTime.value = 0;
    } else {
      await boardState.applyGameState(
        settings.gameState.value,
        settings.gameStateElapsedTime.value,
        settings.gameStateIsCompleted.value,
      );

      if (settings.gameStateIsCompleted.value && mounted) {
        context.go('/fosteroes/stats', extra: StatsPageWinLoseData());
      }
    }
  }

  void onLifecycleStateChange(AppLifecycleState state) {
    boardState.isPaused = state != AppLifecycleState.resumed;
    if (boardState.isPaused) {
      settings.gameStateElapsedTime.value = boardState.elapsedTimeSecs.value;
    }
  }
}
