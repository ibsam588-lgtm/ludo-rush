import 'package:audioplayers/audioplayers.dart';

abstract interface class SoundtrackAudio {
  Future<void> setLooping();

  Future<void> setVolume(double volume);

  Future<void> playAsset(String asset, double volume);

  Future<void> stop();

  Future<void> pause();

  Future<void> resume();

  Future<void> dispose();
}

class AudioplayersSoundtrackAudio implements SoundtrackAudio {
  final AudioPlayer _player;

  AudioplayersSoundtrackAudio({AudioPlayer? player})
      : _player = player ?? AudioPlayer();

  @override
  Future<void> setLooping() => _player.setReleaseMode(ReleaseMode.loop);

  @override
  Future<void> setVolume(double volume) => _player.setVolume(volume);

  @override
  Future<void> playAsset(String asset, double volume) => _player.play(
        AssetSource(asset),
        volume: volume,
        position: Duration.zero,
      );

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> resume() => _player.resume();

  @override
  Future<void> dispose() => _player.dispose();
}

abstract final class SoundtrackCatalog {
  static const royalAdventure = 'royal_adventure';
  static const luckyDiceDance = 'lucky_dice_dance';
  static const starlightBoardwalk = 'starlight_boardwalk';
  static const diceParade = 'dice_parade';
  static const victorySpark = 'victory_spark';
  static const carnivalCrown = 'carnival_crown';
  static const defaultId = victorySpark;
  static const defaultVolume = 0.28;

  static const ids = [
    victorySpark,
    royalAdventure,
    luckyDiceDance,
    starlightBoardwalk,
    diceParade,
    carnivalCrown,
  ];

  static const assets = {
    royalAdventure: 'audio/music-royal-adventure.mp3',
    luckyDiceDance: 'audio/music-lucky-dice-dance.mp3',
    starlightBoardwalk: 'audio/music-starlight-boardwalk.mp3',
    diceParade: 'audio/music-dice-parade.mp3',
    victorySpark: 'audio/music-victory-spark.mp3',
    carnivalCrown: 'audio/music-carnival-crown.mp3',
  };

  static const _legacyIds = {
    'crown_circuit': royalAdventure,
    'neon_dash': luckyDiceDance,
    'carnival_hop': starlightBoardwalk,
  };

  static String normalize(String value) =>
      ids.contains(value) ? value : _legacyIds[value] ?? defaultId;
}

class SoundtrackService {
  SoundtrackAudio? _audio;
  String _track = SoundtrackCatalog.defaultId;
  bool _enabled = true;
  bool _configured = false;
  bool _pausedByLifecycle = false;
  bool _disposed = false;
  Future<void> _pendingOperation = Future.value();

  SoundtrackService({SoundtrackAudio? audio}) : _audio = audio;

  SoundtrackAudio get _output => _audio ??= AudioplayersSoundtrackAudio();

  Future<void> configure({
    required String track,
    required bool enabled,
  }) {
    _track = SoundtrackCatalog.normalize(track);
    _enabled = enabled;
    return _enqueue(() async {
      if (!_enabled) {
        _pausedByLifecycle = false;
        if (_configured) await _output.stop();
        return;
      }
      if (!_configured) {
        await _output.setLooping();
        await _output.setVolume(SoundtrackCatalog.defaultVolume);
        _configured = true;
      }
      _pausedByLifecycle = false;
      await _playSelectedTrack();
    });
  }

  Future<void> select(String track) {
    _track = SoundtrackCatalog.normalize(track);
    _enabled = true;
    _pausedByLifecycle = false;
    return _enqueue(() async {
      if (!_configured) {
        await _output.setLooping();
        await _output.setVolume(SoundtrackCatalog.defaultVolume);
        _configured = true;
      }
      await _playSelectedTrack();
    });
  }

  Future<void> setEnabled(bool enabled) => configure(
        track: _track,
        enabled: enabled,
      );

  Future<void> pauseForLifecycle() {
    if (!_enabled) return Future.value();
    return _enqueue(() async {
      if (!_enabled || !_configured) return;
      await _output.pause();
      _pausedByLifecycle = true;
    });
  }

  Future<void> resumeAfterLifecycle() {
    if (!_enabled) return Future.value();
    return _enqueue(() async {
      if (!_enabled || !_configured) return;
      if (_pausedByLifecycle) {
        await _output.resume();
      } else {
        await _playSelectedTrack();
      }
      _pausedByLifecycle = false;
    });
  }

  Future<void> _playSelectedTrack() => _output.playAsset(
        SoundtrackCatalog.assets[_track]!,
        SoundtrackCatalog.defaultVolume,
      );

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _pendingOperation;
    await _audio?.dispose();
    _audio = null;
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    if (_disposed) return Future.value();
    final next = _pendingOperation.then((_) async {
      if (_disposed) return;
      try {
        await operation();
      } catch (_) {
        // Browsers can reject autoplay and platforms can briefly lose focus.
      }
    });
    _pendingOperation = next;
    return next;
  }
}
