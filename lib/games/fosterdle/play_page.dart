import 'dart:async';

import 'package:fft_games/games/fosterdle/keyboard_widget.dart';
import 'package:fft_games/games/fosterdle/providers.dart';
import 'package:fft_games/games/fosterdle/settings.dart';
import 'package:fft_games/games/fosterdle/settings_dialog.dart';
import 'package:fft_games/utils/dialog_or_bottom_sheet.dart';
import 'package:fft_games/utils/multi_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart' as prov;

import 'board_state.dart';
import 'board_widget.dart';
import 'stats_page.dart';

class PlayPage extends ConsumerStatefulWidget {
  const PlayPage({super.key});

  @override
  ConsumerState<PlayPage> createState() => _PlayPageState();
}

class _PlayPageState extends ConsumerState<PlayPage> with KeyboardAdapter {
  late final SettingsController settings;
  late final BoardState boardState;

  late final MultiSnackBarMessenger messenger;

  bool isProcessingGuess = false;

  bool get shouldAcceptInput => boardState.isGameInProgress && !isProcessingGuess;

  @override
  void initState() {
    super.initState();
    messenger = MultiSnackBarMessenger();
    settings = ref.read(settingsProvider);
    boardState = BoardState(onWon: _onPlayerWon, onLost: _onPlayerLost);

    // Once the game state is loaded, check if it's current, then apply it
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => Future.wait([
        boardState.isLoaded,
        //settings.gameStateDate.waitLoaded,
        //settings.gameStateGuesses.waitLoaded,
        //settings.gameStateIsCompleted.waitLoaded,
      ]).then(_maybeApplyBoardState),
    );
  }

  @override
  void dispose() {
    messenger.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(paletteProvider);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: Text('Fosterdle'),
        centerTitle: true,
        actions: [
          IconButton(onPressed: showStats, icon: Icon(Icons.bar_chart)),
          Builder(
            builder: (context) => IconButton(
              onPressed: () => showDialogOrBottomSheet(context, SettingsDialog(settings, boardState, messenger)),
              icon: Icon(Icons.settings),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(18.0),
          child: Text(DateFormat.yMMMMd().format(DateTime.now()), style: TextTheme.of(context).bodyMedium),
        ),
      ),
      body: Stack(
        children: [
          Focus(
            autofocus: true,
            onKeyEvent: _processKeyEvent,
            child: Padding(
              padding: EdgeInsets.all(10),
              child: ListenableBuilder(
                listenable: boardState,
                builder: (context, child) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(child: BoardWidget(boardState, palette)),
                    const SizedBox(height: 5),
                    ListenableBuilder(
                      listenable: boardState.keyboard,
                      builder: (context, child) =>
                          KeyboardWidget(adapter: this, letterStates: boardState.keyboard.keys, palette: palette),
                    ),
                  ],
                ),
              ),
            ),
          ),
          MultiSnackBar(messenger: messenger),
        ],
      ),
    );
  }

  KeyEventResult _processKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent && !_isModifierKeyPressed()) {
      final letter = event.character?.toUpperCase();
      if (letter is String && RegExp(r'^[a-zA-Z]$').hasMatch(letter)) {
        onLetter(letter);
      } else if (event.logicalKey == LogicalKeyboardKey.backspace) {
        onBackspace();
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        onSubmit();
      } else {
        return KeyEventResult.ignored;
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  bool _isModifierKeyPressed() =>
      HardwareKeyboard.instance.isControlPressed ||
      HardwareKeyboard.instance.isShiftPressed ||
      HardwareKeyboard.instance.isAltPressed ||
      HardwareKeyboard.instance.isMetaPressed;

  @override
  void onLetter(String letter) {
    if (shouldAcceptInput) boardState.addLetter(letter);
  }

  @override
  void onBackspace() {
    if (shouldAcceptInput) boardState.removeLetter();
  }

  @override
  void onSubmit() async {
    if (!shouldAcceptInput) return;

    if (await ref.read(settings.isHardMode.future)) {
      if (_errorForHardModeCheckResult(boardState.checkHardMode()) case String err) {
        messenger.showSnackBar(err);
        return;
      }
    }

    isProcessingGuess = true;
    boardState.submitGuess().then((result) {
      isProcessingGuess = false;

      ref
          .read(settings.gameStateGuesses.notifier)
          .setValue(boardState.guesses.where((g) => g.isSubmitted).map((g) => g.letters.toList()).toList());
      ref.read(settings.gameStateDate.notifier).setValue(DateUtils.dateOnly(DateTime.now()));
      ref.read(settings.gameStateIsCompleted.notifier).setValue(!boardState.isGameInProgress);

      if (!mounted) return;
      if (result == SubmissionResult.wordNotInDictionary) {
        messenger.showSnackBar("Word not in dictionary");
      }
    });
  }

  String? _errorForHardModeCheckResult(HardModeCheckResult r) {
    if (r == HardModeCheckResult.ok) {
      return null;
    } else if (r.place != null) {
      return "Letter ${r.place! + 1} must be ${r.letter}";
    } else {
      return "Guess must contain ${r.letter}";
    }
  }

  Future<void> _onPlayerWon(int numGuesses) async {
    final solveCounts = await ref.read(settings.solveCounts.future);
    solveCounts[numGuesses - 1] += 1;
    ref.read(settings.solveCounts.notifier).setValue(solveCounts);

    final currentStreak = await ref.read(settings.currentStreak.future) + 1;
    final maxStreak = await ref.read(settings.maxStreak.future);

    ref.read(settings.numPlayed.notifier).increment();
    ref.read(settings.numWon.notifier).increment();
    ref.read(settings.currentStreak.notifier).setValue(currentStreak);

    if (currentStreak > maxStreak) {
      ref.read(settings.maxStreak.notifier).setValue(currentStreak);
    }

    showStats(winLoseData: StatsPageWinLoseData(numGuesses, boardState.word));
  }

  Future<void> _onPlayerLost(String word) async {
    ref.read(settings.numPlayed.notifier).increment();
    ref.read(settings.currentStreak.notifier).setValue(0);

    showStats(winLoseData: StatsPageWinLoseData(-1, boardState.word));
  }

  Future _maybeApplyBoardState(List<void> _) async {
    // This page is loaded even when navigating to the stats page directly (probably because all Fosterdle routes are in
    // a shell route). If this is not our final destination, we want to skip all the animation delays.
    bool isNavigatingToChildPage = GoRouter.of(context).state.path != "fosterdle";

    final date = await ref.read(settings.gameStateDate.future);
    final isCompleted = await ref.read(settings.gameStateIsCompleted.future);

    if (DateUtils.isSameDay(date, DateTime.now())) {
      if (!isNavigatingToChildPage) await Future.delayed(Duration(milliseconds: 50));

      final numGuesses = await boardState.applyGameState(await ref.read(settings.gameStateGuesses.future), isCompleted);

      if (!isNavigatingToChildPage) {
        await Future.delayed(Duration(milliseconds: 750));

        if (!boardState.isGameInProgress && mounted) {
          showStats(winLoseData: StatsPageWinLoseData(numGuesses, boardState.word));
        }
      }
    }
  }

  void showStats({StatsPageWinLoseData? winLoseData}) => context.go('/fosterdle/stats', extra: winLoseData);
}
