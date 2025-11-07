import 'dart:async';

import 'package:defer_pointer/defer_pointer.dart';
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

class PlayPage extends StatefulWidget {
  final bool autogen;

  const PlayPage({this.autogen = true, super.key});

  @override
  State<PlayPage> createState() => _PlayPageState();
}

class _PlayPageState extends State<PlayPage> {
  late final SettingsController settings;
  late final BoardState boardState;
  late final AppLifecycleListener appLifecycleListener;

  late final MultiSnackBarMessenger messenger;

  @override
  void initState() {
    super.initState();

    messenger = MultiSnackBarMessenger();
    appLifecycleListener = AppLifecycleListener(onStateChange: onLifecycleStateChange);
    settings = context.read<SettingsController>();
    boardState = BoardState(_onPlayerWon, _onBadSolution, widget.autogen);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await boardState.isLoaded;
      await settings.gameStateDate.isLoaded;
      await settings.gameState.isLoaded;
      await settings.gameStateIsCompleted.isLoaded;
      await settings.gameStateElapsedTime.isLoaded;
      await _maybeApplyBoardState();

      boardState.onBoard.addListener(() {
        settings.gameState.value = boardState.onBoard.dominoes.entries
            .map((e) => SavedDominoPlacement(e.value.x, e.value.y, e.key.side1, e.key.side2, e.key.quarterTurns.value))
            .toList();
        settings.gameStateDate.value = DateUtils.dateOnly(DateTime.now());
        settings.gameStateIsCompleted.value = false;
      });
    });
  }

  @override
  void dispose() {
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
        IconButton(icon: Icon(Icons.settings), onPressed: () => showDialogOrBottomSheet(context, SettingsDialog())),
      ],
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(18.0),
        child: Padding(
          padding: EdgeInsetsGeometry.only(left: 20, right: 10),
          child: Row(
            children: [
              Text(DateFormat.yMMMMd().format(DateTime.now()), style: TextTheme.of(context).bodyMedium),
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
    settings.gameStateElapsedTime.value = boardState.elapsedTimeSecs.value;
    settings.gameStateIsCompleted.value = true;
    settings.numWon.value += 1;
    settings.currentStreak.value += 1;
    if (settings.currentStreak.value > settings.maxStreak.value) {
      settings.maxStreak.value = settings.currentStreak.value;
    }

    context.go('/fosteroes/stats', extra: StatsPageWinLoseData());
  }

  void _onBadSolution() {
    messenger.showSnackBar("So close!");
  }

  Future _maybeApplyBoardState() async {
    final today = DateUtils.dateOnly(DateTime.now());

    if (settings.gameStateDate.value != today) {
      // If the last saved-game state is for a different day, reset everything
      settings.numPlayed.value += 1;
      settings.gameStateDate.value = today;
      settings.gameStateIsCompleted.value = false;
      settings.gameStateElapsedTime.value = 0;
    } else {
      if (settings.gameStateElapsedTime.value > 0) {
        messenger.showSnackBar("Continuing from earlier");
        await boardState.applyGameState(
          settings.gameState.value,
          settings.gameStateElapsedTime.value,
          settings.gameStateIsCompleted.value,
        );
      }

      if (settings.gameStateIsCompleted.value && mounted) {
        context.go('/fosteroes/stats', extra: StatsPageWinLoseData());
      }
    }
  }

  void onLifecycleStateChange(AppLifecycleState state) {
    boardState.isPaused.value = state != AppLifecycleState.resumed;
    if (boardState.isPaused.value) {
      settings.gameStateElapsedTime.value = boardState.elapsedTimeSecs.value;
    }
  }
}
