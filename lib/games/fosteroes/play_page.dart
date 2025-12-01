import 'dart:async';

import 'package:defer_pointer/defer_pointer.dart';
import 'package:fft_games/games/fosteroes/puzzle.dart';
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
import 'settings_dialog.dart';
import 'stats_page.dart';

class PlayPageParams {
  final PuzzleType puzzleType;
  final PuzzleDifficulty puzzleDifficulty;

  PlayPageParams(this.puzzleType, this.puzzleDifficulty);
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

    boardState = BoardState(_onPlayerWon, _onBadSolution, widget.params.puzzleDifficulty);
    boardState.isPaused.addListener(maybeUpdateElapsedTime);

    gameSettings = settings.gameSettings[(widget.params.puzzleType, widget.params.puzzleDifficulty)]!;

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

  Future pauseWhile(Future Function() action) async {
    final tmp = boardState.isPaused.value;
    boardState.isPaused.value = true;
    await action();
    boardState.isPaused.value = tmp;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: BackButton(onPressed: () => context.pop()),
      title: Text('Fosteroes'),
      centerTitle: true,
      actions: [
        IconButton(onPressed: showStats, icon: Icon(Icons.bar_chart)),
        IconButton(
          icon: Icon(Icons.settings),
          onPressed: () => pauseWhile(() async => await showDialogOrBottomSheet(context, SettingsDialog(settings))),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(28.0),
        child: Padding(
          padding: EdgeInsetsGeometry.only(left: 20),
          child: Row(
            mainAxisAlignment: .spaceBetween,
            children: [
              ValueListenableBuilder(
                valueListenable: gameSettings.seed,
                builder: (context, seed, child) => Text(
                  "${widget.params.puzzleType == PuzzleType.daily ? DateFormat.yMMMMd().format(DateTime.now()) : "#${gameSettings.seed.value}"} - ${toBeginningOfSentenceCase(boardState.puzzleDifficulty.name)}",
                  style: TextTheme.of(context).bodyMedium,
                ),
              ),
              ValueListenableBuilder(
                valueListenable: settings.showTime,
                builder: (context, showTime, child) => showTime
                    ? ListenableBuilder(
                        listenable: Listenable.merge([boardState.elapsedTimeSecs, boardState.isPaused]),
                        builder: (context, child) => Opacity(
                          opacity: 0.6,
                          child: Padding(
                            padding: EdgeInsetsGeometry.only(left: 15),
                            child: Text(
                              boardState.isPaused.value
                                  ? "Paused"
                                  : Duration(seconds: boardState.elapsedTimeSecs.value).formatHHMMSS(),
                              style: TextTheme.of(context).bodyMedium,
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ),
                      )
                    : SizedBox(),
              ),
              Spacer(),
              TextButton(onPressed: boardState.clearBoard, child: Text("Clear")),
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
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 600),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: ValueListenableBuilder(
                  valueListenable: boardState.puzzle,
                  builder: (context, puzzle, child) => puzzle == null
                      ? CircularProgressIndicator()
                      : ValueListenableBuilder(
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

    final today = DateUtils.dateOnly(DateTime.now());
    if (widget.params.puzzleType == .daily && settings.lastDateDailyWon.value.isBefore(today)) {
      settings.lastDateDailyWon.value = today;
      settings.currentStreak.value += 1;

      if (settings.currentStreak.value > settings.maxStreak.value) {
        settings.maxStreak.value = settings.currentStreak.value;
      }
    }

    showStats(justWon: true);
  }

  void _onBadSolution() => messenger.showSnackBar("So close!");

  Future _maybeApplyBoardState() async {
    final today = DateUtils.dateOnly(DateTime.now());

    // Different algorithms depending on game type...
    if (widget.params.puzzleType == PuzzleType.daily) {
      // Make today's puzzle. The seed is today's date as an int.
      // Daily games reset only once a day
      boardState.makePuzzle(int.parse(today.toString().split(' ').first.split('-').join()));

      if (gameSettings.date.value != today) {
        // If the last saved-game state is for a different day, reset everything
        gameSettings.reset();
        settings.numPlayed.value += 1;
      } else {
        await restoreGameState();
      }
    } else {
      //Autogen games reset after they have been completed.
      if (gameSettings.elapsedTime.value > 0 && !gameSettings.isCompleted.value) {
        boardState.makePuzzle(gameSettings.seed.value);
        await restoreGameState();
      } else {
        // Start over
        gameSettings.seed.value = boardState.makePuzzle(null);
        gameSettings.reset();
        settings.numPlayed.value += 1;
      }
    }

    if (gameSettings.isCompleted.value && mounted) {
      showStats(justWon: true);
    }
  }

  Future restoreGameState() async {
    if (gameSettings.state.value.isNotEmpty) {
      messenger.showSnackBar("Continuing from earlier");
    }
    await boardState.applyGameState(
      gameSettings.state.value,
      gameSettings.elapsedTime.value,
      gameSettings.isCompleted.value,
    );
  }

  void showStats({bool justWon = false}) {
    context.go(
      '/fosteroes/stats',
      extra: justWon
          ? StatsPageParams(
              widget.params.puzzleType,
              widget.params.puzzleDifficulty,
              Duration(seconds: boardState.elapsedTimeSecs.value),
            )
          : null,
    );
  }
}
