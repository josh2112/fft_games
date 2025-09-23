import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import '../../settings/persistence/settings_persistence.dart';
import '../../settings/persistence/shared_prefs_persistence.dart';

class Setting<T> extends ValueNotifier<T> {
  final String key;

  bool _isLoaded = false;

  final T defaultValue;

  final SettingsPersistence store;
  final Logger? log;

  Setting(this.key, this.store, this.defaultValue, {this.log}) : super(defaultValue) {
    _load().then((t) {
      value = t;
      log?.fine(() => 'Loaded setting $key => $value');
      _isLoaded = true;
    });
  }

  @override
  set value(T newValue) {
    super.value = newValue;
    if (_isLoaded) {
      _save().then((_) => log?.fine("Saved setting $key to $value"));
    }
  }

  Future<T> _load() {
    return switch (defaultValue) {
      int() => store.getInt(key, defaultValue: defaultValue as int) as Future<T>,
      bool() => store.getBool(key, defaultValue: defaultValue as bool) as Future<T>,
      String _ => store.getString(key, defaultValue: defaultValue as String) as Future<T>,
      _ => throw ("Cannot get a setting with type ${T.runtimeType}"),
    };
  }

  Future<void> _save() {
    return switch (defaultValue) {
      int() => store.setInt(key, value as int),
      bool() => store.setBool(key, value as bool),
      String _ => store.setString(key, value as String),
      _ => throw ("Cannot set a setting with type ${T.runtimeType}"),
    };
  }
}

class JsonSetting<T> extends ValueNotifier<T> {
  final String key;

  bool _isLoaded = false;

  final T defaultValue;
  final T Function(dynamic) convert;

  final SettingsPersistence store;
  final Logger? log;

  JsonSetting(this.key, this.store, this.convert, this.defaultValue, {this.log}) : super(defaultValue) {
    _load().then((t) {
      value = t;
      log?.fine(() => 'Loaded setting $key => $value');
      _isLoaded = true;
    });
  }

  @override
  set value(T newValue) {
    if (super.value != newValue) {
      super.value = newValue;
      if (_isLoaded) {
        _save().then((_) => log?.fine("Saved setting $key to $value"));
      }
    }
  }

  Future<T> _load() =>
      store.getString(key, defaultValue: '').then((str) => str.isEmpty ? defaultValue : convert(jsonDecode(str)));

  Future<void> _save() => store.setString(key, jsonEncode(value));
}

class SettingsController {
  static final String _prefix = 'Fosterdle';

  static final _log = Logger('$_prefix.SettingsController');

  final SettingsPersistence _store;

  late final Setting<bool> isHardMode;
  late final JsonSetting<List<int>> solveCounts;
  late final Setting<int> numPlayed;
  late final Setting<int> numWon;
  late final Setting<int> currentStreak;
  late final Setting<int> maxStreak;

  SettingsController({SettingsPersistence? store}) : _store = store ?? SharedPrefsPersistence() {
    isHardMode = Setting("$_prefix.hardMode", _store, false, log: _log);
    numPlayed = Setting("$_prefix.numPlayed", _store, 0, log: _log);
    numWon = Setting("$_prefix.numWon", _store, 0, log: _log);
    currentStreak = Setting("$_prefix.currentStreak", _store, 0, log: _log);
    maxStreak = Setting("$_prefix.maxStreak", _store, 0, log: _log);
    solveCounts = JsonSetting("$_prefix.solveCounts", _store, (obj) => List<int>.from(obj), [
      0,
      0,
      0,
      0,
      0,
      0,
    ], log: _log);
  }
}
