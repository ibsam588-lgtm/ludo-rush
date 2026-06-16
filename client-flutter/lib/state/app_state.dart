import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/game_snapshot.dart';
import '../services/prefs_service.dart';
import '../services/sound_service.dart';
import '../services/websocket_service.dart';

class AppState extends ChangeNotifier {
  static const String _backendUrl =
      'https://ludo-rush-backend.ibsam588.workers.dev';
  static const int _yardProgress = -1;
  static const int _finishProgress = 57;
  static const int _trackLength = 52;
  static const List<int> _localStartOffsets = [1, 14, 27, 40];
  static const Set<int> _localSafeTrackIndexes = {
    1,
    8,
    14,
    21,
    27,
    34,
    40,
    47,
  };
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
  bool localMatchActive = false;
  String pendingMatchMode = 'classic_2p';
  bool fallbackBotStarted = false;
  bool backendOnline = false;
  int _pollAttempts = 0;
  final math.Random _rng = math.Random();
  Timer? _localBotTimer;

  // Roll state (mirrors Java lastRollValue / lastRollPlayerId)
  int lastRollValue = 0;
  String? lastRollPlayerId;
  int lastRollSequence = 0;

  // Navigation
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

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

  @override
  void dispose() {
    _localBotTimer?.cancel();
    _wsSub?.cancel();
    _ws.disconnect();
    super.dispose();
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
    clearTransientUi();
    navigatorKey.currentState?.pushNamed(route, arguments: arguments);
  }

  void goBack() {
    clearTransientUi();
    navigatorKey.currentState?.pop();
  }

  void clearTransientUi() {
    scaffoldMessengerKey.currentState?.clearSnackBars();
  }

  // ── Game actions ───────────────────────────────────────────────────────────

  void rollDice() {
    if (localMatchActive) {
      _rollLocalDice();
      return;
    }
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
    if (localMatchActive) {
      _moveLocalPiece(pieceId);
      return;
    }
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
    if (localMatchActive) {
      final moves = lastSnapshot?.availableMoves ?? [];
      if (moves.isEmpty) {
        _setStatus('No legal pieces to move.');
        return;
      }
      _moveLocalPiece(_chooseBest(moves));
      return;
    }
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
    if (localMatchActive) {
      _resetLiveMatch();
      _setStatus('Match resigned.');
      return;
    }
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
    currentMatchIsBot = true;
    _resetLiveMatch();
    connecting = true;
    navigateTo('/game');
    _setStatus('Opening table...');
    _startLocalBotMatch(
      mode,
      reason: 'Bot table ready. Roll when it is your turn.',
    );
  }

  void startBotMatch(String mode) {
    if (connecting) return;
    pendingMatchMode = mode;
    fallbackBotStarted = false;
    currentMatchIsBot = true;
    _resetLiveMatch();
    connecting = true;
    navigateTo('/game');
    _setStatus('Opening bot table...');
    _startLocalBotMatch(
      mode,
      reason: 'Bot table ready. Roll when it is your turn.',
    );
  }

  // ignore: unused_element
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
    localMatchActive = false;
    _localBotTimer?.cancel();
    _localBotTimer = null;
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
          lastRollSequence++;
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

  // Local bot table used when the online backend is unavailable.

