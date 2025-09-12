// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainMenuPage extends StatefulWidget {
  const MainMenuPage({super.key});

  @override
  State<MainMenuPage> createState() => _MainMenuPageState();

  static const _gap = SizedBox(height: 10);
}

class _MainMenuPageState extends State<MainMenuPage> {
  String _version = "";

  static const isRunningWithWasm = bool.fromEnvironment('dart.tool.dart2wasm');

  @override
  void initState() {
    super.initState();

    DefaultAssetBundle.of(context)
        .loadString("pubspec.yaml")
        .then(
          (f) =>
              setState(() => _version = f.split("version: ")[1].split("+")[0]),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Foster Family Times Games',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 50),
              FilledButton(
                onPressed: () {
                  GoRouter.of(context).go('/fosterdle');
                },
                child: const Text('Fosterdle'),
              ),
              MainMenuPage._gap,
              Opacity(
                opacity: 0.5,
                child: Text(
                  "Version $_version\t${(isRunningWithWasm ? 'WASM enabled' : '')}",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
