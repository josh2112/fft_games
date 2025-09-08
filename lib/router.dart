// Copyright 2023, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

//import 'game_internals/score.dart';
import 'main_menu_page.dart';
import 'games/fosterdle/fosterdle.dart' as fosterdle;
//import 'settings/settings_screen.dart';
//import 'win_game/win_game_screen.dart';

/// The router describes the game's navigational hierarchy, from the main
/// screen through settings screens all the way to each individual level.
final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MainMenuPage(key: Key('main menu')),
      routes: [
        GoRoute(
          path: 'fosterdle',
          builder: (context, state) =>
              const fosterdle.PlayPage(key: Key('fosterdle')),
          /*routes: [
            GoRoute(
              path: 'won',
              redirect: (context, state) {
                if (state.extra == null) {
                  // Trying to navigate to a win screen without any data.
                  // Possibly by using the browser's back button.
                  return '/';
                }

                // Otherwise, do not redirect.
                return null;
              },
              pageBuilder: (context, state) {
                final map = state.extra! as Map<String, dynamic>;
                final score = map['score'] as Score;

                return buildMyTransition<void>(
                  key: const ValueKey('won'),
                  color: context.watch<Palette>().backgroundPlaySession,
                  child: WinGameScreen(
                    score: score,
                    key: const Key('win game'),
                  ),
                );
              },
            ),
          ],*/
        ),
        /*GoRoute(
          path: 'settings',
          builder: (context, state) =>
              const SettingsScreen(key: Key('settings')),
        ),*/
      ],
    ),
  ],
);
