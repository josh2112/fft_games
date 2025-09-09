import 'package:fft_games/games/fosterdle/keyboard_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import '../../settings/persistence/settings_persistence.dart';
import 'board_state.dart';
import 'board_widget.dart';
import 'settings.dart';

class PlayPage extends StatefulWidget {
  const PlayPage({super.key});

  @override
  State<PlayPage> createState() => _PlayPageState();
}

class _PlayPageState extends State<PlayPage> with KeyboardAdapter {
  static final _log = Logger('PlaySessionScreen');

  late final BoardState _boardState;

  @override
  void initState() {
    super.initState();
    _boardState = BoardState(word: 'WORDL', onWin: _onPlayerWon);
  }

  @override
  void dispose() {
    _boardState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SettingsController settings = SettingsController(store: context.watch<SettingsPersistence>());

    //_log.info("Focused: ${Focus.of(context).debugLabel}");

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        
        final letter = event.character?.toUpperCase();
        if (letter is String) {
          onLetter(letter);
        } else if (event.logicalKey == LogicalKeyboardKey.backspace) {
          onBackspace();
        } else if (event.logicalKey == LogicalKeyboardKey.enter) {
          onSubmit();
        }
        return KeyEventResult.handled;
      },
      child: MultiProvider(
        providers: [Provider.value(value: _boardState)],
        child: Scaffold(
          body: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Fosterdle', style: Theme.of(context).textTheme.headlineLarge),
                    ValueListenableBuilder(
                      valueListenable: settings.hardMode,
                      builder: (context, hardMode, child) =>
                          Switch(value: hardMode, onChanged: (v) => _maybeToggleHardMode(v, settings)),
                    ),
                  ],
                ),
                const Spacer(),
                const BoardWidget(),
                const Spacer(),
                StreamBuilder(
                  stream: _boardState.keyboardStateChanges,
                  builder: (context, child) => KeyboardWidget(adapter: this, letterStates: _boardState.keyboardState),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void onLetter(String letter) => _boardState.addLetter(letter);

  @override
  void onBackspace() => _boardState.removeLetter();

  @override
  void onSubmit() => _boardState.submitGuess();

  Future<void> _onPlayerWon(int numGuesses) async {
    _log.info('Player won!');

    //final score = Score(1, 1, DateTime.now().difference(_startOfPlay));

    // final playerProgress = context.read<PlayerProgress>();
    // playerProgress.setLevelReached(widget.level.number);

    //setState(() => _isGameWinAnimationInProgress = true);

    //await Future<void>.delayed(_gameWinAnimationDuration);
    //if (!mounted) return;

    GoRouter.of(context).go('/play/won', extra: {'numGuesses': numGuesses});
  }

  void _maybeToggleHardMode(bool hardModeOn, SettingsController settings) {
    if (!hardModeOn && _boardState.guesses.isNotEmpty) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(const SnackBar(content: Text("Can't turn off hard mode once you've made a guess!")));
    } else {
      settings.toggleHardMode();
    }
  }
}
