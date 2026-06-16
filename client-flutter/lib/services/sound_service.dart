import 'package:flutter/services.dart';

class SoundService {
  static const MethodChannel _channel = MethodChannel('ludo_rush/sound');

  static void tap() {
    HapticFeedback.selectionClick();
    _play('tap', SystemSoundType.click);
  }

  static void roll() {
    HapticFeedback.lightImpact();
    _play('roll', SystemSoundType.click);
  }

  static void move() {
    HapticFeedback.mediumImpact();
    _play('move', SystemSoundType.click);
  }

  static void success() {
    HapticFeedback.heavyImpact();
    _play('success', SystemSoundType.alert);
  }

  static void warning() {
    HapticFeedback.vibrate();
    _play('warning', SystemSoundType.alert);
  }

  static void _play(String effect, SystemSoundType fallback) {
    _channel.invokeMethod<void>('play', effect).catchError((_) {
      return SystemSound.play(fallback);
    });
  }
}
