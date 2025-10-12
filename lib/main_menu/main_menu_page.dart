import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Foster Family Times Games',
          style: TextTheme.of(context).headlineLarge!.apply(fontFamily: 'FacultyGlyphic'),
        ),
        centerTitle: true,
        actions: [
          IconButton(onPressed: () => showDialogOrBottomSheet(context, SettingsDialog()), icon: Icon(Icons.settings)),
        ],
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.center,
                  child: FilledButton(
                    onPressed: () {
                      context.go('/fosterdle');
                    },
                    child: const Text('Fosterdle'),
                  ),
                ),
              ),
              Opacity(opacity: 0.5, child: Text("Version $_version\t${(isRunningWithWasm ? 'WASM enabled' : '')}")),
            ],
          ),
        ),
      ),
    );
  }
}
