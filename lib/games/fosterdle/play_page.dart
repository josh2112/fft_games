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

  @override
  void initState() {
    super.initState();
    messenger = MultiSnackBarMessenger();
    boardState = BoardState(onWon: _onPlayerWin, onLost: _onPlayerLost);
    settings = context.read<SettingsController>();
  }

  @override
  void dispose() {
    messenger.dispose();
    super.dispose();
  }

  bool _isModifierKeyPressed() =>
      HardwareKeyboard.instance.isControlPressed ||
      HardwareKeyboard.instance.isShiftPressed ||
      HardwareKeyboard.instance.isAltPressed ||
      HardwareKeyboard.instance.isMetaPressed;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: BackButton(onPressed: () => context.pop()),
      title: Text('Fosterdle', style: TextStyle(fontFamily: 'FacultyGlyphic')),
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
          onKeyEvent: (node, event) {
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
          },
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

  @override
  void onLetter(String letter) {
    if (boardState.isGameInProgress && !isProcessingGuess) boardState.addLetter(letter);
  }

  @override
  void onBackspace() {
    if (boardState.isGameInProgress && !isProcessingGuess) boardState.removeLetter();
  }

  String? errorForHardModeCheckResult(HardModeCheckResult r) {
    if (r == HardModeCheckResult.ok) {
      return null;
    } else if (r.place != null) {
      return "Letter ${r.place! + 1} must be ${r.letter}";
    } else {
      return "Guess must contain ${r.letter}";
    }
  }

  @override
  void onSubmit() {
    if (isProcessingGuess) return;

    if (settings.isHardMode.value) {
      final err = errorForHardModeCheckResult(boardState.checkHardMode());
      if (err != null) {
        messenger.showSnackBar(err);
      }
    }

    isProcessingGuess = true;
    boardState.submitGuess().then((result) {
      isProcessingGuess = false;
      if (!mounted) return;
      if (result == SubmissionResult.wordNotInDictionary) {
        messenger.showSnackBar("Word not in dictionary");
      }
    });
  }

  Future<void> _onPlayerWin(int numGuesses) async {
    final solveCounts = List<int>.from(settings.solveCounts.value);
    solveCounts[numGuesses - 1] += 1;
    settings.solveCounts.value = solveCounts;

    settings.numPlayed.value += 1;
    settings.numWon.value += 1;
    settings.currentStreak.value += 1;
    if (settings.currentStreak.value > settings.maxStreak.value) {
      settings.maxStreak.value = settings.currentStreak.value;
    }

    context.go('/fosterdle/stats', extra: StatsPageContext(numGuesses, boardState.word));
  }

  Future<void> _onPlayerLost(String word) async {
    settings.numPlayed.value += 1;
    settings.currentStreak.value = 0;

    context.go('/fosterdle/stats', extra: StatsPageContext(-1, boardState.word));
  }

  void showStats() => context.go('/fosterdle/stats');
}
