import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:ludo_rush/services/voice_chat_service.dart';
import 'package:ludo_rush/services/websocket_service.dart';

class _TestAudioTrack extends Fake implements MediaStreamTrack {
  bool stopped = false;

  @override
  bool enabled = true;

  @override
  Future<void> stop() async {
    stopped = true;
  }
}

class _TestMicrophone extends Fake implements MediaStream {
  _TestMicrophone(this.track);

  final _TestAudioTrack track;
  bool disposed = false;

  @override
  List<MediaStreamTrack> getTracks() => [track];

  @override
  List<MediaStreamTrack> getAudioTracks() => [track];

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

void main() {
  test('solo table can enable, mute, and release its microphone', () async {
    final track = _TestAudioTrack();
    final microphone = _TestMicrophone(track);
    final socket = WebSocketService();
    final voice =
        VoiceChatService(socket, microphoneCapture: () async => microphone);

    await voice.joinLocal(playerId: 'player_me');
    expect(voice.joined, isTrue);
    expect(voice.participants, {'player_me'});
    expect(voice.error, isNull);

    voice.onSocketDisconnected();
    expect(voice.joined, isTrue);
    voice.setMuted(true);
    expect(track.enabled, isFalse);
    voice.setPeerMuted('player_two', true);
    expect(voice.mutedPlayerIds, contains('player_two'));
    await voice.onPeerBlocked('player_two');
    expect(voice.blockedPlayerIds, contains('player_two'));
    expect(voice.mutedPlayerIds, isNot(contains('player_two')));

    await voice.leave();
    expect(voice.joined, isFalse);
    expect(voice.participants, isEmpty);
    expect(voice.blockedPlayerIds, isEmpty);
    expect(track.stopped, isTrue);
    expect(microphone.disposed, isTrue);
    voice.dispose();
    socket.dispose();
  });

  test('microphone permission failure leaves solo voice off', () async {
    final socket = WebSocketService();
    final voice = VoiceChatService(socket,
        microphoneCapture: () async => throw StateError('permission denied'));

    await voice.joinLocal(playerId: 'player_me');
    expect(voice.joined, isFalse);
    expect(voice.error, contains('Microphone unavailable'));
    voice.dispose();
    socket.dispose();
  });
}
