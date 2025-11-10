import 'dart:async';

import 'package:defer_pointer/defer_pointer.dart';
import 'package:fft_games/games/fosteroes/puzzle.dart';
import 'package:fft_games/main_menu/settings_dialog.dart';
import 'package:fft_games/utils/dialog_or_bottom_sheet.dart';
import 'package:fft_games/utils/multi_snack_bar.dart';
import 'package:fft_games/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'board.dart';
import 'board_state.dart';
import 'hand.dart';
import 'settings.dart';
import 'stats_page.dart';

class PlayPageParams {
  final PuzzleType type;
  final PuzzleDifficulty difficulty;

  PlayPageParams(this.type, this.difficulty);
}

class PlayPage extends StatefulWidget {
  final PlayPageParams params;

  PlayPage({PlayPageParams? params, super.key})
    : params = params ?? PlayPageParams(PuzzleType.daily, PuzzleDifficulty.easy);

  @override
  State<PlayPage> createState() => _PlayPageState();
}

class _PlayPageState extends State<PlayPage> {
  late final SettingsController settings;
  late final AppLifecycleListener appLifecycleListener;
  late final MultiSnackBarMessenger messenger;

  late final BoardState boardState;
  late final GameSettingsController gameSettings;

  @override
  void initState() {
    super.initState();

    settings = context.read<SettingsController>();

    appLifecycleListener = AppLifecycleListener(
      onStateChange: (state) => boardState.isPaused.value = state != AppLifecycleState.resumed,
    );

    messenger = MultiSnackBarMessenger();

    boardState = BoardState(_onPlayerWon, _onBadSolution, widget.params.type, widget.params.difficulty);
    boardState.isPaused.addListener(maybeUpdateElapsedTime);

    gameSettings = settings.gameSettings[(boardState.puzzleType, boardState.puzzleDifficulty)]!;

    gameSettings.waitUntilLoaded().then((_) async {
      await _maybeApplyBoardState();
      boardState.onBoard.addListener(() {
        gameSettings.state.value = boardState.onBoard.dominoes.entries
            .map((e) => SavedDominoPlacement(e.key.id, e.value.x, e.value.y, e.key.quarterTurns.value))
            .toList();
      });
    });
  }

  void maybeUpdateElapsedTime() {
    if (boardState.isPaused.value) {
      gameSettings.elapsedTime.value = boardState.elapsedTimeSecs.value;
    }
  }

  @override
  void deactivate() {
    gameSettings.elapsedTime.value = boardState.elapsedTimeSecs.value;
    super.deactivate();
  }

  @override
  void dispose() {
    boardState.isPaused.removeListener(maybeUpdateElapsedTime);
    boardState.dispose();

    appLifecycleListener.dispose();
    messenger.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: BackButton(onPressed: () => context.pop()),
      title: Text('Fosteroes'),
      centerTitle: true,
      actions: [
        TextButton(onPressed: boardState.clearBoard, child: Text("Clear")),
        IconButton(icon: Icon(Icons.settings), onPressed: () => showDialogOrBottomSheet(context, SettingsDialog())),
      ],
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(18.0),
        child: Padding(
          padding: EdgeInsetsGeometry.only(left: 20, right: 10),
          child: Row(
            children: [
              Text(
                "${boardState.puzzleType == PuzzleType.daily ? DateFormat.yMMMMd().format(DateTime.now()) : "Autogen"} - ${toBeginningOfSentenceCase(boardState.puzzleDifficulty.name)}",
                style: TextTheme.of(context).bodyMedium,
              ),
              Spacer(),
              Opacity(
                opacity: 0.5,
                child: Padding(
                  padding: EdgeInsetsGeometry.only(right: 5),
                  child: ValueListenableBuilder(
                    valueListenable: boardState.isPaused,
                    builder: (context, isPaused, child) =>
                        isPaused && boardState.isInProgress.value ? Icon(Icons.pause) : SizedBox(),
                  ),
                ),
              ),

              ValueListenableBuilder(
                valueListenable: boardState.elapsedTimeSecs,
                builder: (context, value, child) =>
                    Text(Duration(seconds: value).formatHHMMSS(), style: TextTheme.of(context).bodyMedium),
              ),
            ],
          ),
        ),
      ),
    ),
    body: Stack(
      children: [
        Provider.value(
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
        MultiSnackBar(messenger: messenger),
      ],
    ),
  );

  void _onPlayerWon() {
    gameSettings.elapsedTime.value = boardState.elapsedTimeSecs.value;
    gameSettings.isCompleted.value = true;
    settings.numWon.value += 1;
    settings.currentStreak.value += 1;
    if (settings.currentStreak.value > settings.maxStreak.value) {
      settings.maxStreak.value = settings.currentStreak.value;
    }

    showStats(true);
  }

  void _onBadSolution() => messenger.showSnackBar("So close!");

  Future _maybeApplyBoardState() async {
    // Different algorithms depending on game type. Daily games reset only once a day, and we don't care about the
    // seed (the date is the seed). Autogen games reset after they have been completed.
    if (boardState.puzzleType == PuzzleType.daily) {
      boardState.makePuzzle();

      final today = DateUtils.dateOnly(DateTime.now());

      if (gameSettings.date.value != today) {
        // If the last saved-game state is for a different day, reset everything
        gameSettings.date.value = today;
        gameSettings.isCompleted.value = false;
        gameSettings.elapsedTime.value = 0;
        //settings.numPlayed.value += 1;
      } else {
        messenger.showSnackBar("Continuing from earlier");
        await boardState.applyGameState(
          gameSettings.state.value,
          gameSettings.elapsedTime.value,
          gameSettings.isCompleted.value,
        );
      }
    } else {
      // Autogen

      if (gameSettings.isCompleted.value) {
        // If the saved game has been completed, start over
        gameSettings.isCompleted.value = false;
        gameSettings.elapsedTime.value = 0;
        gameSettings.seed.value = boardState.makePuzzle(null);
        //settings.numPlayed.value += 1;
      } else {
        boardState.makePuzzle(gameSettings.seed.value);

        messenger.showSnackBar("Continuing from earlier");
        await boardState.applyGameState(
          gameSettings.state.value,
          gameSettings.elapsedTime.value,
          gameSettings.isCompleted.value,
        );
      }
    }

    if (gameSettings.isCompleted.value && mounted) {
      showStats(true);
    }
  }

  void showStats(bool won) {
    context.go(
      '/fosteroes/stats',
      extra: StatsPageParams(
        boardState.puzzleType,
        boardState.puzzleDifficulty,
        Duration(seconds: boardState.elapsedTimeSecs.value),
      ),
    );
  }
}
