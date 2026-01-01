import 'dart:developer' as dev;

import 'package:fft_games/settings/global_settings.dart';
import 'package:fft_games/settings/persistence/settings_persistence.dart';
import 'package:fft_games/settings/persistence/shared_prefs_persistence.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import 'router.dart';

void main() async {
  // Basic logging setup.
  Logger.root.level = kDebugMode ? Level.FINE : Level.INFO;
  Logger.root.onRecord.listen((record) {
    dev.log(record.message, time: record.time, level: record.level.value, name: record.loggerName);
  });

  WidgetsFlutterBinding.ensureInitialized();

  // Data migration
  final prefs = SharedPrefsPersistence();
  await GlobalSettingsController.migrate(prefs);

  // Pass in initial theme to avoid flickering from default (system) to dark/light.
  runApp(MyApp(initialThemeMode: ThemeMode.values[await GlobalSettingsController(prefs).themeMode.waitLoaded]));
}

class MyApp extends StatelessWidget {
  final settingsStore = SharedPrefsPersistence();
  final ThemeMode initialThemeMode;

  MyApp({this.initialThemeMode = ThemeMode.light, super.key});

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      Provider.value(value: settingsStore),
      Provider(create: (context) => GlobalSettingsController(settingsStore)),
    ],
    child: Builder(
      builder: (context) {
        return Consumer<GlobalSettingsController>(
          builder: (context, globalSettings, child) => ValueListenableBuilder(
            valueListenable: globalSettings.themeMode,
            builder: (context, themeMode, child) => MaterialApp.router(
              title: 'Foster Family Times Games',
              theme: ThemeData.light().copyWith(textTheme: Typography().black.apply(fontFamily: 'FacultyGlyphic')),
              darkTheme: ThemeData.dark().copyWith(textTheme: Typography().white.apply(fontFamily: 'FacultyGlyphic')),
              themeMode: globalSettings.themeMode.isLoaded ? ThemeMode.values[themeMode] : initialThemeMode,
              routerConfig: router,
              debugShowCheckedModeBanner: false,
            ),
          ),
        );
      },
    ),
  );
}
