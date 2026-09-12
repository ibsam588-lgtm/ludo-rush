import 'package:flutter/services.dart';

class SoundService {
  static const MethodChannel _channel = MethodChannel('ludo_rush/sound');
  static bool soundEnabled = true;
  static bool hapticsEnabled = true;

  static void configure({required bool sound, required bool haptics}) {
    soundEnabled = sound;
    hapticsEnabled = haptics;
  }

  static void tap() {
    if (hapticsEnabled) HapticFeedback.selectionClick();
    _play('tap', SystemSoundType.click);
  }

  static void roll() {
    if (hapticsEnabled) HapticFeedback.lightImpact();
    _play('roll', SystemSoundType.click);
  }

  static void move() {
    if (hapticsEnabled) HapticFeedback.mediumImpact();
    _play('move', SystemSoundType.click);
  }

  static void success() {
    if (hapticsEnabled) HapticFeedback.heavyImpact();
    _play('success', SystemSoundType.alert);
  }

  static void warning() {
    if (hapticsEnabled) HapticFeedback.vibrate();
    _play('warning', SystemSoundType.alert);
  }

  static void ladder() {
    if (hapticsEnabled) HapticFeedback.heavyImpact();
    _play('ladder', SystemSoundType.alert);
  }

  static void snake() {
    if (hapticsEnabled) HapticFeedback.vibrate();
    _play('snake', SystemSoundType.alert);
  }

  static void turn() {
    if (hapticsEnabled) HapticFeedback.selectionClick();
    _play('turn', SystemSoundType.click);
  }

  static void _play(String effect, SystemSoundType fallback) {
    if (!soundEnabled) return;
    _channel.invokeMethod<void>('play', effect).catchError((_) {
      return SystemSound.play(fallback);
    });
  }
}
