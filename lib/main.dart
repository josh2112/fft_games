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
  // Put game into full screen mode on mobile devices.
  //await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final settingsStore = SharedPrefsPersistence();

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // This is where you add objects that you want to have available
      // throughout your game.
      //
      // Every widget in the game can access these objects by calling
      // `context.watch()` or `context.read()`.
      // See `lib/main_menu/main_menu_screen.dart` for example usage.
      providers: [
        Provider<SettingsPersistence>.value(value: settingsStore),
        Provider<GlobalSettingsController>(create: (context) => GlobalSettingsController(store: settingsStore)),
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
                themeMode: ThemeMode.values[themeMode],
                routerConfig: router,
                debugShowCheckedModeBanner: false,
              ),
            ),
          );
        },
      ),
    );
  }
}
