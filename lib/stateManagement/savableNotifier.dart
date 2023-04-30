
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class SavableNotifier<T> extends ValueNotifier<T> {
  final String key;
  static late final SharedPreferences _prefs;

  SavableNotifier(this.key, T fallback) : super(fallback) {
    value = _readValue();
  }

  static void init(SharedPreferences prefs) {
    SavableNotifier._prefs = prefs;
  }

  T _readValue();
  void _saveValue(T value);

  @override
  set value(T newValue) {
    if (value == newValue)
      return;
    super.value = newValue;
    _saveValue(newValue);
  }
}

class SavableNotifierString extends SavableNotifier<String> {
  SavableNotifierString(String key, String fallback)
      : super(key, fallback);

  @override
  String _readValue() => SavableNotifier._prefs.getString(key) ?? "";

  @override
  void _saveValue(String value) => SavableNotifier._prefs.setString(key, value);
}
