import 'dart:developer' as dev;

import 'package:fft_games/settings/persistence/memory_persistence.dart';
import 'package:fft_games/settings/persistence/settings_persistence.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  // Lock the game to portrait mode on mobile devices.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // This is where you add objects that you want to have available
      // throughout your game.
      //
      // Every widget in the game can access these objects by calling
      // `context.watch()` or `context.read()`.
      // See `lib/main_menu/main_menu_screen.dart` for example usage.
      providers: [Provider<SettingsPersistence>(create: (context) => MemoryPersistence())],
      child: Builder(
        builder: (context) {
          return MaterialApp.router(
            title: 'Foster Family Times Games',
            theme: ThemeData.light(), // Or your custom light theme
            darkTheme: ThemeData.dark(), // Or your custom dark theme
            themeMode: ThemeMode.system,
            routerConfig: router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
