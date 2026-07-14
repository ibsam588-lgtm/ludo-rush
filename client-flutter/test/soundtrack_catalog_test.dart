import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_rush/services/prefs_service.dart';
import 'package:ludo_rush/services/soundtrack_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SoundtrackCatalog', () {
    test('contains six unique playable tracks', () {
      expect(SoundtrackCatalog.ids, hasLength(6));
      expect(SoundtrackCatalog.ids.toSet(), hasLength(6));
      expect(
          SoundtrackCatalog.assets.keys.toSet(), SoundtrackCatalog.ids.toSet());
      expect(SoundtrackCatalog.assets.values.toSet(), hasLength(6));
    });

    test('uses Victory Spark at a restrained default volume', () {
      expect(SoundtrackCatalog.defaultId, SoundtrackCatalog.victorySpark);
      expect(SoundtrackCatalog.defaultVolume, 0.28);
    });

    test('fresh installs start with Victory Spark and music enabled', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = PrefsService();
      await preferences.init();

      expect(preferences.soundtrackId, SoundtrackCatalog.victorySpark);
      expect(preferences.musicEnabled, isTrue);
    });

    test('keeps canonical soundtrack selections', () {
      for (final id in SoundtrackCatalog.ids) {
        expect(SoundtrackCatalog.normalize(id), id);
      }
    });

    test('migrates the original soundtrack selections', () {
      expect(
        SoundtrackCatalog.normalize('crown_circuit'),
        SoundtrackCatalog.royalAdventure,
      );
      expect(
        SoundtrackCatalog.normalize('neon_dash'),
        SoundtrackCatalog.luckyDiceDance,
      );
      expect(
        SoundtrackCatalog.normalize('carnival_hop'),
        SoundtrackCatalog.starlightBoardwalk,
      );
    });

    test('falls back to the default soundtrack for unknown values', () {
      expect(
        SoundtrackCatalog.normalize('missing_track'),
        SoundtrackCatalog.defaultId,
      );
    });

    test('player applies volume, selection, lifecycle, and disposal safely',
        () async {
      final audio = _FakeSoundtrackAudio();
      final service = SoundtrackService(audio: audio);

      await service.configure(
        track: SoundtrackCatalog.victorySpark,
        enabled: true,
      );
      expect(audio.loopingCalls, 1);
      expect(audio.volumes, [SoundtrackCatalog.defaultVolume]);
      expect(audio.playedAssets, [
        SoundtrackCatalog.assets[SoundtrackCatalog.victorySpark],
      ]);

      await service.select(SoundtrackCatalog.carnivalCrown);
      await service.pauseForLifecycle();
      await service.resumeAfterLifecycle();
      await service.setEnabled(false);

      expect(audio.playedAssets.last,
          SoundtrackCatalog.assets[SoundtrackCatalog.carnivalCrown]);
      expect(audio.pauseCalls, 1);
      expect(audio.resumeCalls, 1);
      expect(audio.stopCalls, 1);

      await service.dispose();
      await service.dispose();
      await service.select(SoundtrackCatalog.royalAdventure);

      expect(audio.disposeCalls, 1);
      expect(audio.playedAssets, hasLength(2));
    });

    test('a lifecycle pause waits for pending startup playback', () async {
      final audio = _FakeSoundtrackAudio();
      final service = SoundtrackService(audio: audio);

      final startup = service.configure(
        track: SoundtrackCatalog.victorySpark,
        enabled: true,
      );
      final pause = service.pauseForLifecycle();
      await Future.wait([startup, pause]);

      expect(audio.playedAssets, hasLength(1));
      expect(audio.pauseCalls, 1);
      await service.dispose();
    });
  });
}

class _FakeSoundtrackAudio implements SoundtrackAudio {
  int loopingCalls = 0;
  int stopCalls = 0;
  int pauseCalls = 0;
  int resumeCalls = 0;
  int disposeCalls = 0;
  final List<double> volumes = [];
  final List<String> playedAssets = [];

  @override
  Future<void> setLooping() async => loopingCalls++;

  @override
  Future<void> setVolume(double volume) async => volumes.add(volume);

  @override
  Future<void> playAsset(String asset, double volume) async {
    playedAssets.add(asset);
  }

  @override
  Future<void> stop() async => stopCalls++;

  @override
  Future<void> pause() async => pauseCalls++;

  @override
  Future<void> resume() async => resumeCalls++;

  @override
  Future<void> dispose() async => disposeCalls++;
}
