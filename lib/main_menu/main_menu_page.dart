import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../utils/dialog_or_bottom_sheet.dart';
import 'settings_dialog.dart';

class MainMenuPage extends StatefulWidget {
  const MainMenuPage({super.key});

  @override
  State<MainMenuPage> createState() => _MainMenuPageState();
}

class _MainMenuPageState extends State<MainMenuPage> {
  String _version = "";

  static const isRunningWithWasm = bool.fromEnvironment('dart.tool.dart2wasm');

  @override
  void initState() {
    super.initState();

    DefaultAssetBundle.of(
      context,
    ).loadString("pubspec.yaml").then((f) => setState(() => _version = f.split("version: ")[1].split("\n")[0]));
  }

  // , icon:
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.only(top: 40, bottom: 20, left: 20, right: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Foster Family Times Games', style: TextTheme.of(context).titleLarge, textAlign: TextAlign.center),
              Expanded(
                child: Transform.scale(
                  scale: 1.5,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 20,
                    children: [
                      FilledButton.icon(
                        onPressed: () {
                          context.go('/fosterdle');
                        },
                        label: Text('Fosterdle'),
                        icon: Icon(Icons.grid_on),
                      ),
                      if (kDebugMode)
                        FilledButton.icon(
                          onPressed: () {
                            context.go('/fosteroes');
                          },
                          label: Text('Fosteroes'),
                          icon: Icon(Symbols.background_dot_large),
                        ),
                    ],
                  ),
                ),
              ),

              Builder(
                builder: (context) => OutlinedButton.icon(
                  onPressed: () => showDialogOrBottomSheet(context, SettingsDialog()),
                  label: Text("Settings"),
                  icon: Icon(Icons.settings),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 20),
                child: Opacity(
                  opacity: 0.5,
                  child: Text("Version $_version\t${(isRunningWithWasm ? 'WASM enabled' : '')}"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
