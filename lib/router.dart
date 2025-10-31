// Copyright 2023, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:fft_games/settings/persistence/settings_persistence.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'games/fosterdle/fosterdle.dart' as fosterdle;
import 'games/fosteroes/fosteroes.dart' as fosteroes;
import 'main_menu/main_menu_page.dart';

/// The router describes the game's navigational hierarchy, from the main
/// screen through settings screens all the way to each individual level.
final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MainMenuPage(key: Key('main menu')),
      routes: [
        // Use a "shell route" to provide a MultiProvider to all the Fosterdle subroutes.
        // Any child route will be able to grab whatever we put in the MultiProvider. The
        // only downside is the AppBar inside a first-level shell route won't show
        // the Back button, even if there is a previous route, so it has to be
        // provided manually (with BackButton( onPressed: () => context.pop())).
        ShellRoute(
          builder: (context, state, child) {
            return MultiProvider(
              providers: [
                Provider(create: (context) => fosterdle.SettingsController(store: context.read<SettingsPersistence>())),
                Provider(create: (context) => fosterdle.Palette()),
              ],
              child: child,
            );
          },
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
            GoRoute(
              path: 'fosteroes',
              builder: (context, state) => const fosteroes.PlayPage(key: Key('fosteroes')),
              routes: [
                GoRoute(
                  path: 'stats',
                  builder: (context, state) => fosteroes.StatsPage(
                    key: Key('fosteroes stats'),
                    winLoseData: state.extra as fosteroes.StatsPageWinLoseData?,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
  //initialLocation: '/' # Go directly to a page (for testing)
);
