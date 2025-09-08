// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

//import '../settings/settings.dart';
import '/utils/responsive_page.dart';

class MainMenuPage extends StatelessWidget {
  const MainMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    //final settingsController = context.watch<SettingsController>();

    return Scaffold(
      body: ResponsivePage(
        squarishMainArea: Center(
          child: Transform.rotate(
            angle: -0.1,
            child: const Text(
              'Foster Family Times Games!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 55, height: 1),
            ),
          ),
        ),
        rectangularMenuArea: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton(
              onPressed: () {
                GoRouter.of(context).go('/fosterdle');
              },
              child: const Text('Fosterdle'),
            ),
            _gap,
            /*FilledButton(
              onPressed: () => GoRouter.of(context).push('/settings'),
              child: const Text('Settings'),
            ),
            _gap,*/
          ],
        ),
      ),
    );
  }

  static const _gap = SizedBox(height: 10);
}
