import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/settings/global_settings.dart';
import 'settings.dart';

class SettingsDialog extends ConsumerWidget {
  final SettingsController settings;

  const SettingsDialog(this.settings, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final globalSettings = ref.read(globalSettingsProvider);

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 500),
      child: Padding(
        padding: EdgeInsetsGeometry.only(top: 8, bottom: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Padding(
                  padding: EdgeInsetsGeometry.only(right: 15),
                  child: Align(alignment: Alignment.centerRight, child: CloseButton()),
                ),
                Center(
                  child: Container(
                    color: Colors.transparent,
                    child: Text("Settings", style: Theme.of(context).textTheme.titleLarge),
                  ),
                ),
              ],
            ),
            ListTile(
              title: Text("Color theme"),
              trailing: Consumer(
                builder: (context, ref, child) => switch (ref.watch(globalSettings.themeMode)) {
                  AsyncData(value: final themeMode) => DropdownButton(
                    value: themeMode,
                    onChanged: (newThemeMode) => ref.read(globalSettings.themeMode.notifier).setValue(newThemeMode!),
                    items: ThemeMode.values
                        .map(
                          (m) => DropdownMenuItem(
                            value: m,
                            child: Text("${m.name[0].toUpperCase()}${m.name.substring(1)}"),
                          ),
                        )
                        .toList(),
                  ),

                  _ => const CircularProgressIndicator(),
                },
              ),
            ),
            ListTile(
              title: Text("Show time"),
              trailing: Consumer(
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
        ),
      ),
    );
  }
}
