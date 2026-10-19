import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;

import 'websocket_service.dart';

class _VoicePeer {
  _VoicePeer(this.connection, this.renderer);
  final RTCPeerConnection connection;
  final RTCVideoRenderer renderer;
  final List<RTCIceCandidate> pendingCandidates = [];
  bool remoteDescriptionReady = false;

  Future<void> close() async {
    await connection.close();
    renderer.srcObject = null;
    await renderer.dispose();
  }
}

/// Opt-in, audio-only WebRTC mesh for the human seats at the current table.
/// SDP/ICE travel through the authenticated room socket; media is never sent
/// through the game backend or recorded by the app.
class VoiceChatService extends ChangeNotifier {
  VoiceChatService(this._socket);

  static const _backendUrl = 'https://ludo-rush-backend.ibsam588.workers.dev';
  final WebSocketService _socket;
  final Map<String, _VoicePeer> _peers = {};
  final Map<String, Future<_VoicePeer>> _openingPeers = {};
  final Set<String> _offering = {};
  MediaStream? _microphone;
  List<dynamic> _iceServers = const [];
  String? _roomId;
  String? _playerId;
  bool joined = false;
  bool joining = false;
  bool muted = false;
  String? error;
  Set<String> participants = const {};
  bool _disposed = false;
  bool _announceOnSnapshot = false;
  bool _confirmedJoined = false;
  int _generation = 0;

  Future<void> join(
      {required String roomId,
      required String playerId,
      required String authToken}) async {
    if (joined || joining) return;
    if (!_socket.isConnected) {
      error = 'Reconnect to the match before joining voice.';
      notifyListeners();
      return;
    }
    joining = true;
    final generation = ++_generation;
    error = null;
    notifyListeners();
    try {
      final response = await http.get(
          Uri.parse('$_backendUrl/api/v1/voice/ice')
              .replace(queryParameters: {'roomId': roomId}),
          headers: {
            'authorization': 'Bearer $authToken'
          }).timeout(const Duration(seconds: 8));
      if (generation != _generation) return;
      if (response.statusCode != 200)
        throw StateError('Voice connection is unavailable.');
      final config = jsonDecode(response.body) as Map<String, dynamic>;
      _iceServers = config['iceServers'] as List<dynamic>? ?? const [];
      if (_iceServers.isEmpty)
        throw StateError('Voice server is not configured.');
      final microphone = await navigator.mediaDevices.getUserMedia({
        'audio': {'echoCancellation': true, 'noiseSuppression': true},
        'video': false,
      });
      if (generation != _generation) {
        for (final track in microphone.getTracks()) {
          track.stop();
        }
        await microphone.dispose();
        return;
      }
      _microphone = microphone;
      try {
        await Helper.setSpeakerphoneOnButPreferBluetooth();
      } catch (_) {/* Device route is optional. */}
      if (generation != _generation) return;
      _roomId = roomId;
      _playerId = playerId;
      joined = true;
      _confirmedJoined = false;
      muted = false;
      _socket.send({'type': 'voice_join'});
      _announceOnSnapshot = false;
    } catch (e) {
      if (generation == _generation) {
        error = e is StateError
            ? e.message
            : 'Microphone unavailable. Check permission and try again.';
        await leave();
      }
    } finally {
      if (generation == _generation) {
        joining = false;
        if (!_disposed) notifyListeners();
      }
    }
  }

  void onRoomSnapshot(String roomId, bool playing) {
    if (_roomId != null && (_roomId != roomId || !playing)) {
      unawaited(leave());
    } else if (joined && _socket.isConnected && _announceOnSnapshot) {
      // A reconnection creates a new socket attachment; rejoin voice after the
      // ordinary room join has been processed.
      _socket.send({'type': 'voice_join'});
      _announceOnSnapshot = false;
    }
  }

  void onSocketDisconnected() {
    if (joining) {
      unawaited(leave());
      return;
    }
    if (joined) {
      ++_generation;
      _announceOnSnapshot = true;
      _confirmedJoined = false;
      participants = const {};
      _openingPeers.clear();
      _offering.clear();
      for (final id in _peers.keys.toList()) {
        unawaited(_removePeer(id));
      }
      if (!_disposed) notifyListeners();
    }
  }

  void reportError(String message) {
    error = message;
    unawaited(leave());
  }

