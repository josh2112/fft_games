/// YARSP. Yet Another Riverpod Shared Preferences.
///
/// To use, choose the provider that matches your preference data type and parameterize it
/// with the preference key. For example:
/// ```
/// Consumer( builder: (context, ref, child) {
///   return ref
///       .watch(stringSharedPreferenceProvider('username'))
///       .when(
///         data: (username) => Text(username),
///         loading: () => const CircularProgressIndicator(),
///         error: (e, _) => Text("Can't read username!"),
///       );
///   },
/// )
/// ```
/// To set a new value, grab the notifier directly:
/// ```
/// TextButton(
///   onPressed: () => ref.read(stringSharedPreferenceProvider('username').notifier).setValue('bob'),
///   child: Text("Set username"),
/// );
/// ```
/// To establish a default value for a preference, register it at app startup:
/// ```
/// SharedPreferencesRegistry.registerPreference<String>('username', '');
/// ```
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final stringSharedPreferenceProvider = AsyncNotifierProvider.autoDispose.family(SharedPreferenceStringNotifier.new);
final boolSharedPreferenceProvider = AsyncNotifierProvider.autoDispose.family(SharedPreferenceBoolNotifier.new);
final doubleSharedPreferenceProvider = AsyncNotifierProvider.autoDispose.family(SharedPreferenceDoubleNotifier.new);
final intSharedPreferenceProvider = AsyncNotifierProvider.autoDispose.family(SharedPreferenceIntNotifier.new);
final stringListSharedPreferenceProvider = AsyncNotifierProvider.autoDispose.family(
  SharedPreferenceStringListNotifier.new,
);

class SharedPreferencesRegistry {
  static final _types = <String, Type>{};
  static final _defaults = <String, dynamic>{};

  static void registerPreference<T>(String key, dynamic defaultValue) {
    if (defaultValue is! T && defaultValue is! T Function()) {
      throw Exception("Default value must be of type $T or $T Function()");
    }
    _types[key] = T;
    _defaults[key] = defaultValue;
  }
}

abstract class SharedPreferenceNotifier<T> extends AsyncNotifier<T> {
  final String key;

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  SharedPreferenceNotifier(this.key);

  @override
  Future<T> build() async {
    // If we have a value, return it
    final val = await _get(key);
    if (val != null) return val;

    // Preference doesn't exist yet. Get default value (if provided)
    // and set it.
    final def = SharedPreferencesRegistry._defaults[key];

    try {
      final val = def is T ? def : def() as T;
      await _set(key, val);
      return val;
    } catch (_) {
      throw Exception("Preference '$key' does not exist and no default value provided");
    }
  }

  Future<void> setValue(T newValue) async {
    await _set(key, newValue);
    state = AsyncData(newValue);
  }

  Future<T?> _get(String key);

  Future<void> _set(String key, T value);
}

class SharedPreferenceStringNotifier extends SharedPreferenceNotifier<String> {
  SharedPreferenceStringNotifier(super.key);

  @override
  Future<String?> _get(String key) => super._prefs.getString(key);

  @override
  Future<void> _set(String key, String value) => super._prefs.setString(key, value);
}

class SharedPreferenceBoolNotifier extends SharedPreferenceNotifier<bool> {
  SharedPreferenceBoolNotifier(super.key);

  @override
  Future<bool?> _get(String key) => super._prefs.getBool(key);

  @override
  Future<void> _set(String key, bool value) => super._prefs.setBool(key, value);
}

class SharedPreferenceDoubleNotifier extends SharedPreferenceNotifier<double> {
  SharedPreferenceDoubleNotifier(super.key);

  @override
  Future<double?> _get(String key) => super._prefs.getDouble(key);

  @override
  Future<void> _set(String key, double value) => super._prefs.setDouble(key, value);
}

class SharedPreferenceIntNotifier extends SharedPreferenceNotifier<int> {
  SharedPreferenceIntNotifier(super.key);

  @override
  Future<int?> _get(String key) => super._prefs.getInt(key);

  @override
  Future<void> _set(String key, int value) => super._prefs.setInt(key, value);
}

class SharedPreferenceStringListNotifier extends SharedPreferenceNotifier<List<String>> {
  SharedPreferenceStringListNotifier(super.key);

  @override
  Future<List<String>?> _get(String key) => super._prefs.getStringList(key);

  @override
  Future<void> _set(String key, List<String> value) => super._prefs.setStringList(key, value);

  Future<void> add(String value) async {
    final items = await future;
    if (!items.contains(value)) {
      await setValue([...items, value]);
    }
  }

  Future<void> remove(String value) async {
    final items = await future;
    if (items.contains(value)) {
      await setValue(items.where((i) => i != value).toList());
    }
  }
}

// ----------------------------------------------

final dateTimeSharedPreferenceProvider = AsyncNotifierProvider.autoDispose.family(SharedPreferenceDateTimeNotifier.new);

class SharedPreferenceDateTimeNotifier extends SharedPreferenceNotifier<DateTime> {
  SharedPreferenceDateTimeNotifier(super.key);

  @override
  Future<DateTime?> _get(String key) =>
      super._prefs.getString(key).then((str) => str != null ? DateTime.parse(str) : null);

  @override
  Future<void> _set(String key, DateTime value) => super._prefs.setString(key, value.toIso8601String());
}
