import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/game_snapshot.dart';
import '../services/prefs_service.dart';
import '../services/sound_service.dart';
import '../services/websocket_service.dart';

class AppState extends ChangeNotifier {
  static const String _backendUrl =
      'https://ludo-rush-backend.ibsam588.workers.dev';
  static const List<String> _matchedNames = [
    'Maya',
    'Leo',
    'Ava',
    'Noah',
    'Zara',
    'Omar',
    'Mia',
    'Ethan',
    'Nina',
    'Arjun',
    'Sara',
    'Daniel',
  ];

  final PrefsService _prefs;
  final WebSocketService _ws = WebSocketService();

  // Identity
  String? playerId;
  String displayName = 'Ludo Player';
  String countryCode = 'US';
  int avatarPreset = 0;
  String? avatarImagePath;
  int coins = 500;
  int rating = 1000;
  int gamesPlayed = 0;
  int wins = 0;
  bool isDarkMode = true;
  String matchDifficulty = 'medium';

  // Match state
  GameSnapshot? lastSnapshot;
  String statusText = 'Welcome!';
  bool connecting = false;
  bool currentMatchIsBot = false;
  String pendingMatchMode = 'classic_2p';
  bool fallbackBotStarted = false;
  bool backendOnline = false;
  int _pollAttempts = 0;

  // Roll state (mirrors Java lastRollValue / lastRollPlayerId)
  int lastRollValue = 0;
  String? lastRollPlayerId;

  // Navigation
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // WS message subscription
  StreamSubscription<dynamic>? _wsSub;

  AppState(this._prefs);

  Future<void> init() async {
    playerId = _prefs.playerId;
    displayName = _prefs.displayName;
    countryCode = _prefs.countryCode;
    avatarPreset = _prefs.avatarPreset;
    avatarImagePath = _prefs.avatarImagePath;
    coins = _prefs.coins;
    rating = _prefs.rating;
    gamesPlayed = _prefs.gamesPlayed;
    wins = _prefs.wins;
    isDarkMode = _prefs.isDarkMode;
    matchDifficulty = _normalizeDifficulty(_prefs.matchDifficulty);

    // Shared WS service identity
    _ws.playerId = playerId;
    _ws.displayName = displayName;

    _healthCheck();
  }