  Future<void> onVoiceState(Iterable<String> playerIds) async {
    if (!joined || _playerId == null) return;
    final next = playerIds.toSet();
    participants = next;
    if (!next.contains(_playerId)) {
      if (_confirmedJoined)
        reportError('You left table voice. Tap Join to reconnect.');
      if (!_disposed) notifyListeners();
      return;
    }
    _confirmedJoined = true;
    for (final id in _peers.keys.toList()) {
      if (!next.contains(id)) await _removePeer(id);
    }
    for (final id in next) {
      if (id == _playerId || _peers.containsKey(id) || _offering.contains(id))
        continue;
      if (_playerId!.compareTo(id) < 0) await _offer(id);
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> onSignal(
      String fromPlayerId, Map<String, dynamic> signal) async {
    if (!joined ||
        fromPlayerId == _playerId ||
        !participants.contains(fromPlayerId)) return;
    try {
      final type = signal['type'] as String?;
      if (type == 'offer') {
        final peer = await _getPeer(fromPlayerId);
        await peer.connection.setRemoteDescription(
            RTCSessionDescription(signal['sdp'] as String?, 'offer'));
        peer.remoteDescriptionReady = true;
        await _flushCandidates(peer);
        final answer = await peer.connection.createAnswer();
        await peer.connection.setLocalDescription(answer);
        _sendSignal(fromPlayerId, {'type': 'answer', 'sdp': answer.sdp});
      } else if (type == 'answer') {
        final peer = _peers[fromPlayerId];
        if (peer == null) return;
        await peer.connection.setRemoteDescription(
            RTCSessionDescription(signal['sdp'] as String?, 'answer'));
        peer.remoteDescriptionReady = true;
        await _flushCandidates(peer);
      } else if (type == 'candidate') {
        final peer = await _getPeer(fromPlayerId);
        final candidate = RTCIceCandidate(
            signal['candidate'] as String?,
            signal['sdpMid'] as String?,
            (signal['sdpMLineIndex'] as num?)?.toInt());
        if (peer.remoteDescriptionReady) {
          await peer.connection.addCandidate(candidate);
        } else {
          peer.pendingCandidates.add(candidate);
        }
      }
    } catch (_) {
      error = 'Voice connection failed. Leave and rejoin voice to retry.';
      if (!_disposed) notifyListeners();
    }
  }

  void setMuted(bool value) {
    muted = value;
    for (final track in _microphone?.getAudioTracks() ?? <MediaStreamTrack>[]) {
      track.enabled = !value;
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> leave() async {
    ++_generation;
    if (joined && _socket.isConnected) _socket.send({'type': 'voice_leave'});
    joined = false;
    _confirmedJoined = false;
    joining = false;
    _announceOnSnapshot = false;
    participants = const {};
    final microphone = _microphone;
    _microphone = null;
    for (final track in microphone?.getTracks() ?? <MediaStreamTrack>[]) {
      track.stop();
    }
    final peers = _peers.values.toList();
    _peers.clear();
    _openingPeers.clear();
    _offering.clear();
    if (!_disposed) notifyListeners();
    for (final peer in peers) await peer.close();
    await microphone?.dispose();
    _roomId = null;
    _playerId = null;
    if (!_disposed) notifyListeners();
  }

  Future<_VoicePeer> _getPeer(String playerId) async {
    final existing = _peers[playerId];
    if (existing != null) return existing;
    final opening = _openingPeers[playerId];
    if (opening != null) return opening;
    final future = _openPeer(playerId);
    _openingPeers[playerId] = future;
    try {
      return await future;
    } finally {
      if (identical(_openingPeers[playerId], future))
        _openingPeers.remove(playerId);
    }
  }

  Future<_VoicePeer> _openPeer(String playerId) async {
    final generation = _generation;
    final renderer = RTCVideoRenderer();
    await renderer.initialize();
    final connection = await createPeerConnection(
        {'iceServers': _iceServers, 'sdpSemantics': 'unified-plan'});
    final peer = _VoicePeer(connection, renderer);
    if (!joined || generation != _generation) {
      await peer.close();
      throw StateError('Voice session ended.');
    }
    _peers[playerId] = peer;
    connection.onIceCandidate = (candidate) {
      if (candidate.candidate != null) {
        _sendSignal(playerId, {
          'type': 'candidate',
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex
        });
      }
    };
    connection.onTrack = (event) {
      if (event.streams.isNotEmpty) renderer.srcObject = event.streams.first;
    };
    for (final track in _microphone?.getAudioTracks() ?? <MediaStreamTrack>[]) {
      await connection.addTrack(track, _microphone!);
    }
    return peer;
  }

  Future<void> _offer(String playerId) async {
    if (!_offering.add(playerId)) return;
    try {
      final peer = await _getPeer(playerId);
      final offer = await peer.connection.createOffer();
      await peer.connection.setLocalDescription(offer);
      _sendSignal(playerId, {'type': 'offer', 'sdp': offer.sdp});
    } catch (_) {
      error = 'Could not connect to another player’s voice.';
      if (!_disposed) notifyListeners();
    } finally {
      _offering.remove(playerId);
    }
  }

  Future<void> _flushCandidates(_VoicePeer peer) async {
    for (final candidate in peer.pendingCandidates) {
      await peer.connection.addCandidate(candidate);
    }
    peer.pendingCandidates.clear();
  }

  void _sendSignal(String playerId, Map<String, dynamic> signal) {
    if (joined && _socket.isConnected) {
      _socket.send(
          {'type': 'voice_signal', 'toPlayerId': playerId, 'signal': signal});
    }
  }

  Future<void> _removePeer(String playerId) async {
    final peer = _peers.remove(playerId);
    await peer?.close();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(leave());
    super.dispose();
  }
}
