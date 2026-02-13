import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '/settings/global_settings.dart';
import 'router.dart';

void main() async {
  // Basic logging setup.
  Logger.root.level = kDebugMode ? Level.FINE : Level.INFO;
  Logger.root.onRecord.listen((record) {
    dev.log(record.message, time: record.time, level: record.level.value, name: record.loggerName);
  });

  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final globalSettingsState = ref.watch(globalSettingsProvider);
    if (globalSettingsState.hasError) {
      return Text("Error: ${globalSettingsState.error}");
    } else if (globalSettingsState.isLoading) {
      return const CircularProgressIndicator();
    }

    final themeModeState = ref.watch(globalSettingsState.value!.themeMode);

    return switch (themeModeState) {
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
    };
  }
}