  void _healthCheck() {
    http.get(Uri.parse('$_backendUrl/health')).then((r) {
      backendOnline = r.statusCode < 400;
    }).catchError((_) {
      backendOnline = false;
    });
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  void navigateTo(String route, {Object? arguments}) {
    navigatorKey.currentState?.pushNamed(route, arguments: arguments);
  }

  void goBack() {
    navigatorKey.currentState?.pop();
  }

  // ── Game actions ───────────────────────────────────────────────────────────

  void rollDice() {
    if (!_canAct()) return;
    if (!_isMyTurn()) {
      _setStatus('Wait for your turn.');
      return;
    }
    if (_hasDiceValue()) {
      _setStatus('Move a highlighted piece first.');
      return;
    }
    SoundService.roll();
    _setStatus('Rolling...');
    _ws.send({'type': 'roll_dice', 'playerId': playerId});
  }

  void movePiece(String pieceId) {
    if (!_canAct()) return;
    if (!_isMyTurn()) {
      _setStatus('Wait for your turn.');
      return;
    }
    if (!_hasDiceValue()) {
      _setStatus('Roll before moving a piece.');
      return;
    }
    final moves = lastSnapshot?.availableMoves ?? [];
    if (!moves.contains(pieceId)) {
      _setStatus('That piece cannot move.');
      return;
    }
    SoundService.move();
    _setStatus('Moving piece...');
    _ws.send({'type': 'move_piece', 'playerId': playerId, 'pieceId': pieceId});
  }

  void moveBestPiece() {
    if (!_canAct()) return;
    final moves = lastSnapshot?.availableMoves ?? [];
    if (moves.isEmpty) {
      _setStatus('No legal pieces to move.');
      return;
    }
    movePiece(_chooseBest(moves));
  }

  void resign() {
    SoundService.warning();
    if (playerId != null) {
      _ws.send({'type': 'resign', 'playerId': playerId});
    }
    _resetLiveMatch();
  }

  // ── Matchmaking ────────────────────────────────────────────────────────────

  void startQuickMatch(String mode) {
    if (connecting) return;
    pendingMatchMode = mode;
    fallbackBotStarted = false;
    currentMatchIsBot = false;
    _resetLiveMatch();
    connecting = true;
    navigateTo('/game');
    _setStatus('Creating guest profile...');

    final region = matchmakingRegion;
    _post('/api/v1/auth/guest', {
      'displayName': displayName,
      'region': region,
      'country': countryCode,
    }, (body) {
      final player = body['player'] as Map<String, dynamic>;
      _applyPlayer(player);
      _setStatus('Searching for match...');
      _post('/api/v1/matchmaking/quick', {
        'playerId': playerId,
        'displayName': displayName,
        'mode': mode,
        'region': region,
        'country': countryCode,
        'rating': rating,
        'difficulty': matchDifficulty,
      }, (ticket) {
        final ticketId = ticket['ticketId'] as String? ?? '';
        if (ticketId.isEmpty) {
          _fallbackToBots('No online room available.');
          return;
        }
        _pollAttempts = 0;
        _pollTicket(ticketId);
      }, onError: () => _fallbackToBots('Online matchmaking busy.'));
    }, onError: () => _fallbackToBots('Online matchmaking busy.'));
  }

  void startBotMatch(String mode) {
    if (connecting) return;
    pendingMatchMode = mode;
    fallbackBotStarted = false;
    currentMatchIsBot = true;
    _resetLiveMatch();
    connecting = true;
    navigateTo('/game');
    _setStatus('Creating guest profile...');

    final region = matchmakingRegion;
    _post('/api/v1/auth/guest', {
      'displayName': displayName,
      'region': region,
      'country': countryCode,
    }, (body) {
      final player = body['player'] as Map<String, dynamic>;
      _applyPlayer(player);
      _setStatus('Creating table...');
      _post('/api/v1/matchmaking/bots', {
        'playerId': playerId,
        'displayName': displayName,
        'mode': mode,
        'region': region,
        'country': countryCode,
        'rating': rating,
        'difficulty': matchDifficulty,
      }, (match) {
        final socketUrl = match['socketUrl'] as String? ?? '';
        if (socketUrl.isEmpty) {
          _setStatus('Match failed.');
          return;
        }
        _connectWs(socketUrl);
      });
    }, onError: () => _setStatus('Failed to create guest profile.'));
  }

  void _pollTicket(String ticketId) {
    if (_pollAttempts >= 4) {
      _fallbackToBots('No online players found.');
      return;
    }
    Future.delayed(const Duration(seconds: 2), () async {
      try {
        final r = await http.get(
          Uri.parse('$_backendUrl/api/v1/matchmaking/tickets/$ticketId'),
        );
        final j = jsonDecode(r.body) as Map<String, dynamic>;
        final status = j['status'] as String? ?? 'waiting';
        if (status == 'matched') {
          final socketUrl = j['socketUrl'] as String? ?? '';
          if (socketUrl.isNotEmpty) {
            _connectWs(socketUrl);
            return;
          }
        }
        if (status == 'waiting') {
          _pollAttempts++;
          _setStatus('Searching... ($_pollAttempts)');
          _pollTicket(ticketId);
        } else {
          _fallbackToBots('No online players found.');
        }
      } catch (_) {
        _fallbackToBots('Matchmaking check failed.');
      }
    });
  }

  void _fallbackToBots(String reason) {
    if (fallbackBotStarted) return;
    fallbackBotStarted = true;
    connecting = false;
    _setStatus('$reason Opening the next table...');
    Future.delayed(const Duration(milliseconds: 650), () {
      connecting = false;
      startBotMatch(pendingMatchMode);
    });
  }

  // ── WebSocket ──────────────────────────────────────────────────────────────

  void _connectWs(String socketPath) {
    _ws.playerId = playerId;
    _ws.displayName = displayName;
    _ws.connect(socketPath);
    _wsSub?.cancel();
    _wsSub = _ws.messages.listen(_handleMessage);

    // Send join after connect (slight delay for WS handshake)
    Future.delayed(const Duration(milliseconds: 300), () {
      _ws.send(
          {'type': 'join', 'playerId': playerId, 'displayName': displayName});
      _ws.send({'type': 'fill_bots', 'playerId': playerId});
      connecting = false;
      _setStatus('Table ready. Roll when it is your turn.');
    });
  }

  void _handleMessage(dynamic raw) {
    try {
      final envelope = jsonDecode(raw.toString()) as Map<String, dynamic>;
      final type = envelope['type'] as String? ?? '';

      if (type == 'error') {
        _setStatus(envelope['message'] as String? ?? 'Room error');
        return;
      }

      final snapRaw = envelope['snapshot'] as Map<String, dynamic>?;
      final eventStatus = _rememberRoomEvent(type, envelope, snapRaw);

      if (snapRaw != null) {
        lastSnapshot = GameSnapshot.fromJson(snapRaw);

        // Track roll event
        if (type == 'dice_rolled') {
          lastRollValue = envelope['value'] as int? ?? 0;
          lastRollPlayerId = envelope['playerId'] as String?;
        }

        notifyListeners();

        if (eventStatus != null && eventStatus.isNotEmpty) {
          _setStatus(eventStatus);
        }

        if (lastSnapshot!.status == 'finished') {
          _trackMatchResult(lastSnapshot!);
          Future.delayed(const Duration(milliseconds: 1500), () {
            navigateTo('/results');
          });
        }
      } else if (eventStatus != null && eventStatus.isNotEmpty) {
        _setStatus(eventStatus);
      }
    } catch (_) {}
  }

  String? _rememberRoomEvent(
      String type, Map<String, dynamic> e, Map<String, dynamic>? snap) {
    if (type == 'dice_rolled') {
      final val = e['value'] as int? ?? 0;
      final pid = e['playerId'] as String? ?? '';
      final mine = playerId == pid;
      final moves = snap?['availableMoves'] as List<dynamic>?;
      final hasMoves = moves != null && moves.isNotEmpty;
      if (mine) {
        return hasMoves
            ? 'You rolled $val. Tap a highlighted piece.'
            : 'You rolled $val. No legal move, turn passed.';
      }
      return '${_playerName(snap, pid)} rolled $val.';
    }

    if (type == 'turn_skipped') {
      final pid = e['playerId'] as String? ?? '';
      final mine = playerId == pid;
      final roll = (lastRollValue > 0 && pid == lastRollPlayerId)
          ? ' rolled $lastRollValue'
          : '';
      return mine
          ? 'You$roll. No legal move, turn passed.'
          : '${_playerName(snap, pid)}$roll and had no legal move.';
    }

    if (type == 'move_accepted') {
      final pid = e['playerId'] as String? ?? '';
      final mine = playerId == pid;
      final piece = e['pieceId'] as String? ?? '';
      return mine
          ? 'Moved $piece.'
          : '${_playerName(snap, pid)} moved a piece.';
    }

    if (type == 'match_finished') {
      final winner = e['winnerPlayerId'] as String? ?? '';
      return playerId == winner
          ? 'You won the match.'
          : '${_playerName(snap, winner)} won the match.';
    }

    return null;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _applyPlayer(Map<String, dynamic> player) {
    playerId = player['id'] as String? ?? playerId;
    displayName = player['displayName'] as String? ?? displayName;
    rating = player['rating'] as int? ?? rating;
    coins = player['coins'] as int? ?? coins;

    _ws.playerId = playerId;
    _ws.displayName = displayName;
    _prefs.playerId = playerId;
    _prefs.displayName = displayName;
    notifyListeners();
  }

  void _trackMatchResult(GameSnapshot snap) {
    gamesPlayed++;
    final won = playerId != null && playerId == snap.winnerPlayerId;
    if (won) {
      SoundService.success();
      wins++;
      rating += 12;
      coins += 100;
    } else {
      SoundService.warning();
      rating = (rating - 6).clamp(0, 9999);
      coins += 15;
    }
    _prefs.gamesPlayed = gamesPlayed;
    _prefs.wins = wins;
    _prefs.rating = rating;
    _prefs.coins = coins;
    _ws.disconnect();
    lastRollValue = 0;
    lastRollPlayerId = null;
    notifyListeners();
  }

  void _resetLiveMatch() {
    _ws.disconnect();
    lastSnapshot = null;
    lastRollValue = 0;
    lastRollPlayerId = null;
    notifyListeners();
  }

  bool _canAct() {
    if (playerId == null) {
      _setStatus('Match is not connected.');
      return false;
    }
    if (lastSnapshot == null) {
      _setStatus('Waiting for room state...');
      return false;
    }
    return true;
  }

  bool _isMyTurn() {
    if (lastSnapshot == null || playerId == null) return false;
    final mySeat = lastSnapshot!.seats
            .where((s) => s.playerId == playerId)
            .map((s) => s.seat)
            .firstOrNull ??
        -1;
    return mySeat >= 0 &&
        mySeat == lastSnapshot!.currentTurnSeat &&
        lastSnapshot!.status == 'playing';
  }

  bool _hasDiceValue() => (lastSnapshot?.diceValue ?? 0) > 0;

  int? get mySeat => lastSnapshot?.seats
      .where((s) => s.playerId == playerId)
      .map((s) => s.seat)
      .firstOrNull;

  String _chooseBest(List<String> moves) {
    String best = moves.first;
    int bestScore = -1;
    for (final id in moves) {
      final piece =
          lastSnapshot?.pieces.where((p) => p.pieceId == id).firstOrNull;
      final score = piece?.progress ?? -1;
      if (score > bestScore) {
        bestScore = score;
        best = id;
      }
    }
    return best;
  }

  String _playerName(Map<String, dynamic>? snap, String targetId) {
    if (targetId.isEmpty) return 'Player';
    final seats = (snap?['seats'] ??
        lastSnapshot?.seats
            .map((s) => {
                  'playerId': s.playerId,
                  'displayName': s.displayName,
                  'isBot': s.isBot,
                  'seat': s.seat,
                })
            .toList()) as List<dynamic>?;
    if (seats == null) return 'Player';
    for (final s in seats) {
      if (s is Map && s['playerId'] == targetId) {
        return publicDisplayName(
          s['displayName'] as String?,
          playerId: s['playerId'] as String?,
          seat: s['seat'] as int?,
          isFallback: s['isBot'] == true,
        );
      }
    }
    return 'Player';
  }

  void _setStatus(String text) {
    statusText = text;
    notifyListeners();
  }

  // ── HTTP helper ────────────────────────────────────────────────────────────

  void _post(
    String path,
    Map<String, dynamic> payload,
    void Function(Map<String, dynamic>) onSuccess, {
    void Function()? onError,
  }) {
    http
        .post(
      Uri.parse('$_backendUrl$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    )
        .then((r) {
      if (r.statusCode >= 400) {
        connecting = false;
        if (onError != null) {
          onError();
        } else {
          _setStatus('HTTP error ${r.statusCode}');
        }
        return;
      }
      onSuccess(jsonDecode(r.body) as Map<String, dynamic>);
    }).catchError((_) {
      connecting = false;
      if (onError != null) {
        onError();
      } else {
        _setStatus('Request failed.');
      }
    });
  }

  void toggleDarkMode() {
    SoundService.tap();
    isDarkMode = !isDarkMode;
    _prefs.isDarkMode = isDarkMode;
    notifyListeners();
  }

  String get matchDifficultyLabel {
    switch (matchDifficulty) {
      case 'easy':
        return 'Easy';
      case 'hard':
        return 'Hard';
      case 'repeat':
        return 'Repeat';
      case 'medium':
      default:
        return 'Medium';
    }
  }

  void setMatchDifficulty(String value) {
    final normalized = _normalizeDifficulty(value);
    if (normalized == matchDifficulty) return;
    SoundService.tap();
    matchDifficulty = normalized;
    _prefs.matchDifficulty = matchDifficulty;
    notifyListeners();
  }

  String publicSeatName(SeatState seat) => publicDisplayName(
        seat.displayName,
        playerId: seat.playerId,
        seat: seat.seat,
        isFallback: seat.isBot,
      );

  String publicDisplayName(
    String? raw, {
    String? playerId,
    int? seat,
    bool isFallback = false,
  }) {
    final name = (raw ?? '').trim();
    final lower = name.toLowerCase();
    final fallback = isFallback ||
        (playerId?.startsWith('bot_') ?? false) ||
        lower.contains('bot') ||
        lower.contains('cpu') ||
        lower == 'ai' ||
        name.isEmpty ||
        name == 'Player';
    if (!fallback) return name;

    final index = seat != null && seat >= 0
        ? seat
        : ((playerId ?? name).hashCode & 0x7fffffff);
    return _matchedNames[index % _matchedNames.length];
  }

  String _normalizeDifficulty(String value) {
    switch (value.trim().toLowerCase()) {
      case 'easy':
      case 'hard':
      case 'repeat':
        return value.trim().toLowerCase();
      case 'medium':
      default:
        return 'medium';
    }
  }

  String get matchmakingRegion {
    switch (countryCode.toUpperCase()) {
      case 'IN':
      case 'PK':
      case 'BD':
      case 'LK':
        return 'ap-south';
      case 'GB':
      case 'DE':
      case 'FR':
      case 'ES':
        return 'eu-west';
      case 'AE':
      case 'SA':
        return 'me-central';
      case 'AU':
        return 'ap-southeast';
      case 'BR':
        return 'sa-east';
      case 'CA':
      case 'US':
      default:
        return 'us-east';
    }
  }

  void updateProfile({
    String? name,
    String? country,
    int? avatar,
    String? imagePath,
    bool clearImage = false,
  }) {
    final cleanName = name?.trim();
    if (cleanName != null && cleanName.isNotEmpty) {
      displayName =
          cleanName.length > 18 ? cleanName.substring(0, 18) : cleanName;
      _prefs.displayName = displayName;
      _ws.displayName = displayName;
    }
    if (country != null && country.trim().isNotEmpty) {
      countryCode = country.trim().toUpperCase();
      _prefs.countryCode = countryCode;
    }
    if (avatar != null) {
      avatarPreset = avatar.clamp(0, 7);
      _prefs.avatarPreset = avatarPreset;
      if (clearImage) {
        avatarImagePath = null;
        _prefs.avatarImagePath = null;
      }
    }
    if (imagePath != null && imagePath.trim().isNotEmpty) {
      avatarImagePath = imagePath;
      _prefs.avatarImagePath = imagePath;
    } else if (clearImage) {
      avatarImagePath = null;
      _prefs.avatarImagePath = null;
    }
    notifyListeners();
  }

  void addCoins(int amount) {
    coins = (coins + amount).clamp(0, 99999999);
    _prefs.coins = coins;
    notifyListeners();
  }
}
