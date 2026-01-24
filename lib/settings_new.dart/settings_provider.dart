// With notifiers providers, we also use ".family" and receive and extra
// generic argument.
// The main difference is that the associated Notifier needs to define
// a constructor+field to accept the argument.

import 'dart:async';

import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KeyNotFoundException implements Exception {
  final String key;

  KeyNotFoundException(this.key);

  @override
  String toString() => 'KeyNotFoundException: Key "$key" not found in SharedPreferences.';
}

typedef PrefKeyWithDefaultValue = ({String key, bool? defaultValue});

class SharedPreferenceBoolNotifier extends AsyncNotifier<bool> {
  final PrefKeyWithDefaultValue key;

  final SharedPreferencesAsync prefs = SharedPreferencesAsync();

  SharedPreferenceBoolNotifier(this.key);

  @override
  Future<bool> build() async {
    try {
      final val = await prefs.getBool(key.key);
      if (val != null) return val;
    } catch (_) {}

    if (key.defaultValue != null) {
      await prefs.setBool(key.key, key.defaultValue!);
      return key.defaultValue!;
    } else {
      throw KeyNotFoundException(key.key);
    }
  }

  Future<void> setValue(bool newValue) async {
    await prefs.setBool(key.key, newValue);
    state = AsyncData(newValue);
  }
}

final sharedPreferenceProvider = AsyncNotifierProvider.autoDispose
    .family<SharedPreferenceBoolNotifier, bool, PrefKeyWithDefaultValue>(SharedPreferenceBoolNotifier.new);
