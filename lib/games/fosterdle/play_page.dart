import 'dart:async';

import 'package:fft_games/games/fosterdle/keyboard_widget.dart';
import 'package:fft_games/games/fosterdle/settings.dart';
import 'package:fft_games/games/fosterdle/settings_dialog.dart';
import 'package:fft_games/utils/dialog_or_bottom_sheet.dart';
import 'package:fft_games/utils/multi_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'board_state.dart';
import 'board_widget.dart';
import 'stats_page.dart';

class PlayPage extends StatefulWidget {
  const PlayPage({super.key});

  @override
  State<PlayPage> createState() => _PlayPageState();
}

class _PlayPageState extends State<PlayPage> with KeyboardAdapter {
  late final SettingsController settings;
  late final BoardState boardState;

  late final MultiSnackBarMessenger messenger;

  bool isProcessingGuess = false;

  bool get shouldAcceptInput => boardState.isGameInProgress && !isProcessingGuess;

  @override
  void initState() {
    super.initState();
    messenger = MultiSnackBarMessenger();
    settings = context.read<SettingsController>();
    boardState = BoardState(onWon: _onPlayerWon, onLost: _onPlayerLost);

    // Once the game state is loaded, check if it's current, then apply it
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => Future.wait([
        boardState.isLoaded,
        settings.gameStateDate.isLoaded,
        settings.gameStateGuesses.isLoaded,
        settings.gameStateIsCompleted.isLoaded,
      ]).then(maybeApplyBoardState),
    );
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
    ),
    body: Stack(
      children: [
        Focus(
          autofocus: true,
          onKeyEvent: _processKeyEvent,
          child: Padding(
            padding: EdgeInsets.all(10),
            child: ChangeNotifierProvider.value(
              value: boardState,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(child: const BoardWidget()),
                  const SizedBox(height: 5),
                  ListenableBuilder(
                    listenable: boardState.keyboard,
                    builder: (context, child) => KeyboardWidget(adapter: this, letterStates: boardState.keyboard.keys),
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
  void onSubmit() {
    if (!shouldAcceptInput) return;

    if (settings.isHardMode.value) {
      final err = _errorForHardModeCheckResult(boardState.checkHardMode());
      if (err != null) {
        messenger.showSnackBar(err);
        return;
      }
    }

    isProcessingGuess = true;
    boardState.submitGuess().then((result) {
      isProcessingGuess = false;

      settings.gameStateGuesses.value = boardState.guesses
          .where((g) => g.isSubmitted)
          .map((g) => g.letters.toList())
          .toList();
      settings.gameStateIsCompleted.value = !boardState.isGameInProgress;
      settings.gameStateDate.value = DateUtils.dateOnly(DateTime.now());

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
    final solveCounts = List<int>.from(settings.solveCounts.value);
    solveCounts[numGuesses - 1] += 1;
    settings.solveCounts.value = solveCounts;

    settings.numPlayed.value += 1;
    settings.numWon.value += 1;
    settings.currentStreak.value += 1;
    if (settings.currentStreak.value > settings.maxStreak.value) {
      settings.maxStreak.value = settings.currentStreak.value;
    }

    context.go('/fosterdle/stats', extra: StatsPageWinLoseData(numGuesses, boardState.word));
  }

  Future<void> _onPlayerLost(String word) async {
    settings.numPlayed.value += 1;
    settings.currentStreak.value = 0;

    context.go('/fosterdle/stats', extra: StatsPageWinLoseData(-1, boardState.word));
  }

  void showStats() => context.go('/fosterdle/stats');

  Future maybeApplyBoardState(List<void> value) async {
    if (DateUtils.isSameDay(settings.gameStateDate.value, DateTime.now())) {
      await Future.delayed(Duration(milliseconds: 50));

      final numGuesses = await boardState.applyGameState(
        settings.gameStateGuesses.value,
        settings.gameStateIsCompleted.value,
      );
      await Future.delayed(Duration(milliseconds: 750));

      if (!boardState.isGameInProgress && mounted) {
        context.go('/fosterdle/stats', extra: StatsPageWinLoseData(numGuesses, boardState.word));
      }
    }
  }
}
