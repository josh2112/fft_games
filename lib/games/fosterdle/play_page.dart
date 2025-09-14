import 'package:fft_games/games/fosterdle/keyboard_widget.dart';
import 'package:fft_games/games/fosterdle/palette.dart';
import 'package:fft_games/games/fosterdle/settings.dart';
import 'package:fft_games/games/fosterdle/settings_dialog.dart';
import 'package:fft_games/settings/persistence/settings_persistence.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
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
  static final _log = Logger('PlaySessionScreen');

  late final SettingsController settings;
  late final BoardState boardState;

  bool isProcessingGuess = false;

  @override
  void initState() {
    super.initState();
    boardState = BoardState(word: 'WORDL', onWon: _onPlayerWin, onLost: _onPlayerLost);
    settings = SettingsController(store: context.read<SettingsPersistence>());
  }

  @override
  void dispose() {
    settings.dispose();
    super.dispose();
  }

  bool _isModifierKeyPressed() =>
      HardwareKeyboard.instance.isControlPressed ||
      HardwareKeyboard.instance.isShiftPressed ||
      HardwareKeyboard.instance.isAltPressed ||
      HardwareKeyboard.instance.isMetaPressed;

  @override
  Widget build(BuildContext context) {
    return Focus(
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
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          Provider.value(value: boardState),
          Provider.value(value: Palette()),
        ],
        child: Scaffold(
          appBar: AppBar(
            title: Text('Fosterdle'),
            centerTitle: true,
            actions: [
              IconButton(onPressed: showStats, icon: Icon(Icons.bar_chart)),
              Builder(
                builder: (context) => IconButton(
                  onPressed: () =>
                      showDialogOrBottomSheet(context, SettingsDialog(callerContext: context)),
                  icon: Icon(Icons.settings),
                ),
              ),
            ],
          ),
          body: Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(child: const BoardWidget()),
                const SizedBox(height: 5),
                ListenableBuilder(
                  listenable: boardState.keyboard,
                  builder: (context, child) =>
                      KeyboardWidget(adapter: this, letterStates: boardState.keyboard.keys),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void onLetter(String letter) {
    if (!isProcessingGuess) boardState.addLetter(letter);
  }

  @override
  void onBackspace() {
    if (!isProcessingGuess) boardState.removeLetter();
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

    if (settings.hardMode.value) {
      final err = errorForHardModeCheckResult(boardState.checkHardMode());
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
        return;
      }
    }

    isProcessingGuess = true;
    boardState.submitGuess().then((_) => isProcessingGuess = false);
  }

  Future<void> _onPlayerWin(int numGuesses) async {
    _log.info('Player won!');

    //final score = Score(1, 1, DateTime.now().difference(_startOfPlay));

    // final playerProgress = context.read<PlayerProgress>();
    // playerProgress.setLevelReached(widget.level.number);

    //setState(() => _isGameWinAnimationInProgress = true);

    //await Future<void>.delayed(_gameWinAnimationDuration);
    //if (!mounted) return;

    GoRouter.of(context).go('/fosterdle/stats', extra: StatsPageWonGameData(numGuesses));
  }

  Future<void> _onPlayerLost(String word) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Oh no!"),
        actions: [TextButton(onPressed: () => GoRouter.of(context).go('/'), child: Text("OK"))],
        content: Text("The word is $word. Better luck tomorrow!"),
      ),
    );
  }

  void showStats() => GoRouter.of(context).go('/fosterdle/stats');

  void showSettings(BuildContext context) {
    if (MediaQuery.of(context).size.width < 500) {
      Scaffold.of(context).showBottomSheet((context) => SettingsDialog(callerContext: context));
    } else {
      showDialog(
        context: context,
        builder: (c) => Dialog(child: SettingsDialog(callerContext: context)),
      );
    }
  }
}

void showDialogOrBottomSheet(BuildContext context, Widget widget) {
  if (MediaQuery.of(context).size.width < 500) {
    Scaffold.of(context).showBottomSheet((c) => widget);
  } else {
    showDialog(
      context: context,
      builder: (c) => Dialog(child: widget),
    );
  }
}
