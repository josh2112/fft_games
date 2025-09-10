import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

import '../../settings/persistence/settings_persistence.dart';
import '../../settings/persistence/shared_prefs_persistence.dart';

class SettingsController with ChangeNotifier {
  static final String _prefix = 'Fosterdle';

  static final String _keyHardMode = 'hardMode';

  static final _log = Logger('$_prefix.SettingsController');

  late final version;

  /// The persistence store that is used to save settings.
  final SettingsPersistence _store;

  ValueNotifier<bool> hardMode = ValueNotifier(true);

  SettingsController({SettingsPersistence? store}) : _store = store ?? SharedPrefsPersistence() {
    _load();
  }

  void toggleHardMode() {
    hardMode.value = !hardMode.value;
    _store.setBool("$_prefix.$_keyHardMode", hardMode.value);
  }

  Future<void> _load() async {
    final pubspec = await rootBundle.loadString("pubspec.yaml");
    version = pubspec.split("version: ")[1].split("+")[0];

    final loadedValues = await Future.wait([
      _store.getBool("$_prefix.$_keyHardMode", defaultValue: false).then((value) => hardMode.value = value),
    ]);

    _log.fine(() => 'Loaded settings: $loadedValues');
  }
}
