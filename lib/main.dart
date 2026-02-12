import 'dart:developer' as dev;

import 'package:fft_games/settings/global_settings.dart';
import 'package:fft_games/settings/persistence/settings_persistence.dart';
import 'package:fft_games/settings/persistence/shared_prefs_persistence.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart' as prov;

import 'router.dart';

void main() async {
  // Basic logging setup.
  Logger.root.level = kDebugMode ? Level.FINE : Level.INFO;
  Logger.root.onRecord.listen((record) {
    dev.log(record.message, time: record.time, level: record.level.value, name: record.loggerName);
  });

  WidgetsFlutterBinding.ensureInitialized();

  // Data migration TODO: Do in MyApp once rewritten with riverpod
  final prefs = SharedPrefsPersistence();
  await GlobalSettingsController.migrate(prefs);

  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  final settingsStore = SharedPrefsPersistence();
  final ThemeMode initialThemeMode;

  MyApp({this.initialThemeMode = ThemeMode.light, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final globalSettings = ref.read(globalSettingsProvider);
    final themeModeState = ref.watch(globalSettings.themeMode);

    return prov.MultiProvider(
      providers: [
        prov.Provider<SettingsPersistence>.value(value: settingsStore),
        prov.Provider(create: (context) => GlobalSettingsController()),
      ],
      child: switch (themeModeState) {
        AsyncData(value: final themeMode) => MaterialApp.router(
          title: 'Foster Family Times Games',
          theme: ThemeData.light().copyWith(textTheme: Typography().black.apply(fontFamily: 'FacultyGlyphic')),
          darkTheme: ThemeData.dark().copyWith(textTheme: Typography().white.apply(fontFamily: 'FacultyGlyphic')),
          themeMode: themeMode,
          routerConfig: router,
          debugShowCheckedModeBanner: false,
        ),
        AsyncLoading() => const CircularProgressIndicator(),
        AsyncError(:final error) => Text("Error: $error"),
      },
    );
  }
}
