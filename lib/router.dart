// Copyright 2023, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:fft_games/games/fosterdle/stats_page.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'games/fosterdle/fosterdle.dart' as fosterdle;
//import 'game_internals/score.dart';
import 'main_menu_page.dart';
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
          routes: [
            GoRoute(
              path: 'stats',
              builder: (context, state) => fosterdle.StatsPage(
                key: Key('fosterdle stats'),
                wonGameData: state.extra as StatsPageWonGameData?,
              ),
            ),
          ],
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
