import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ludo_string_keys.dart';

/// Loads the Android resources translated by Google Play for this install.
/// A local or non-Android build safely falls back to the English source copy.
class LudoStrings extends ChangeNotifier with WidgetsBindingObserver {
  LudoStrings._();

  static final LudoStrings instance = LudoStrings._();
  static const MethodChannel _channel = MethodChannel('ludo_rush/app');

  Map<String, String> _translated = const {};

  Future<void> load() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final values = await _channel.invokeMapMethod<String, String>(
        'getUiStrings',
      );
      if (values == null) return;
      _translated = Map<String, String>.unmodifiable(values);
      notifyListeners();
    } on PlatformException {
      // English remains available if the native bridge cannot be reached.
    } on MissingPluginException {
      // Flutter tests and non-Play builds need no translated resources.
    }
  }

  void watchDeviceLocale() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    unawaited(load());
  }

  String translate(String source) {
    final key = ludoStringKeys[source];
    return key == null ? source : (_translated[key] ?? source);
  }
}

class LudoStringsScope extends InheritedNotifier<LudoStrings> {
  const LudoStringsScope({
    super.key,
    required super.notifier,
    required super.child,
  });

  static String translate(BuildContext context, String source) {
    final strings =
        context
            .dependOnInheritedWidgetOfExactType<LudoStringsScope>()
            ?.notifier ??
        LudoStrings.instance;
    return strings.translate(source);
  }
}
