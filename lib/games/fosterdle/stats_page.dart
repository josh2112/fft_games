import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StatsPageWonGameData {
  final int numGuesses;

  const StatsPageWonGameData(this.numGuesses);
}

class StatsPage extends StatelessWidget {
  final StatsPageWonGameData? wonGameData;

  const StatsPage({super.key, this.wonGameData});

  @override
  Widget build(BuildContext context) {
    final bool wonGame = wonGameData != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(wonGame ? 'You won!' : 'Fosterdle Stats'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (wonGame)
              Text('You did it in ${wonGameData!.numGuesses} guesses'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (wonGame) {
                  GoRouter.of(context).go('/');
                } else {
                  GoRouter.of(context).pop();
                }
              },
              child: Text(wonGame ? "Home" : 'Back'),
            ),
          ],
        ),
      ),
    );
  }
}
