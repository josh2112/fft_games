import 'dart:convert';

import 'package:fft_games/settings/persistence/settings_persistence.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

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

  JsonSetting(this.key, this.store, this.convert, this.defaultValue, {this.log})
    : super(defaultValue) {
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

  Future<T> _load() => store
      .getString(key, defaultValue: '')
      .then((str) => str.isEmpty ? defaultValue : convert(jsonDecode(str)));

  Future<void> _save() => store.setString(key, jsonEncode(value));
}
