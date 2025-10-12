import 'package:fft_games/settings/global_settings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({super.key});

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
          ],
        ),
      ),
    );
  }
}