  void _startLocalBotMatch(String mode, {required String reason}) {
    _ws.disconnect();
    _localBotTimer?.cancel();
    _localBotTimer = null;

    if (playerId == null || playerId!.isEmpty) {
      playerId = 'local_${DateTime.now().millisecondsSinceEpoch}';
      _prefs.playerId = playerId;
    }

    final maxPlayers = mode.contains('4p') ? 4 : 2;
    final seats = List<SeatState>.generate(maxPlayers, (seat) {
      if (seat == 0) {
        return SeatState(
          seat: seat,
          playerId: playerId!,
          displayName: _humanDisplayName,
          isBot: false,
        );
      }
      return SeatState(
        seat: seat,
        playerId: 'local_bot_$seat',
        displayName: _matchedNames[seat % _matchedNames.length],
        isBot: true,
      );
    });

    final pieces = <PieceState>[
      for (final seat in seats)
        for (int i = 0; i < 4; i++)
          PieceState(
            pieceId: 's${seat.seat}_p$i',
            seat: seat.seat,
            state: 'yard',
            progress: _yardProgress,
            trackIndex: -1,
          ),
    ];

    _ws.playerId = playerId;
    _ws.displayName = displayName;
    currentMatchIsBot = true;
    localMatchActive = true;
    fallbackBotStarted = true;
    connecting = false;
    lastRollValue = 0;
    lastRollPlayerId = null;
    lastRollSequence = 0;
    lastSnapshot = GameSnapshot(
      seats: seats,
      pieces: pieces,
      diceValue: 0,
      currentTurnSeat: 0,
      status: 'playing',
      availableMoves: const [],
      winnerPlayerId: '',
      mode: mode,
    );
    _setStatus(reason);
    _scheduleLocalBots();
  }

  void _rollLocalDice() {
    if (!_canAct()) return;
    if (!_isMyTurn()) {
      _setStatus('Wait for your turn.');
      return;
    }
    if (_hasDiceValue()) {
      _setStatus('Move a highlighted piece first.');
      return;
    }

    final snap = lastSnapshot!;
    final seat = mySeat ?? snap.currentTurnSeat;
    final value = _nextLocalDice(snap, seat);
    final moves = _localLegalMoves(snap, seat, value);

    SoundService.roll();
    lastRollValue = value;
    lastRollPlayerId = playerId;
    lastRollSequence++;

    if (moves.isEmpty) {
      lastSnapshot = _advanceLocalTurn(snap);
      _setStatus('You rolled $value. No legal move, turn passed.');
      _scheduleLocalBots();
      return;
    }

    lastSnapshot = _copySnapshot(
      snap,
      diceValue: value,
      availableMoves: moves,
    );
    _setStatus('You rolled $value. Tap a highlighted piece.');
  }

  void _moveLocalPiece(String pieceId) {
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

    final before = lastSnapshot!;
    SoundService.move();
    final after = _applyLocalMove(before, pieceId);
    lastSnapshot = after;

    if (after.status == 'finished') {
      _setStatus('You won the match.');
      _trackMatchResult(after);
      Future.delayed(const Duration(milliseconds: 1200), () {
        navigateTo('/results');
      });
      return;
    }

    final sameTurn = after.currentTurnSeat == (mySeat ?? -1);
    _setStatus(
      sameTurn
          ? 'You moved a piece. Bonus roll.'
          : 'You moved a piece. ${_currentTurnLabel(after)} is next.',
    );
    _scheduleLocalBots();
  }

  void _scheduleLocalBots(
      {Duration delay = const Duration(milliseconds: 650)}) {
    _localBotTimer?.cancel();
    _localBotTimer = null;
    if (!localMatchActive) return;
    final snap = lastSnapshot;
    if (snap == null || snap.status != 'playing') return;
    final seat = _currentLocalSeat(snap);
    if (seat == null || !seat.isBot) return;

    _localBotTimer = Timer(delay, _playLocalBotTurn);
  }

