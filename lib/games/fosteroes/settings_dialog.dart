import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/settings/settings_dialog.dart' as global;
import 'settings.dart';

class SettingsDialog extends ConsumerWidget {
  final SettingsController settings;

  const SettingsDialog(this.settings, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => global.SettingsDialog(
    children: [
      global.SettingsEntry(
        title: "Show time",
        child: Consumer(
          builder: (context, ref, child) => switch (ref.watch(settings.showTime)) {
            AsyncData(value: final showTime) => Switch(
              value: showTime,
              onChanged: (newShowTime) => ref.read(settings.showTime.notifier).setValue(newShowTime),
            ),
            _ => const CircularProgressIndicator(),
          },
        ),
      ),
    ],
  );
}
