import 'dart:async';

import 'package:fft_games_lib/fosteroes/puzzle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '/utils/dialog_or_bottom_sheet.dart';
import '/utils/multi_snack_bar.dart';
import '/utils/utils.dart';
import 'board.dart';
import 'board_state.dart';
import 'hand.dart';
import 'providers.dart';
import 'settings.dart';
import 'settings_dialog.dart';
import 'stats_page.dart';

class PlayPageParams {
  final PuzzleType puzzleType;
  final PuzzleDifficulty puzzleDifficulty;

  PlayPageParams(this.puzzleType, this.puzzleDifficulty);
}

class PlayPage extends ConsumerStatefulWidget {
  final PlayPageParams params;

  PlayPage({PlayPageParams? params, super.key})
    : params = params ?? PlayPageParams(PuzzleType.daily, PuzzleDifficulty.easy);

  @override
  ConsumerState<PlayPage> createState() => _PlayPageState();
}

class _PlayPageState extends ConsumerState<PlayPage> {
  final MultiSnackBarMessenger messenger = MultiSnackBarMessenger();

  late final SettingsController settings;
  late final AppLifecycleListener appLifecycleListener;

  late final BoardState boardState;
  late final GameSettingsController gameSettings;

  @override
  void initState() {
    super.initState();

    settings = ref.read(settingsProvider);

    appLifecycleListener = AppLifecycleListener(
      onStateChange: (state) => boardState.isPaused.value = state != AppLifecycleState.resumed,
    );

    boardState = BoardState(_onPlayerWon, _onBadSolution, widget.params.puzzleDifficulty);
    boardState.isPaused.addListener(maybeUpdateElapsedTime);

    gameSettings = settings.gameSettings[(type: widget.params.puzzleType, difficulty: widget.params.puzzleDifficulty)]!;

    WidgetsBinding.instance.scheduleFrameCallback((_) async {
      await _maybeApplyBoardState();
      boardState.onBoard.addListener(() {
        ref.read(gameSettings.state.notifier).setValue([
          for (final e in boardState.onBoard.dominoes.entries)
            SavedDominoPlacement(e.key.id, e.value.x, e.value.y, e.key.quarterTurns.value),
        ]);
      });
    });
  }

  void maybeUpdateElapsedTime() {
    if (boardState.isPaused.value) {
      ref.read(gameSettings.elapsedTime.notifier).setValue(boardState.elapsedTimeSecs.value);
    }
  }

  @override
  void deactivate() {
    ref.read(gameSettings.elapsedTime.notifier).setValue(boardState.elapsedTimeSecs.value);
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
              Consumer(
                builder: (context, ref, child) => switch (ref.watch(gameSettings.seed)) {
                  AsyncData(value: final seed) => Text(
                    "${widget.params.puzzleType == PuzzleType.daily ? DateFormat.yMMMMd().format(DateTime.now()) : "#$seed"} - ${toBeginningOfSentenceCase(boardState.puzzleDifficulty.name)}",
                    style: TextTheme.of(context).bodyMedium,
                  ),
                  _ => SizedBox(),
                },
              ),
              Consumer(
                builder: (context, ref, child) => switch (ref.watch(settings.showTime)) {
                  AsyncData(value: final showTime) when showTime => ListenableBuilder(
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
                  ),
                  _ => SizedBox(),
                },
              ),
              Spacer(),
              TextButton(onPressed: boardState.isInProgress.value ? boardState.clearBoard : null, child: Text("Clear")),
            ],
          ),
        ),
      ),
    ),
    body: Stack(
      children: [
        Center(
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
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            spacing: 10,
                            children: [
                              Expanded(
                                child: FittedBox(fit: BoxFit.contain, child: Board(boardState)),
                              ),
                              Divider(),
                              Hand(boardState),
                            ],
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

  void _onPlayerWon() async {
    ref.read(gameSettings.elapsedTime.notifier).setValue(boardState.elapsedTimeSecs.value);
    ref.read(gameSettings.isCompleted.notifier).setValue(true);

    ref.read(settings.numPlayed.notifier).increment();
    ref.read(settings.numWon.notifier).increment();

    final currentStreak = await ref.read(settings.currentStreak.future) + 1;
    ref.read(settings.currentStreak.notifier).setValue(currentStreak);

    final lastDateDailyWon = await ref.read(settings.lastDateDailyWon.future);
    final today = DateUtils.dateOnly(DateTime.now());

    if (widget.params.puzzleType == .daily && lastDateDailyWon.isBefore(today)) {
      ref.read(settings.lastDateDailyWon.notifier).setValue(today);

      final maxStreak = await ref.read(settings.maxStreak.future);

      if (currentStreak > maxStreak) {
        ref.read(settings.maxStreak.notifier).setValue(currentStreak);
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

      if ((await ref.read(gameSettings.date.future)).isBefore(today)) {
        // If the last saved-game state is for a different day, reset everything
        await gameSettings.reset(ref);
        ref.read(settings.numPlayed.notifier).increment();
      } else {
        await restoreGameState();
      }
    } else {
      //Autogen games reset after they have been completed.
      if (await ref.read(gameSettings.elapsedTime.future) > 0 && !await ref.read(gameSettings.isCompleted.future)) {
        boardState.makePuzzle(await ref.read(gameSettings.seed.future));
        await restoreGameState();
      } else {
        // Start over
        ref.read(gameSettings.seed.notifier).setValue(boardState.makePuzzle(null));
        await gameSettings.reset(ref);
        ref.read(settings.numPlayed.notifier).increment();
      }
    }

    if (await ref.read(gameSettings.isCompleted.future) && mounted) {
      showStats(justWon: true);
    }
  }

  Future restoreGameState() async {
    final gameState = await ref.read(gameSettings.state.future);

    if (gameState.isNotEmpty) {
      messenger.showSnackBar("Continuing from earlier");
    }
    await boardState.applyGameState(
      gameState,
      await ref.read(gameSettings.elapsedTime.future),
      await ref.read(gameSettings.isCompleted.future),
    );
  }

  void showStats({bool justWon = false}) => context.go(
    '/fosteroes/play/stats',
    extra: justWon
        ? StatsPageParams(
            widget.params.puzzleType,
            widget.params.puzzleDifficulty,
            Duration(seconds: boardState.elapsedTimeSecs.value),
          )
        : null,
  );
}