  void _playLocalBotTurn() {
    if (!localMatchActive) return;
    final snap = lastSnapshot;
    if (snap == null || snap.status != 'playing') return;
    final seat = _currentLocalSeat(snap);
    if (seat == null || !seat.isBot) return;

    final value = _nextLocalDice(snap, seat.seat);
    final moves = _localLegalMoves(snap, seat.seat, value);
    final name = publicSeatName(seat);

    SoundService.roll();
    lastRollValue = value;
    lastRollPlayerId = seat.playerId;
    lastRollSequence++;

    if (moves.isEmpty) {
      lastSnapshot = _advanceLocalTurn(snap);
      _setStatus('$name rolled $value and had no legal move.');
      _scheduleLocalBots();
      return;
    }

    lastSnapshot = _copySnapshot(
      snap,
      diceValue: value,
      availableMoves: moves,
    );
    _setStatus('$name rolled $value.');

    _localBotTimer = Timer(const Duration(milliseconds: 620), () {
      if (!localMatchActive) return;
      final current = lastSnapshot;
      if (current == null ||
          current.status != 'playing' ||
          current.currentTurnSeat != seat.seat ||
          current.diceValue != value) {
        return;
      }

      final move = _chooseLocalBotMove(current, moves);
      SoundService.move();
      final after = _applyLocalMove(current, move);
      lastSnapshot = after;

      if (after.status == 'finished') {
        _setStatus('$name won the match.');
        _trackMatchResult(after);
        Future.delayed(const Duration(milliseconds: 1200), () {
          navigateTo('/results');
        });
        return;
      }

      final sameTurn = after.currentTurnSeat == seat.seat;
      _setStatus(
        sameTurn
            ? '$name moved a piece. Bonus roll.'
            : '$name moved a piece. ${_currentTurnLabel(after)} is next.',
      );
      _scheduleLocalBots();
    });
  }

  GameSnapshot _applyLocalMove(GameSnapshot snap, String pieceId) {
    final dice = snap.diceValue;
    final movingPiece = snap.pieces.firstWhere((p) => p.pieceId == pieceId);
    final moverSeat = movingPiece.seat;
    final nextProgress =
        movingPiece.progress == _yardProgress ? 0 : movingPiece.progress + dice;
    final nextTrack = _trackIndexFor(moverSeat, nextProgress);
    final nextState = _stateForProgress(nextProgress);

    var pieces = snap.pieces.map((piece) {
      if (piece.pieceId != pieceId) return piece;
      return PieceState(
        pieceId: piece.pieceId,
        seat: piece.seat,
        state: nextState,
        progress: nextProgress,
        trackIndex: nextTrack ?? -1,
      );
    }).toList();

    if (nextTrack != null && !_localSafeTrackIndexes.contains(nextTrack)) {
      pieces = pieces.map((piece) {
        if (piece.seat == moverSeat ||
            piece.trackIndex != nextTrack ||
            piece.state != 'track') {
          return piece;
        }
        return PieceState(
          pieceId: piece.pieceId,
          seat: piece.seat,
          state: 'yard',
          progress: _yardProgress,
          trackIndex: -1,
        );
      }).toList();
    }

    final winner = _seatFinished(pieces, moverSeat)
        ? snap.seats.firstWhere((seat) => seat.seat == moverSeat).playerId
        : '';
    if (winner.isNotEmpty) {
      return _copySnapshot(
        snap,
        pieces: pieces,
        diceValue: 0,
        availableMoves: const [],
        winnerPlayerId: winner,
        status: 'finished',
      );
    }

    final moved = _copySnapshot(
      snap,
      pieces: pieces,
      diceValue: 0,
      availableMoves: const [],
    );
    return dice == 6 ? moved : _advanceLocalTurn(moved);
  }

  List<String> _localLegalMoves(GameSnapshot snap, int seat, int diceValue) {
    return snap.pieces
        .where((piece) => piece.seat == seat)
        .where((piece) => _canLocalPieceMove(piece, diceValue))
        .map((piece) => piece.pieceId)
        .toList();
  }

  bool _canLocalPieceMove(PieceState piece, int diceValue) {
    if (piece.state == 'finished') return false;
    if (piece.progress == _yardProgress) return diceValue == 6;
    return piece.progress + diceValue <= _finishProgress;
  }

  GameSnapshot _advanceLocalTurn(GameSnapshot snap) {
    final activeSeats = snap.seats
        .where((seat) => !_seatFinished(snap.pieces, seat.seat))
        .map((seat) => seat.seat)
        .toList()
      ..sort();
    if (activeSeats.isEmpty) return snap;

    final index = activeSeats.indexOf(snap.currentTurnSeat);
    final nextIndex = index < 0 ? 0 : (index + 1) % activeSeats.length;
    return _copySnapshot(
      snap,
      currentTurnSeat: activeSeats[nextIndex],
      diceValue: 0,
      availableMoves: const [],
    );
  }

