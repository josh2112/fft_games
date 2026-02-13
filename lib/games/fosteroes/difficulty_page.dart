import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '/utils/utils.dart';
import 'domino.dart';
import 'fosteroes.dart';
import 'providers.dart';

class DifficultyPage extends StatefulWidget {
  final PuzzleType puzzleType;
  const DifficultyPage(this.puzzleType, {super.key});

  @override
  State<DifficultyPage> createState() => _DifficultyPageState();
}

class _DifficultyPageState extends State<DifficultyPage> {
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: BackButton(onPressed: () => context.pop()),
      centerTitle: true,
      title: Text('Fosteroes'),
    ),
    body: Center(
      child: Padding(
        padding: EdgeInsets.only(top: 0, bottom: 20, left: 20, right: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(toBeginningOfSentenceCase(widget.puzzleType.name), style: TextTheme.of(context).titleMedium),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 15,
                children: [
                  for (var d in PuzzleDifficulty.values)
                    Consumer(
                      builder: (context, ref, child) {
                        final isNew =
                            true ==
                            ref.watch(isNewGameAvailableProvider((type: PuzzleType.daily, difficulty: d))).value;
                        return Badge(
                          label: Text("New"),
                          offset: Offset(-18, -4),
                          isLabelVisible: isNew,
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          child: SizedBox(
                            width: 180,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.all(Radius.circular(25))),
                                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                              ),
                              onPressed: () =>
                                  context.go('/fosteroes/play', extra: PlayPageParams(widget.puzzleType, d)),
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    margin: EdgeInsets.only(right: 20),
                                    decoration: ShapeDecoration(
                                      color: Colors.white,
                                      shape: RoundedSuperellipseBorder(
                                        borderRadius: BorderRadius.all(Radius.circular(10)),
                                      ),
                                    ),
                                    child: HalfDomino(d.index + 1, Colors.black),
                                  ),
                                  Text(toBeginningOfSentenceCase(d.name)),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
