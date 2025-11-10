import 'dart:async';

import 'package:fft_games/settings/persistence/settings_persistence.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

class SettingSerializer<T> {
  final String Function(T obj) serialize;
  final T Function(String) deserialize;

  const SettingSerializer(this.serialize, this.deserialize);

  static SettingSerializer<DateTime> dateTime = SettingSerializer(
    (date) => date.toIso8601String(),
    (str) => DateTime.parse(str),
  );
}

class Setting<T> extends ValueNotifier<T> {
  final String key;

  final _loadCompleter = Completer<T>();

  final SettingSerializer<T>? serializer;

  final T defaultValue;

  final SettingsPersistence store;
  final Logger? log;

  Future<T> get isLoaded => _loadCompleter.future;

  Setting(this.key, this.store, this.defaultValue, {this.serializer, this.log}) : super(defaultValue) {
    _load().then((v) => _loadCompleter.complete(v));
  }

  @override
  set value(T newValue) {
    if (super.value != newValue) {
      super.value = newValue;
      if (_loadCompleter.isCompleted) {
        _save().then((_) => log?.fine("Saved setting $key to $value"));
      }
    }
  }

  Future<T> _load() async {
    if (serializer != null) {
      value = await store
          .getString(key, defaultValue: '')
          .then((str) => str.isEmpty ? defaultValue : serializer!.deserialize(str));
    } else {
      value = await switch (defaultValue) {
        int() => store.getInt(key, defaultValue: defaultValue as int) as Future<T>,
        bool() => store.getBool(key, defaultValue: defaultValue as bool) as Future<T>,
        String _ => store.getString(key, defaultValue: defaultValue as String) as Future<T>,
        _ => throw ("Cannot get a setting with type ${T.runtimeType}"),
      };
    }
    log?.fine(() => 'Loaded setting $key => $value');
    return value;
  }

  Future _save() {
    if (serializer != null) {
      return store.setString(key, serializer!.serialize(value));
    } else {
      return switch (defaultValue) {
        int() => store.setInt(key, value as int),
        bool() => store.setBool(key, value as bool),
        String _ => store.setString(key, value as String),
        _ => throw ("Cannot set a setting with type ${T.runtimeType}"),
      };
    }
  }
}