  String _chooseLocalBotMove(GameSnapshot snap, List<String> moves) {
    final sorted = [...moves]
      ..sort((a, b) => _scoreLocalMove(snap, b) - _scoreLocalMove(snap, a));
    return sorted.first;
  }

  int _scoreLocalMove(GameSnapshot snap, String pieceId) {
    final piece = snap.pieces.where((p) => p.pieceId == pieceId).firstOrNull;
    if (piece == null) return 0;
    if (piece.progress == _yardProgress) return 30;

    final nextProgress = piece.progress + snap.diceValue;
    final nextTrack = _trackIndexFor(piece.seat, nextProgress);
    final captures = nextTrack != null &&
        !_localSafeTrackIndexes.contains(nextTrack) &&
        snap.pieces.any((other) =>
            other.seat != piece.seat &&
            other.trackIndex == nextTrack &&
            other.state == 'track');
    return nextProgress + (captures ? 100 : 0);
  }

  int _nextLocalDice(GameSnapshot snap, int seat) {
    final seatPieces = snap.pieces.where((piece) => piece.seat == seat);
    final allInYard =
        seatPieces.every((piece) => piece.progress == _yardProgress);
    if (allInYard) {
      return 6;
    }
    return _rng.nextInt(6) + 1;
  }

  String _currentTurnLabel(GameSnapshot snap) {
    final seat = _currentLocalSeat(snap);
    if (seat == null) return 'Next player';
    if (seat.playerId == playerId) return 'Your turn';
    return publicSeatName(seat);
  }

  int? _trackIndexFor(int seat, int progress) {
    if (progress < 0 || progress > 51) return null;
    return (_localStartOffsets[seat.clamp(0, 3)] + progress) % _trackLength;
  }

  String _stateForProgress(int progress) {
    if (progress == _yardProgress) return 'yard';
    if (progress >= _finishProgress) return 'finished';
    if (progress > 51) return 'home';
    return 'track';
  }

  bool _seatFinished(List<PieceState> pieces, int seat) {
    final seatPieces = pieces.where((piece) => piece.seat == seat).toList();
    return seatPieces.isNotEmpty &&
        seatPieces.every((piece) => piece.state == 'finished');
  }

  SeatState? _currentLocalSeat(GameSnapshot snap) {
    return snap.seats
        .where((seat) => seat.seat == snap.currentTurnSeat)
        .firstOrNull;
  }

  GameSnapshot _copySnapshot(
    GameSnapshot snap, {
    List<SeatState>? seats,
    List<PieceState>? pieces,
    int? diceValue,
    int? currentTurnSeat,
    String? status,
    List<String>? availableMoves,
    String? winnerPlayerId,
    String? mode,
  }) {
    return GameSnapshot(
      seats: seats ?? snap.seats,
      pieces: pieces ?? snap.pieces,
      diceValue: diceValue ?? snap.diceValue,
      currentTurnSeat: currentTurnSeat ?? snap.currentTurnSeat,
      status: status ?? snap.status,
      availableMoves: availableMoves ?? snap.availableMoves,
      winnerPlayerId: winnerPlayerId ?? snap.winnerPlayerId,
      mode: mode ?? snap.mode,
    );
  }

  String get _humanDisplayName {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty || trimmed == 'Ludo Player') return 'Ibsam';
    return trimmed;
  }

  // ignore: unused_element
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
    _localBotTimer?.cancel();
    _localBotTimer = null;
    localMatchActive = false;
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
    _localBotTimer?.cancel();
    _localBotTimer = null;
    localMatchActive = false;
    _ws.disconnect();
    lastSnapshot = null;
    lastRollValue = 0;
    lastRollPlayerId = null;
    lastRollSequence = 0;
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

  // ignore: unused_element
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
