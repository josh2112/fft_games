// Copyright 2023, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:fft_games/settings/persistence/settings_persistence.dart';
import 'package:fft_games/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' as prov;

import 'games/fosterdle/fosterdle.dart' as fosterdle;
import 'games/fosteroes/fosteroes.dart' as fosteroes;
import 'main_menu/main_menu_page.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => MainMenuPage(key: Key('main menu')),
      routes: [
        GoRoute(
          path: 'fosterdle',
          builder: (context, state) => const fosterdle.PlayPage(key: Key('fosterdle')),
          routes: [
            GoRoute(
              path: 'stats',
              builder: (context, state) => fosterdle.StatsPage(
                key: Key('fosterdle stats'),
                winLoseData: state.extra as fosterdle.StatsPageWinLoseData?,
              ),
            ),
          ],
        ),
        ShellRoute(
          builder: (context, state, child) => prov.Provider(
            create: (context) => fosteroes.SettingsController(store: context.read<SettingsPersistence>()),
            child: child,
          ),
          routes: [
            GoRoute(
              path: 'fosteroes',
              builder: (context, state) {
                final puzzleType = state.extra is PuzzleType ? state.extra as PuzzleType : PuzzleType.daily;
                return fosteroes.DifficultyPage(puzzleType, key: Key('fosteroes difficulty'));
              },
              routes: [
                GoRoute(
                  path: 'play',
                  builder: (context, state) =>
                      fosteroes.PlayPage(key: Key('fosteroes'), params: state.extra as fosteroes.PlayPageParams?),
                  routes: [
                    GoRoute(
                      path: 'stats',
                      builder: (context, state) => const fosteroes.StatsPage(key: Key('fosteroes stats')),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ], // initialLocation: '/' # Go directly to a page (for testing)
);
