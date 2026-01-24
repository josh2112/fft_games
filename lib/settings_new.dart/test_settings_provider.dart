import 'package:fft_games/settings_new.dart/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main2() {
  runApp(ProviderScope(child: TestPrefsApp()));
}

class TestPrefsApp extends StatelessWidget {
  static const PrefKeyWithDefaultValue abcPrefKey = (key: "a.b.c", defaultValue: true);

  const TestPrefsApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      appBar: AppBar(title: Text('Test prefs')),
      body: Center(
        child: Column(
          children: [
            Consumer(
              builder: (context, ref, child) {
                return switch (ref.watch(sharedPreferenceProvider(abcPrefKey))) {
                  AsyncData(:final value) => Text("${abcPrefKey.key} = $value"),
                  AsyncError(:final error) => Text('Error: $error', style: TextStyle(color: Colors.red)),
                  AsyncLoading() => const Center(child: CircularProgressIndicator()),
                };
              },
            ),
            Consumer(
              builder: (context, ref, child) {
                final abcPref = ref.watch(sharedPreferenceProvider(abcPrefKey));
                return TextButton(
                  onPressed: abcPref.hasValue
                      ? () {
                          ref.read(sharedPreferenceProvider(abcPrefKey).notifier).setValue(!abcPref.value!);
                        }
                      : null,
                  child: Text('Toggle a.b.c'),
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}
