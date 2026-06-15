import 'package:flutter/services.dart';

class SoundService {
  static void tap() {
    HapticFeedback.selectionClick();
    SystemSound.play(SystemSoundType.click);
  }

  static void roll() {
    HapticFeedback.lightImpact();
    SystemSound.play(SystemSoundType.click);
  }

  static void move() {
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);
  }

  static void success() {
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.alert);
  }

  static void warning() {
    HapticFeedback.vibrate();
    SystemSound.play(SystemSoundType.alert);
  }
}
