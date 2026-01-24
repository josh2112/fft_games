import 'settings.dart';
import 'package:fft_games/settings/global_settings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as prov;

class SettingsDialog extends StatelessWidget {
  final SettingsController settings;

  const SettingsDialog(this.settings, {super.key});

  @override
  Widget build(BuildContext context) {
    final globalSettings = context.watch<GlobalSettingsController>();

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
              subtitle: Text("Applies to all games"),
              trailing: ValueListenableBuilder(
                valueListenable: globalSettings.themeMode,
                builder: (context, themeMode, child) => DropdownButton(
                  value: ThemeMode.values[themeMode],
                  onChanged: (v) => globalSettings.themeMode.value = v!.index,
                  items: ThemeMode.values
                      .map(
                        (m) =>
                            DropdownMenuItem(value: m, child: Text("${m.name[0].toUpperCase()}${m.name.substring(1)}")),
                      )
                      .toList(),
                ),
              ),
            ),
            ListTile(
              title: Text("Show time"),
              trailing: ValueListenableBuilder(
                valueListenable: settings.showTime,
                builder: (context, showTime, child) =>
                    Switch(value: showTime, onChanged: (v) => settings.showTime.value = v),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
