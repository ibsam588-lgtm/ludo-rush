import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../data/profile_catalog.dart';
import '../data/economy.dart';
import '../models/game_snapshot.dart';
import '../services/app_platform_service.dart';
import '../services/prefs_service.dart';
import '../services/sound_service.dart';
import '../services/soundtrack_service.dart';
import '../services/websocket_service.dart';

class SocialPlayer {
  final String id;
  final String displayName;
  final int rating;

  const SocialPlayer({
    required this.id,
    required this.displayName,
    required this.rating,
  });

  factory SocialPlayer.fromJson(Map<String, dynamic> json) => SocialPlayer(
        id: json['id'] as String? ?? '',
        displayName: json['displayName'] as String? ?? 'Player',
        rating: (json['rating'] as num?)?.toInt() ?? 1000,
      );
}

class ClubSummary {
  final String id;
  final String name;
  final String tag;
  final String description;
  final int minimumRating;
  final int memberCount;
  final int ratingTotal;
  final int contribution;

  const ClubSummary({
    required this.id,
    required this.name,
    required this.tag,
    required this.description,
    required this.minimumRating,
    required this.memberCount,
    required this.ratingTotal,
    this.contribution = 0,
  });

  factory ClubSummary.fromJson(Map<String, dynamic> json) => ClubSummary(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? 'Club',
        tag: json['tag'] as String? ?? '',
        description: json['description'] as String? ?? '',
        minimumRating: (json['minimumRating'] as num?)?.toInt() ?? 0,
        memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
        ratingTotal: (json['ratingTotal'] as num?)?.toInt() ?? 0,
        contribution: (json['contribution'] as num?)?.toInt() ?? 0,
      );
}

class FriendChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String message;
  final int createdAt;

  const FriendChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.createdAt,
  });

  factory FriendChatMessage.fromJson(Map<String, dynamic> json) =>
      FriendChatMessage(
        id: json['id'] as String? ?? '',
        senderId: json['senderId'] as String? ?? '',
        senderName: json['senderName'] as String? ?? 'Player',
        message: json['message'] as String? ?? '',
        createdAt: (json['createdAt'] as num?)?.toInt() ?? 0,
      );
}

class ReceivedFriendGift {
  final String id;
  final String giftId;
  final String senderName;
  final int createdAt;

  const ReceivedFriendGift({
    required this.id,
    required this.giftId,
    required this.senderName,
    required this.createdAt,
  });

  factory ReceivedFriendGift.fromJson(Map<String, dynamic> json) =>
      ReceivedFriendGift(
        id: json['id'] as String? ?? '',
        giftId: json['giftId'] as String? ?? 'gift',
        senderName: json['senderName'] as String? ?? 'Friend',
        createdAt: (json['createdAt'] as num?)?.toInt() ?? 0,
      );
}

class AppState extends ChangeNotifier with WidgetsBindingObserver {
  static const String _backendUrl =
      'https://ludo-rush-backend.ibsam588.workers.dev';
  static const String _defaultAndroidUpdateUrl =
      'https://play.google.com/store/apps/details?id=com.ludorush.game';
  static const String snakesLaddersMode = 'snakes_ladders';
  static const int _yardProgress = -1;
  static const int _classicFinishProgress = 57;
  static const int _snakeFinishProgress = 100;
  static const int _classicTrackLength = 52;
  // Must match the backend rules (rules.ts): START_OFFSETS and
  // SAFE_TRACK_INDEXES, so online and offline games agree on where pieces
  // stand and which cells are capture-safe.
  static const List<int> _localStartOffsets = [1, 14, 27, 40];
  static const Set<int> _localSafeTrackIndexes = {1, 9, 14, 22, 27, 35, 40, 48};
  static const Map<int, int> _snakeLadders = {
    6: 26,
    23: 37,
    48: 68,
    65: 85,
    79: 99,
  };
  static const Map<int, int> _snakeDrops = {
    47: 13,
    57: 35,
    84: 64,
    93: 68,
  };
  static const Map<String, int> _diceUnlockWins = {
    'classic': 0,
    'royal': 3,
    'neon': 5,
    'emerald': 8,
  };
  static const Map<String, int> _boardUnlockWins = {
    'carnival': 0,
    'classic': 2,
    'royal': 6,
    'jungle': 10,
  };
  static const Map<String, String> _premiumDicePrices = {
    'ruby': '0.99 USD',
    'cosmic': '1.99 USD',
  };
  static const Map<String, String> _premiumBoardPrices = {
    'neon': '1.99 USD',
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
  final SoundtrackService _soundtrack = SoundtrackService();

  // Identity
  String? playerId;
  String? authToken;
  String displayName = 'Ludo Player';
  String countryCode = 'US';
  int avatarPreset = 0;
  int age = 0;
  String? avatarImagePath;
  int coins = GameEconomy.startingCoins;
  int rating = 1000;
  int gamesPlayed = 0;
  int wins = 0;
  int claimedGoldChests = 0;
  bool isDarkMode = true;
  String matchDifficulty = 'medium';
  String ludoBoardTheme = 'carnival';
  String snakesBoardTheme = 'carnival';
  String diceSkin = 'classic';
  bool autoRollEnabled = false;
  String soundtrackId = SoundtrackCatalog.defaultId;
  bool musicEnabled = true;
  String lastDailyRewardDate = '';
  bool startChoiceSeen = false;
  bool socialLoading = false;
  String socialError = '';
  List<SocialPlayer> friends = const [];
  List<SocialPlayer> recentOpponents = const [];
  List<SocialPlayer> incomingFriendRequests = const [];
  List<SocialPlayer> outgoingFriendRequests = const [];
  List<FriendChatMessage> friendMessages = const [];
  List<ReceivedFriendGift> receivedFriendGifts = const [];
  List<ClubSummary> clubs = const [];
  ClubSummary? currentClub;
  Set<String> ownedProductIds = const {};
  bool economySynced = false;
  int _availableGoldChests = 0;

  // Match state
  GameSnapshot? lastSnapshot;
  String statusText = 'Welcome!';
  bool connecting = false;
  bool currentMatchIsBot = false;
  bool localMatchActive = false;
  String pendingMatchMode = 'classic_2p';
  String? privateInviteCode;
  bool fallbackBotStarted = false;
  bool backendOnline = false;
  bool updateCheckInProgress = false;
  bool updateCheckComplete = false;
  bool updateCheckFailed = false;
  bool forceUpdateRequired = false;
  String installedVersionName = '';
  int installedBuildNumber = 0;
  int minimumRequiredBuildNumber = 0;
  int latestAvailableBuildNumber = 0;
  String latestAvailableVersionName = '';
  String? lastReactionText;
  bool lastReactionIsEmoji = false;
  String? lastReactionPlayerId;
  int reactionSequence = 0;
  String forceUpdateMessage =
      'A newer version of Ludo Rush is required to keep matchmaking, rewards, and game rules in sync.';
  String forceUpdateUrl = _defaultAndroidUpdateUrl;
  int _pollAttempts = 0;
  final math.Random _rng = math.Random();
  Timer? _localBotTimer;
  Timer? _matchmakingTimer;
  Timer? _autoRollTimer;
  Future<void>? _authenticationFuture;
  bool _lifecycleObserverRegistered = false;

  // Roll state (mirrors Java lastRollValue / lastRollPlayerId)
  int lastRollValue = 0;
  String? lastRollPlayerId;
  int lastRollSequence = 0;
  bool _matchResultTracked = false;

  // Navigation
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  // WS message subscription
  StreamSubscription<dynamic>? _wsSub;

  AppState(this._prefs);

  Future<void> init() async {
    if (!_lifecycleObserverRegistered) {
      WidgetsBinding.instance.addObserver(this);
      _lifecycleObserverRegistered = true;
    }
    playerId = _prefs.playerId;
    authToken = _prefs.authToken;
    displayName = _prefs.displayName;
    countryCode = _prefs.countryCode;
    avatarPreset =
        _prefs.avatarPreset.clamp(0, profileAvatarCatalog.length - 1);
    age = _prefs.age;
    avatarImagePath = _prefs.avatarImagePath;
    coins = _prefs.coins;
    rating = _prefs.rating;
    gamesPlayed = _prefs.gamesPlayed;
    wins = _prefs.wins;
    claimedGoldChests = _prefs.claimedGoldChests;
    isDarkMode = _prefs.isDarkMode;
    matchDifficulty = _normalizeDifficulty(_prefs.matchDifficulty);
    ludoBoardTheme = _normalizeLudoBoardTheme(_prefs.ludoBoardTheme);
    snakesBoardTheme = _normalizeSnakesBoardTheme(_prefs.snakesBoardTheme);
    diceSkin = _normalizeDiceSkin(_prefs.diceSkin);
    autoRollEnabled = _prefs.autoRollEnabled;
    final storedSoundtrackId = _prefs.soundtrackId;
    soundtrackId = SoundtrackCatalog.normalize(storedSoundtrackId);
    if (soundtrackId != storedSoundtrackId) {
      _prefs.soundtrackId = soundtrackId;
    }
    musicEnabled = _prefs.musicEnabled;
    if (!isBoardThemePremium(ludoBoardTheme) &&
        !isBoardThemeUnlocked(ludoBoardTheme)) {
      ludoBoardTheme = 'carnival';
      _prefs.ludoBoardTheme = ludoBoardTheme;
    }
    if (!isBoardThemePremium(snakesBoardTheme) &&
        !isBoardThemeUnlocked(snakesBoardTheme)) {
      snakesBoardTheme = 'carnival';
      _prefs.snakesBoardTheme = snakesBoardTheme;
    }
    if (!isDiceSkinPremium(diceSkin) && !isDiceSkinUnlocked(diceSkin)) {
      diceSkin = 'classic';
      _prefs.diceSkin = diceSkin;
    }
    lastDailyRewardDate = _prefs.lastDailyRewardDate;
    startChoiceSeen = _prefs.startChoiceSeen;
    unawaited(_soundtrack.configure(
      track: soundtrackId,
      enabled: musicEnabled,
    ));

    // Shared WS service identity
    _ws.playerId = playerId;
    _ws.displayName = displayName;
    _ws.authToken = authToken;

    await checkForForcedUpdate(notify: false);
    if (updateCheckComplete && !forceUpdateRequired) {
      _ensurePlayerIdentity();
      unawaited(_initializeOnlineIdentity());
    }
    _healthCheck();
  }

  Future<void> _initializeOnlineIdentity() async {
    await _ensureAuthenticatedIdentity();
    if (authToken == null || authToken!.isEmpty) return;
    await syncSocialProfile(notify: false);
    await refreshSocial();
  }

  @override
  void dispose() {
    if (_lifecycleObserverRegistered) {
      WidgetsBinding.instance.removeObserver(this);
      _lifecycleObserverRegistered = false;
    }
    _matchmakingTimer?.cancel();
    _localBotTimer?.cancel();
    _autoRollTimer?.cancel();
    _wsSub?.cancel();
    _ws.disconnect();
    unawaited(_soundtrack.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_soundtrack.resumeAfterLifecycle());
      return;
    }
    unawaited(_soundtrack.pauseForLifecycle());
  }

  void _healthCheck() {
    http.get(Uri.parse('$_backendUrl/health')).then((r) {
      backendOnline = r.statusCode < 400;
    }).catchError((_) {
      backendOnline = false;
    });
  }

  Future<void> checkForForcedUpdate({bool notify = true}) async {
    updateCheckInProgress = true;
    updateCheckFailed = false;
    if (notify) notifyListeners();

    try {
      if (kIsWeb) {
        installedVersionName = 'web-preview';
        installedBuildNumber = 1;
        minimumRequiredBuildNumber = 1;
        latestAvailableBuildNumber = 1;
        latestAvailableVersionName = 'web-preview';
        forceUpdateRequired = false;
        updateCheckComplete = true;
        updateCheckFailed = false;
        return;
      }

      final packageInfo = await AppPlatformService.getVersionInfo();
      final buildNumber = packageInfo.buildNumber;
      installedVersionName = packageInfo.versionName;
      installedBuildNumber = buildNumber;

      final uri = Uri.parse('$_backendUrl/api/v1/app/config').replace(
        queryParameters: {
          'platform': 'android',
          'build': buildNumber.toString(),
          'version': packageInfo.versionName,
        },
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode >= 400) {
        updateCheckFailed = !updateCheckComplete;
        return;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final minimum = _readInt(body['minimumBuildNumber'], fallback: 0);
      final latest = _readInt(body['latestBuildNumber'], fallback: minimum);
      final updateUrl = (body['updateUrl'] as String? ?? '').trim();
      final message = (body['message'] as String? ?? '').trim();
      final latestVersion = (body['latestVersionName'] as String? ?? '').trim();
      final forceEnabled = body['forceUpdate'] == true;

      minimumRequiredBuildNumber = minimum;
      latestAvailableBuildNumber = latest;
      latestAvailableVersionName = latestVersion;
      forceUpdateUrl = updateUrl.isEmpty ? _defaultAndroidUpdateUrl : updateUrl;
      if (message.isNotEmpty) forceUpdateMessage = message;
      forceUpdateRequired = forceEnabled && buildNumber > 0;
      updateCheckComplete = true;
      updateCheckFailed = false;
    } catch (_) {
      updateCheckFailed = !updateCheckComplete;
    } finally {
      updateCheckInProgress = false;
      if (notify) notifyListeners();
    }
  }

  Future<void> openForcedUpdateStore() async {
    SoundService.tap();
    final launched = forceUpdateUrl.isNotEmpty
        ? await AppPlatformService.openUrl(forceUpdateUrl)
        : false;
    if (!launched) {
      await AppPlatformService.openUrl(_defaultAndroidUpdateUrl);
    }
  }

  Future<void> _ensureAuthenticatedIdentity() {
    if (authToken != null && authToken!.isNotEmpty) {
      _ws.authToken = authToken;
      return Future<void>.value();
    }
    final active = _authenticationFuture;
    if (active != null) return active;
    final request = _authenticateIdentity();
    _authenticationFuture = request;
    return request.whenComplete(() {
      if (identical(_authenticationFuture, request)) {
        _authenticationFuture = null;
      }
    });
  }

  Future<void> _authenticateIdentity() async {
    try {
      final response = await http
          .post(
            Uri.parse('$_backendUrl/api/v1/auth/guest'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'displayName': _humanDisplayName,
              'region': matchmakingRegion,
              'countryCode': countryCode,
              'avatarKey': 'preset_$avatarPreset',
              'age': age,
            }),
          )
          .timeout(const Duration(seconds: 7));
      if (response.statusCode >= 400) return;
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final token = (json['token'] as String? ?? '').trim();
      final player = json['player'] as Map<String, dynamic>?;
      if (token.isEmpty || player == null) return;
      authToken = token;
      _prefs.authToken = token;
      _ws.authToken = token;
      _applyPlayer(player);
    } catch (_) {
      // Offline play remains available; online actions explain the failure.
    }
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  void navigateTo(String route, {Object? arguments}) {
    clearTransientUi();
    navigatorKey.currentState?.pushNamed(route, arguments: arguments);
  }

  void replaceWith(String route, {Object? arguments}) {
    clearTransientUi();
    navigatorKey.currentState
        ?.pushReplacementNamed(route, arguments: arguments);
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

  void sendReaction(String text, {bool isEmoji = true}) {
    final clean = text.trim();
    if (clean.isEmpty) return;
    if (!localMatchActive && _ws.isConnected) {
      _ws.send({
        'type': 'reaction',
        'playerId': playerId,
        'displayName': _humanDisplayName,
        'text': clean,
        'isEmoji': isEmoji,
      });
    }
  }

  void resign() {
    SoundService.warning();
    final wasPlaying = lastSnapshot?.status == 'playing';
    if (localMatchActive) {
      if (wasPlaying) _trackResignedMatch();
      _resetLiveMatch();
      _setStatus('Match resigned.');
      return;
    }
    if (playerId != null) {
      _ws.send({'type': 'resign', 'playerId': playerId});
    }
    if (wasPlaying) _trackResignedMatch();
    _resetLiveMatch();
  }

  void _trackResignedMatch() {
    if (_matchResultTracked) return;
    _matchResultTracked = true;
    final economyEligible = !localMatchActive && !currentMatchIsBot;
    gamesPlayed++;
    if (economyEligible) {
      rating = (rating - 6).clamp(0, 9999);
    }
    _prefs.gamesPlayed = gamesPlayed;
    _prefs.rating = rating;
    if (economyEligible) {
      unawaited(Future<void>.delayed(
        const Duration(milliseconds: 900),
        refreshSocial,
      ));
    }
  }

  // ── Matchmaking ────────────────────────────────────────────────────────────

  void startQuickMatch(String mode) {
    if (connecting) return;
    markStartChoiceSeen();
    _ensurePlayerIdentity();
    pendingMatchMode = mode;
    fallbackBotStarted = false;
    currentMatchIsBot = false;
    _resetLiveMatch();
    connecting = true;
    _setStatus('Searching for match...');
    _openMatchmakingScreen();

    if (_isSnakesLaddersMode(mode)) {
      currentMatchIsBot = true;
      _scheduleLocalBotMatch(
        mode,
        reason: 'Snakes & Ladders table ready. Roll to climb.',
      );
      return;
    }

    if (authToken == null || authToken!.isEmpty) {
      _ensureAuthenticatedIdentity().then((_) {
        if (!connecting || pendingMatchMode != mode) return;
        if (authToken == null || authToken!.isEmpty) {
          _fallbackToBots('Online sign-in is unavailable.');
          return;
        }
        _requestOnlineMatch(mode);
      });
      return;
    }

    _requestOnlineMatch(mode);
  }

  void _requestOnlineMatch(String mode) {
    _pollAttempts = 0;
    _post(
      '/api/v1/matchmaking/quick',
      {
        'playerId': playerId,
        'displayName': _humanDisplayName,
        'mode': mode,
        'region': matchmakingRegion,
      },
      (j) {
        final status = j['status'] as String? ?? '';
        if (status == 'matched') {
          final socketUrl = j['socketUrl'] as String? ?? '';
          if (socketUrl.isEmpty) {
            _fallbackToBots('Match server returned no game socket.');
            return;
          }
          _connectWs(socketUrl);
          replaceWith('/game');
          return;
        }

        final ticketId = j['ticketId'] as String? ?? '';
        if (status == 'waiting' && ticketId.isNotEmpty) {
          _setStatus('Searching for online players...');
          _pollTicket(ticketId);
          return;
        }
        _fallbackToBots('No online table was available.');
      },
      onError: () => _fallbackToBots('Online matchmaking is unavailable.'),
    );
  }

  void startGuestMatch([String mode = 'classic_2p']) {
    markStartChoiceSeen();
    startQuickMatch(mode);
  }

  void markStartChoiceSeen() {
    if (startChoiceSeen) return;
    startChoiceSeen = true;
    _prefs.startChoiceSeen = true;
    notifyListeners();
  }

  bool get shouldShowStartChoice {
    final defaultName =
        displayName.trim().isEmpty || displayName.trim() == 'Ludo Player';
    return !startChoiceSeen &&
        playerId == null &&
        gamesPlayed == 0 &&
        defaultName;
  }

  void startBotMatch(String mode) {
    if (connecting) return;
    pendingMatchMode = mode;
    fallbackBotStarted = false;
    currentMatchIsBot = true;
    _resetLiveMatch();
    connecting = true;
    _setStatus('Searching for bot table...');
    _openMatchmakingScreen();
    _scheduleLocalBotMatch(
      mode,
      reason: _isSnakesLaddersMode(mode)
          ? 'Snakes & Ladders table ready. Roll to climb.'
          : 'Bot table ready. Roll when it is your turn.',
    );
  }

  void startOfflineMatch(String mode) {
    if (connecting) return;
    markStartChoiceSeen();
    pendingMatchMode = mode;
    fallbackBotStarted = true;
    currentMatchIsBot = true;
    _resetLiveMatch();
    _startLocalBotMatch(
      mode,
      reason: _isSnakesLaddersMode(mode)
          ? 'Offline Snakes & Ladders ready. Roll to climb.'
          : 'Offline table ready. Roll when it is your turn.',
    );
    replaceWith('/game');
  }

  void createPrivateRoom(String mode) {
    if (connecting) return;
    markStartChoiceSeen();
    _ensurePlayerIdentity();
    pendingMatchMode = mode;
    fallbackBotStarted = false;
    currentMatchIsBot = false;
    _resetLiveMatch();
    connecting = true;
    privateInviteCode = null;
    _setStatus('Creating private room...');
    _openMatchmakingScreen();
    if (authToken == null || authToken!.isEmpty) {
      _ensureAuthenticatedIdentity().then((_) {
        if (!connecting || pendingMatchMode != mode) return;
        if (authToken == null || authToken!.isEmpty) {
          connecting = false;
          _setStatus(
              'Online sign-in is unavailable. Try again when connected.');
          return;
        }
        _sendCreatePrivateRoom(mode);
      });
      return;
    }
    _sendCreatePrivateRoom(mode);
  }

  void _sendCreatePrivateRoom(String mode) {
    _post(
      '/api/v1/rooms/private',
      {
        'playerId': playerId,
        'displayName': _humanDisplayName,
        'mode': mode,
        'region': matchmakingRegion,
      },
      (j) {
        final code = (j['code'] as String? ?? '').trim().toUpperCase();
        final socketUrl = j['socketUrl'] as String? ?? '';
        privateInviteCode = code.isEmpty ? null : code;
        if (socketUrl.isEmpty) {
          connecting = false;
          _setStatus(code.isEmpty
              ? 'Private room created.'
              : 'Private room $code created. Share the code.');
          return;
        }
        _connectWs(
          socketUrl,
          fillBots: false,
          readyStatus: code.isEmpty
              ? 'Private room ready. Waiting for players...'
              : 'Share code $code. Waiting for players...',
        );
        replaceWith('/game');
      },
      onError: () {
        connecting = false;
        privateInviteCode = null;
        _setStatus(
            'Could not create a private room. Check your connection and try again.');
      },
    );
  }

  void joinPrivateRoom(String code) {
    if (connecting) return;
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) {
      _setStatus('Enter a private room code.');
      return;
    }
    markStartChoiceSeen();
    _ensurePlayerIdentity();
    fallbackBotStarted = false;
    currentMatchIsBot = false;
    _resetLiveMatch();
    connecting = true;
    privateInviteCode = cleanCode;
    _setStatus('Joining private room $cleanCode...');
    _openMatchmakingScreen();
    if (authToken == null || authToken!.isEmpty) {
      _ensureAuthenticatedIdentity().then((_) {
        if (!connecting || privateInviteCode != cleanCode) return;
        if (authToken == null || authToken!.isEmpty) {
          connecting = false;
          privateInviteCode = null;
          _setStatus(
              'Online sign-in is unavailable. Try again when connected.');
          return;
        }
        _sendJoinPrivateRoom(cleanCode);
      });
      return;
    }
    _sendJoinPrivateRoom(cleanCode);
  }

  void _sendJoinPrivateRoom(String cleanCode) {
    _post(
      '/api/v1/rooms/private/join',
      {
        'playerId': playerId,
        'displayName': _humanDisplayName,
        'code': cleanCode,
      },
      (j) {
        pendingMatchMode = j['mode'] as String? ?? pendingMatchMode;
        final socketUrl = j['socketUrl'] as String? ?? '';
        if (socketUrl.isEmpty) {
          connecting = false;
          _setStatus('Private room found, but socket was missing.');
          return;
        }
        _connectWs(
          socketUrl,
          fillBots: false,
          readyStatus: 'Joined room $cleanCode. Waiting for players...',
        );
        replaceWith('/game');
      },
      onError: () {
        connecting = false;
        privateInviteCode = null;
        _setStatus(
            'Room code was not found, expired, or could not be reached.');
      },
    );
  }

  void cancelMatchmaking() {
    _matchmakingTimer?.cancel();
    _matchmakingTimer = null;
    if (connecting) {
      connecting = false;
      pendingMatchMode = 'classic_2p';
      _setStatus('Matchmaking cancelled.');
    }
  }

  void _openMatchmakingScreen() {
    clearTransientUi();
    navigatorKey.currentState?.pushNamed('/matchmaking');
  }

  void _scheduleLocalBotMatch(
    String mode, {
    required String reason,
    Duration delay = const Duration(milliseconds: 2500),
    String setupStatus = 'Setting up your game...',
  }) {
    _matchmakingTimer?.cancel();
    _matchmakingTimer = Timer(delay, () {
      _matchmakingTimer = null;
      if (!connecting || pendingMatchMode != mode) return;
      _setStatus(setupStatus);
      _startLocalBotMatch(mode, reason: reason);
      replaceWith('/game');
    });
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
          headers: _authorizedHeaders(),
        );
        final j = jsonDecode(r.body) as Map<String, dynamic>;
        final status = j['status'] as String? ?? 'waiting';
        if (status == 'matched') {
          final socketUrl = j['socketUrl'] as String? ?? '';
          if (socketUrl.isNotEmpty) {
            _connectWs(socketUrl);
            replaceWith('/game');
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

  void _connectWs(
    String socketPath, {
    bool fillBots = true,
    String? readyStatus,
  }) {
    localMatchActive = false;
    _localBotTimer?.cancel();
    _localBotTimer = null;
    _ws.playerId = playerId;
    _ws.displayName = _humanDisplayName;
    _ws.authToken = authToken;
    _ws.connect(socketPath);
    _wsSub?.cancel();
    _wsSub = _ws.messages.listen(_handleMessage);

    // Send join after connect (slight delay for WS handshake)
    Future.delayed(const Duration(milliseconds: 300), () {
      _ws.send({
        'type': 'join',
        'playerId': playerId,
        'displayName': _humanDisplayName
      });
      if (fillBots) {
        _ws.send({'type': 'fill_bots', 'playerId': playerId});
      }
      connecting = false;
      _setStatus(readyStatus ?? 'Table ready. Roll when it is your turn.');
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

      if (type == 'reaction') {
        _rememberReaction(envelope);
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

        _scheduleAutomaticTurnAction();

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
      final reason = e['reason'] as String? ?? '';
      if (reason == 'turn_timeout') {
        return mine
            ? 'You ran out of time. Turn passed.'
            : '${_playerName(snap, pid)} ran out of time.';
      }
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

  void _rememberReaction(Map<String, dynamic> e) {
    final text = (e['text'] as String? ?? '').trim();
    if (text.isEmpty) return;
    lastReactionText = text;
    lastReactionIsEmoji = e['isEmoji'] != false;
    lastReactionPlayerId = e['playerId'] as String?;
    reactionSequence++;
    notifyListeners();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  // Local bot table used when the online backend is unavailable.

  void _startLocalBotMatch(String mode, {required String reason}) {
    _ws.disconnect();
    _localBotTimer?.cancel();
    _localBotTimer = null;
    _autoRollTimer?.cancel();
    _autoRollTimer = null;

    if (playerId == null || playerId!.isEmpty) {
      playerId = 'local_${DateTime.now().millisecondsSinceEpoch}';
      _prefs.playerId = playerId;
    }

    final snakeMode = _isSnakesLaddersMode(mode);
    final maxPlayers = snakeMode ? 4 : _playersForMode(mode);
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

    final pieces = snakeMode
        ? <PieceState>[
            for (final seat in seats)
              PieceState(
                pieceId: 's${seat.seat}_snake',
                seat: seat.seat,
                state: 'track',
                progress: 1,
                trackIndex: 1,
              ),
          ]
        : <PieceState>[
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
    _matchResultTracked = false;
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
    _autoRollTimer?.cancel();
    _autoRollTimer = null;
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
    if (_isSnakesLaddersMode(snap.mode)) {
      _rollSnakesLaddersDice(snap);
      return;
    }

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
    if (autoRollEnabled && moves.length == 1) {
      _scheduleAutoMove(moves.single);
    }
  }

  void _rollSnakesLaddersDice(GameSnapshot snap) {
    final seat = mySeat ?? snap.currentTurnSeat;
    final value = _rng.nextInt(6) + 1;
    final moves = _snakesLaddersLegalMoves(snap, seat, value);

    SoundService.roll();
    lastRollValue = value;
    lastRollPlayerId = playerId;
    lastRollSequence++;

    if (moves.isEmpty) {
      lastSnapshot = _advanceLocalTurn(snap);
      _setStatus('You rolled $value. Need exact roll to reach 100.');
      _scheduleLocalBots();
      return;
    }

    lastSnapshot = _copySnapshot(
      snap,
      diceValue: value,
      availableMoves: moves,
    );
    _setStatus('You rolled $value. Tap to move.');
    if (autoRollEnabled && moves.length == 1) {
      _scheduleAutoMove(moves.single);
    }
  }

  void _moveLocalPiece(String pieceId) {
    _autoRollTimer?.cancel();
    _autoRollTimer = null;
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
    final after = _isSnakesLaddersMode(before.mode)
        ? _applySnakesLaddersMove(before, pieceId)
        : _applyLocalMove(before, pieceId);
    lastSnapshot = after;

    if (after.status == 'finished') {
      _setStatus(
        _isSnakesLaddersMode(after.mode)
            ? 'You reached 100 and won.'
            : 'You won the match.',
      );
      _trackMatchResult(after);
      Future.delayed(const Duration(milliseconds: 1200), () {
        navigateTo('/results');
      });
      return;
    }

    final sameTurn = after.currentTurnSeat == (mySeat ?? -1);
    if (_isSnakesLaddersMode(after.mode)) {
      _setStatus('You moved. ${_currentTurnLabel(after)} is next.');
      _scheduleLocalBots();
      return;
    }
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
    if (seat == null) return;
    if (!seat.isBot) {
      _scheduleAutoRoll(delay: delay);
      return;
    }

    _localBotTimer = Timer(delay, _playLocalBotTurn);
  }

  void _scheduleAutoRoll({
    Duration delay = const Duration(milliseconds: 520),
  }) {
    _autoRollTimer?.cancel();
    _autoRollTimer = null;
    if (!_canAutoRollNow) return;
    _autoRollTimer = Timer(delay, () {
      _autoRollTimer = null;
      if (_canAutoRollNow) _rollLocalDice();
    });
  }

  void _scheduleAutoMove(
    String pieceId, {
    Duration delay = const Duration(milliseconds: 520),
  }) {
    _autoRollTimer?.cancel();
    _autoRollTimer = null;
    if (!autoRollEnabled) return;
    _autoRollTimer = Timer(delay, () {
      _autoRollTimer = null;
      final snap = lastSnapshot;
      if (snap == null ||
          snap.status != 'playing' ||
          snap.availableMoves.length != 1 ||
          !snap.availableMoves.contains(pieceId) ||
          !_isMyTurn() ||
          !_hasDiceValue()) {
        return;
      }
      movePiece(pieceId);
    });
  }

  bool get _canAutoRollNow {
    if (!autoRollEnabled) return false;
    final snap = lastSnapshot;
    final seat = mySeat;
    return snap != null &&
        seat != null &&
        snap.status == 'playing' &&
        snap.currentTurnSeat == seat &&
        snap.diceValue == 0 &&
        (localMatchActive || _ws.isConnected);
  }

  void _scheduleAutomaticTurnAction() {
    if (!autoRollEnabled) return;
    final snap = lastSnapshot;
    if (snap == null || !_isMyTurn()) return;
    if (snap.diceValue > 0) {
      if (snap.availableMoves.length == 1) {
        _scheduleAutoMove(snap.availableMoves.single);
      }
      return;
    }
    _scheduleAutoRoll();
  }

  void _playLocalBotTurn() {
    if (!localMatchActive) return;
    final snap = lastSnapshot;
    if (snap == null || snap.status != 'playing') return;
    if (_isSnakesLaddersMode(snap.mode)) {
      _playSnakesLaddersBotTurn(snap);
      return;
    }
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

  void _playSnakesLaddersBotTurn(GameSnapshot snap) {
    final seat = _currentLocalSeat(snap);
    if (seat == null || !seat.isBot) return;

    final value = _rng.nextInt(6) + 1;
    final moves = _snakesLaddersLegalMoves(snap, seat.seat, value);
    final name = publicSeatName(seat);

    SoundService.roll();
    lastRollValue = value;
    lastRollPlayerId = seat.playerId;
    lastRollSequence++;

    if (moves.isEmpty) {
      lastSnapshot = _advanceLocalTurn(snap);
      _setStatus('$name rolled $value and needs exact roll for 100.');
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

      final move = moves.first;
      SoundService.move();
      final after = _applySnakesLaddersMove(current, move);
      lastSnapshot = after;

      if (after.status == 'finished') {
        _setStatus('$name reached 100 and won.');
        _trackMatchResult(after);
        Future.delayed(const Duration(milliseconds: 1200), () {
          navigateTo('/results');
        });
        return;
      }

      _setStatus('$name moved. ${_currentTurnLabel(after)} is next.');
      _scheduleLocalBots();
    });
  }

  GameSnapshot _applySnakesLaddersMove(GameSnapshot snap, String pieceId) {
    final dice = snap.diceValue;
    final movingPiece = snap.pieces.firstWhere((p) => p.pieceId == pieceId);
    final moverSeat = movingPiece.seat;
    final rolledProgress = movingPiece.progress + dice;
    final nextProgress = _snakeLadders[rolledProgress] ??
        _snakeDrops[rolledProgress] ??
        rolledProgress;
    final nextState =
        nextProgress >= _snakeFinishProgress ? 'finished' : 'track';

    final pieces = snap.pieces.map((piece) {
      if (piece.pieceId != pieceId) return piece;
      return PieceState(
        pieceId: piece.pieceId,
        seat: piece.seat,
        state: nextState,
        progress: nextProgress,
        trackIndex: nextProgress,
      );
    }).toList();

    final winner = nextProgress >= _snakeFinishProgress
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

    return _advanceLocalTurn(
      _copySnapshot(
        snap,
        pieces: pieces,
        diceValue: 0,
        availableMoves: const [],
      ),
    );
  }

  GameSnapshot _applyLocalMove(GameSnapshot snap, String pieceId) {
    final dice = snap.diceValue;
    final movingPiece = snap.pieces.firstWhere((p) => p.pieceId == pieceId);
    final moverSeat = movingPiece.seat;
    final nextProgress =
        movingPiece.progress == _yardProgress ? 0 : movingPiece.progress + dice;
    final nextTrack = _trackIndexFor(moverSeat, nextProgress, snap.mode);
    final nextState = _stateForProgress(nextProgress, snap.mode);

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

    if (nextTrack != null &&
        !_safeTrackIndexesForMode(snap.mode).contains(nextTrack)) {
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
    if (_isSnakesLaddersMode(snap.mode)) {
      return _snakesLaddersLegalMoves(snap, seat, diceValue);
    }
    return snap.pieces
        .where((piece) => piece.seat == seat)
        .where((piece) => _canLocalPieceMove(piece, diceValue, snap.mode))
        .map((piece) => piece.pieceId)
        .toList();
  }

  List<String> _snakesLaddersLegalMoves(
      GameSnapshot snap, int seat, int diceValue) {
    return snap.pieces
        .where((piece) => piece.seat == seat)
        .where((piece) =>
            piece.state != 'finished' &&
            piece.progress + diceValue <= _snakeFinishProgress)
        .map((piece) => piece.pieceId)
        .toList();
  }

  bool _canLocalPieceMove(PieceState piece, int diceValue, String mode) {
    if (piece.state == 'finished') return false;
    if (piece.progress == _yardProgress) return diceValue == 6;
    return piece.progress + diceValue <= _finishProgressForMode(mode);
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
    if (_isSnakesLaddersMode(snap.mode)) {
      final rolled = piece.progress + snap.diceValue;
      final landed = _snakeLadders[rolled] ?? _snakeDrops[rolled] ?? rolled;
      return landed + (_snakeLadders.containsKey(rolled) ? 60 : 0);
    }
    if (piece.progress == _yardProgress) return 30;

    final nextProgress = piece.progress + snap.diceValue;
    final nextTrack = _trackIndexFor(piece.seat, nextProgress, snap.mode);
    final captures = nextTrack != null &&
        !_safeTrackIndexesForMode(snap.mode).contains(nextTrack) &&
        snap.pieces.any((other) =>
            other.seat != piece.seat &&
            other.trackIndex == nextTrack &&
            other.state == 'track');
    return nextProgress + (captures ? 100 : 0);
  }

  int _nextLocalDice(GameSnapshot snap, int seat) {
    if (_isSnakesLaddersMode(snap.mode)) {
      return _rng.nextInt(6) + 1;
    }
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

  int? _trackIndexFor(int seat, int progress, String mode) {
    if (_isSnakesLaddersMode(mode)) {
      if (progress < 1 || progress > _snakeFinishProgress) return null;
      return progress;
    }
    final trackLength = _trackLengthForMode(mode);
    final starts = _startOffsetsForMode(mode);
    if (progress < 0 || progress >= trackLength) return null;
    return (starts[seat.clamp(0, starts.length - 1)] + progress) % trackLength;
  }

  String _stateForProgress(int progress, String mode) {
    if (_isSnakesLaddersMode(mode)) {
      return progress >= _snakeFinishProgress ? 'finished' : 'track';
    }
    if (progress == _yardProgress) return 'yard';
    if (progress >= _finishProgressForMode(mode)) return 'finished';
    if (progress >= _trackLengthForMode(mode)) return 'home';
    return 'track';
  }

  int _playersForMode(String mode) {
    final clean = mode.toLowerCase();
    if (_isSnakesLaddersMode(mode)) return 4;
    if (clean.contains('4p') || clean.contains('4_player')) return 4;
    if (clean.contains('3p') || clean.contains('3_player')) return 3;
    return 2;
  }

  bool _isSnakesLaddersMode(String mode) =>
      mode.toLowerCase() == snakesLaddersMode;

  int _trackLengthForMode(String mode) =>
      _isSnakesLaddersMode(mode) ? _snakeFinishProgress : _classicTrackLength;

  int _finishProgressForMode(String mode) => _isSnakesLaddersMode(mode)
      ? _snakeFinishProgress
      : _classicFinishProgress;

  List<int> _startOffsetsForMode(String mode) => _localStartOffsets;

  Set<int> _safeTrackIndexesForMode(String mode) => _localSafeTrackIndexes;

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

  void _ensurePlayerIdentity() {
    if (playerId != null && playerId!.isNotEmpty) return;
    playerId = 'local_${DateTime.now().millisecondsSinceEpoch}';
    authToken = null;
    _prefs.playerId = playerId;
    _prefs.authToken = null;
    _ws.playerId = playerId;
    _ws.displayName = displayName;
    _ws.authToken = null;
  }

  void _applyPlayer(Map<String, dynamic> player) {
    playerId = player['id'] as String? ?? playerId;
    displayName = player['displayName'] as String? ?? displayName;
    rating = player['rating'] as int? ?? rating;
    coins = player['coins'] as int? ?? coins;

    _ws.playerId = playerId;
    _ws.displayName = displayName;
    _prefs.playerId = playerId;
    _prefs.displayName = displayName;
    _prefs.rating = rating;
    _prefs.coins = coins;
    notifyListeners();
  }

  void _trackMatchResult(GameSnapshot snap) {
    if (_matchResultTracked) return;
    _matchResultTracked = true;
    final economyEligible = !localMatchActive && !currentMatchIsBot;
    _localBotTimer?.cancel();
    _localBotTimer = null;
    localMatchActive = false;
    gamesPlayed++;
    final won = playerId != null && playerId == snap.winnerPlayerId;
    if (won) {
      SoundService.success();
      if (economyEligible) {
        wins++;
        rating += 12;
        coins += GameEconomy.onlineWinCoins;
      }
    } else {
      SoundService.warning();
      if (economyEligible) {
        rating = (rating - 6).clamp(0, 9999);
        coins += GameEconomy.onlineFinishCoins;
      }
    }
    _prefs.gamesPlayed = gamesPlayed;
    _prefs.wins = wins;
    _prefs.rating = rating;
    _prefs.coins = coins;
    _ws.disconnect();
    lastRollValue = 0;
    lastRollPlayerId = null;
    notifyListeners();
    if (economyEligible) unawaited(refreshSocial());
  }

  void _resetLiveMatch() {
    _matchmakingTimer?.cancel();
    _matchmakingTimer = null;
    _localBotTimer?.cancel();
    _localBotTimer = null;
    _autoRollTimer?.cancel();
    _autoRollTimer = null;
    localMatchActive = false;
    _ws.disconnect();
    lastSnapshot = null;
    privateInviteCode = null;
    lastRollValue = 0;
    lastRollPlayerId = null;
    lastRollSequence = 0;
    lastReactionText = null;
    lastReactionPlayerId = null;
    reactionSequence = 0;
    _matchResultTracked = false;
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

  int _readInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? fallback;
    return fallback;
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
          headers: _authorizedHeaders(),
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 6))
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

  Future<void> syncSocialProfile({bool notify = true}) async {
    _ensurePlayerIdentity();
    try {
      await _requestJson(
        'POST',
        '/api/v1/social/profile',
        body: {
          'playerId': playerId,
          'displayName': _humanDisplayName,
          'countryCode': countryCode,
          'avatarKey': 'preset_$avatarPreset',
          'age': age,
        },
      );
      socialError = '';
    } catch (error) {
      socialError = _cleanApiError(error);
    }
    if (notify) notifyListeners();
  }

  Future<void> refreshSocial({bool notify = true}) async {
    _ensurePlayerIdentity();
    socialLoading = true;
    if (notify) notifyListeners();
    try {
      final json = await _requestJson(
        'GET',
        '/api/v1/social/overview',
        query: {'playerId': playerId!},
      );
      friends = _socialPlayers(json['friends']);
      recentOpponents = _socialPlayers(json['recentOpponents']);
      incomingFriendRequests = _socialPlayers(json['incomingRequests']);
      outgoingFriendRequests = _socialPlayers(json['outgoingRequests']);
      final giftsRaw = json['receivedGifts'] as List<dynamic>? ?? const [];
      receivedFriendGifts = giftsRaw
          .whereType<Map<String, dynamic>>()
          .map(ReceivedFriendGift.fromJson)
          .where((gift) => gift.id.isNotEmpty)
          .toList(growable: false);
      final productsRaw = json['ownedProductIds'] as List<dynamic>? ?? const [];
      ownedProductIds = productsRaw
          .whereType<String>()
          .map((product) => product.trim())
          .where((product) => product.isNotEmpty)
          .toSet();
      final clubsRaw = json['clubs'] as List<dynamic>? ?? const [];
      clubs = clubsRaw
          .whereType<Map<String, dynamic>>()
          .map(ClubSummary.fromJson)
          .where((club) => club.id.isNotEmpty)
          .toList(growable: false);
      final currentClubRaw = json['currentClub'];
      currentClub = currentClubRaw is Map<String, dynamic>
          ? ClubSummary.fromJson(currentClubRaw)
          : null;
      if (!isBoardThemeUnlocked(snakesBoardTheme)) {
        snakesBoardTheme = 'carnival';
        _prefs.snakesBoardTheme = snakesBoardTheme;
      }
      if (!isBoardThemeUnlocked(ludoBoardTheme)) {
        ludoBoardTheme = 'carnival';
        _prefs.ludoBoardTheme = ludoBoardTheme;
      }
      if (!isDiceSkinUnlocked(diceSkin)) {
        diceSkin = 'classic';
        _prefs.diceSkin = diceSkin;
      }
      if (!isAvatarUnlocked(avatarPreset)) {
        avatarPreset = 0;
        _prefs.avatarPreset = avatarPreset;
      }
      final serverCoins = _readInt(json['coins'], fallback: coins);
      if (serverCoins >= 0) {
        coins = serverCoins;
        _prefs.coins = coins;
      }
      gamesPlayed = _readInt(json['gamesPlayed'], fallback: gamesPlayed);
      wins = _readInt(json['wins'], fallback: wins);
      _availableGoldChests = _readInt(
        json['availableGoldChests'],
        fallback: _availableGoldChests,
      );
      _prefs.gamesPlayed = gamesPlayed;
      _prefs.wins = wins;
      economySynced = true;
      socialError = '';
    } catch (error) {
      socialError = _cleanApiError(error);
    } finally {
      socialLoading = false;
      if (notify) notifyListeners();
    }
  }

  Future<String> requestFriend(String targetPlayerId) async {
    return _socialMutation(
      '/api/v1/social/friends/request',
      targetPlayerId: targetPlayerId,
      success: 'Friend request sent.',
    );
  }

  Future<String> acceptFriend(String targetPlayerId) async {
    return _socialMutation(
      '/api/v1/social/friends/accept',
      targetPlayerId: targetPlayerId,
      success: 'Friend request accepted.',
    );
  }

  Future<String> removeFriend(String targetPlayerId) async {
    return _socialMutation(
      '/api/v1/social/friends/remove',
      targetPlayerId: targetPlayerId,
      success: 'Friend removed.',
    );
  }

  Future<String> sendFriendGift(String targetPlayerId, String giftId) async {
    try {
      final json = await _requestJson(
        'POST',
        '/api/v1/social/gifts',
        body: {
          'playerId': playerId,
          'targetPlayerId': targetPlayerId,
          'giftId': giftId,
        },
      );
      coins = _readInt(json['coins'], fallback: coins);
      _prefs.coins = coins;
      socialError = '';
      notifyListeners();
      return 'Gift sent.';
    } catch (error) {
      final message = _cleanApiError(error);
      socialError = message;
      notifyListeners();
      return message;
    }
  }

  Future<String> loadFriendMessages() async {
    if (!canUseChat) return 'Friends chat is available for age 13+ profiles.';
    try {
      final json = await _requestJson(
        'GET',
        '/api/v1/social/messages',
        query: {'playerId': playerId!},
      );
      final raw = json['messages'] as List<dynamic>? ?? const [];
      friendMessages = raw
          .whereType<Map<String, dynamic>>()
          .map(FriendChatMessage.fromJson)
          .toList(growable: false);
      socialError = '';
      notifyListeners();
      return '';
    } catch (error) {
      final message = _cleanApiError(error);
      socialError = message;
      notifyListeners();
      return message;
    }
  }

  Future<String> sendFriendMessage(String message) async {
    if (!canUseChat) return 'Friends chat is available for age 13+ profiles.';
    final clean = message.trim();
    if (clean.isEmpty) return 'Enter a message first.';
    try {
      await _requestJson(
        'POST',
        '/api/v1/social/messages',
        body: {'playerId': playerId, 'message': clean},
      );
      await loadFriendMessages();
      return '';
    } catch (error) {
      final result = _cleanApiError(error);
      socialError = result;
      notifyListeners();
      return result;
    }
  }

  Future<String> _socialMutation(
    String path, {
    required String targetPlayerId,
    required String success,
  }) async {
    try {
      await _requestJson(
        'POST',
        path,
        body: {
          'playerId': playerId,
          'targetPlayerId': targetPlayerId,
        },
      );
      await refreshSocial();
      return success;
    } catch (error) {
      final message = _cleanApiError(error);
      socialError = message;
      notifyListeners();
      return message;
    }
  }

  Future<Map<String, dynamic>> _requestJson(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) async {
    if (authToken == null || authToken!.isEmpty) {
      await _ensureAuthenticatedIdentity();
    }
    final uri = Uri.parse('$_backendUrl$path').replace(queryParameters: query);
    final response = method == 'GET'
        ? await http
            .get(uri, headers: _authorizedHeaders())
            .timeout(const Duration(seconds: 7))
        : await http
            .post(
              uri,
              headers: _authorizedHeaders(),
              body: jsonEncode(body ?? const <String, dynamic>{}),
            )
            .timeout(const Duration(seconds: 7));
    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw StateError(decoded['error'] as String? ??
          'Request failed (${response.statusCode}).');
    }
    return decoded;
  }

  Map<String, String> _authorizedHeaders() {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = authToken;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  List<SocialPlayer> _socialPlayers(dynamic value) {
    final raw = value as List<dynamic>? ?? const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(SocialPlayer.fromJson)
        .where((player) => player.id.isNotEmpty)
        .toList(growable: false);
  }

  String _cleanApiError(Object error) {
    final message = error.toString().replaceFirst('Bad state: ', '').trim();
    return message.isEmpty ? 'Could not reach the social service.' : message;
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

  bool get canUseChat => age >= 13;

  void setMatchDifficulty(String value) {
    final normalized = _normalizeDifficulty(value);
    if (normalized == matchDifficulty) return;
    SoundService.tap();
    matchDifficulty = normalized;
    _prefs.matchDifficulty = matchDifficulty;
    notifyListeners();
  }

  void setSnakesBoardTheme(String value) {
    final normalized = _normalizeSnakesBoardTheme(value);
    if (!isBoardThemeUnlocked(normalized)) {
      _setStatus(boardThemeUnlockLabel(normalized));
      return;
    }
    if (normalized == snakesBoardTheme) return;
    SoundService.tap();
    snakesBoardTheme = normalized;
    _prefs.snakesBoardTheme = snakesBoardTheme;
    notifyListeners();
  }

  void setLudoBoardTheme(String value) {
    final normalized = _normalizeLudoBoardTheme(value);
    if (!isBoardThemeUnlocked(normalized)) {
      _setStatus(boardThemeUnlockLabel(normalized));
      return;
    }
    if (normalized == ludoBoardTheme) return;
    SoundService.tap();
    ludoBoardTheme = normalized;
    _prefs.ludoBoardTheme = ludoBoardTheme;
    notifyListeners();
  }

  void setSoundtrack(String value) {
    final normalized = SoundtrackCatalog.normalize(value);
    final selectionChanged = normalized != soundtrackId || !musicEnabled;
    soundtrackId = normalized;
    musicEnabled = true;
    _prefs.soundtrackId = soundtrackId;
    _prefs.musicEnabled = true;
    unawaited(_soundtrack.select(soundtrackId));
    if (selectionChanged) notifyListeners();
  }

  void setMusicEnabled(bool value) {
    if (musicEnabled == value) return;
    SoundService.tap();
    musicEnabled = value;
    _prefs.musicEnabled = musicEnabled;
    unawaited(_soundtrack.setEnabled(musicEnabled));
    notifyListeners();
  }

  bool get canClaimDailyReward => lastDailyRewardDate != _todayKey();

  int get dailyRewardAmount => GameEconomy.dailyCoins;

  Future<bool> claimDailyReward() async {
    SoundService.tap();
    try {
      final json = await _requestJson(
        'POST',
        '/api/v1/social/rewards/daily',
        body: {'playerId': playerId},
      );
      final claimed = json['claimed'] == true;
      coins = _readInt(json['coins'], fallback: coins);
      lastDailyRewardDate =
          (json['periodKey'] as String? ?? _todayKey()).trim();
      _prefs.coins = coins;
      _prefs.lastDailyRewardDate = lastDailyRewardDate;
      socialError = '';
      notifyListeners();
      return claimed;
    } catch (error) {
      socialError = _cleanApiError(error);
      notifyListeners();
      return false;
    }
  }

  int get availableGoldChests => economySynced
      ? _availableGoldChests
      : math.max(
          0,
          (wins ~/ GameEconomy.winsPerGoldChest) - claimedGoldChests,
        );

  Future<bool> claimGoldChest() async {
    try {
      final json = await _requestJson(
        'POST',
        '/api/v1/social/rewards/gold-chest',
        body: {'playerId': playerId},
      );
      coins = _readInt(json['coins'], fallback: coins);
      _availableGoldChests = _readInt(
        json['availableGoldChests'],
        fallback: math.max(0, availableGoldChests - 1),
      );
      economySynced = true;
      claimedGoldChests++;
      _prefs.claimedGoldChests = claimedGoldChests;
      _prefs.coins = coins;
      socialError = '';
      notifyListeners();
      return json['claimed'] == true;
    } catch (error) {
      socialError = _cleanApiError(error);
      notifyListeners();
      return false;
    }
  }

  void setDiceSkin(String value) {
    final normalized = _normalizeDiceSkin(value);
    if (!isDiceSkinUnlocked(normalized)) {
      _setStatus(diceSkinUnlockLabel(normalized));
      return;
    }
    if (normalized == diceSkin) return;
    SoundService.tap();
    diceSkin = normalized;
    _prefs.diceSkin = diceSkin;
    notifyListeners();
  }

  bool isDiceSkinPremium(String value) =>
      _premiumDicePrices.containsKey(_normalizeDiceSkin(value));

  bool isBoardThemePremium(String value) =>
      _premiumBoardPrices.containsKey(_normalizeSnakesBoardTheme(value));

  String? diceSkinPremiumPrice(String value) =>
      _premiumDicePrices[_normalizeDiceSkin(value)];

  String? boardThemePremiumPrice(String value) =>
      _premiumBoardPrices[_normalizeSnakesBoardTheme(value)];

  int diceSkinRequiredWins(String value) =>
      _diceUnlockWins[_normalizeDiceSkin(value)] ?? 0;

  int boardThemeRequiredWins(String value) =>
      _boardUnlockWins[_normalizeSnakesBoardTheme(value)] ?? 0;

  bool isDiceSkinUnlocked(String value) {
    final normalized = _normalizeDiceSkin(value);
    if (isDiceSkinPremium(normalized)) {
      return ownedProductIds.contains('dice.$normalized');
    }
    return wins >= diceSkinRequiredWins(normalized);
  }

  bool isBoardThemeUnlocked(String value) {
    final normalized = _normalizeSnakesBoardTheme(value);
    if (isBoardThemePremium(normalized)) {
      return ownedProductIds.contains('board.$normalized');
    }
    return wins >= boardThemeRequiredWins(normalized);
  }

  String diceSkinUnlockLabel(String value) {
    final normalized = _normalizeDiceSkin(value);
    if (isDiceSkinUnlocked(normalized)) return 'Dice unlocked.';
    final premium = diceSkinPremiumPrice(normalized);
    if (premium != null) return 'Premium dice unlocks with $premium.';
    final needed = diceSkinRequiredWins(normalized);
    final left = math.max(0, needed - wins);
    return left == 0
        ? 'Dice unlocked.'
        : 'Win $left more ${left == 1 ? 'game' : 'games'} to unlock this dice.';
  }

  String boardThemeUnlockLabel(String value) {
    final normalized = _normalizeSnakesBoardTheme(value);
    if (isBoardThemeUnlocked(normalized)) return 'Board unlocked.';
    final premium = boardThemePremiumPrice(normalized);
    if (premium != null) return 'Premium board unlocks with $premium.';
    final needed = boardThemeRequiredWins(normalized);
    final left = math.max(0, needed - wins);
    return left == 0
        ? 'Board unlocked.'
        : 'Win $left more ${left == 1 ? 'game' : 'games'} to unlock this board.';
  }

  Future<String> joinClub(String clubId) async {
    try {
      await _requestJson(
        'POST',
        '/api/v1/social/clubs/join',
        body: {'clubId': clubId},
      );
      await refreshSocial();
      return 'Club joined.';
    } catch (error) {
      final message = _cleanApiError(error);
      socialError = message;
      notifyListeners();
      return message;
    }
  }

  Future<String> leaveClub() async {
    try {
      await _requestJson('POST', '/api/v1/social/clubs/leave');
      await refreshSocial();
      return 'Club left.';
    } catch (error) {
      final message = _cleanApiError(error);
      socialError = message;
      notifyListeners();
      return message;
    }
  }

  bool isAvatarUnlocked(int preset) {
    final avatar = avatarForPreset(preset);
    switch (avatar.rarity) {
      case AvatarRarity.common:
        return true;
      case AvatarRarity.rare:
        return wins >= avatar.requiredWins;
      case AvatarRarity.premium:
        return ownedProductIds.contains('avatar.${avatar.id}');
    }
  }

  String avatarUnlockLabel(int preset) {
    final avatar = avatarForPreset(preset);
    switch (avatar.rarity) {
      case AvatarRarity.common:
        return 'Included';
      case AvatarRarity.rare:
        final left = math.max(0, avatar.requiredWins - wins);
        return left == 0
            ? 'Unlocked'
            : 'Win $left more ${left == 1 ? 'game' : 'games'}';
      case AvatarRarity.premium:
        if (isAvatarUnlocked(preset)) return 'Owned';
        return avatar.price ?? 'Premium';
    }
  }

  String rewardEconomySummary() {
    final unlocks = <({int atWins, String label})>[
      for (final entry in _diceUnlockWins.entries)
        if (entry.value > 0) (atWins: entry.value, label: '${entry.key} dice'),
      for (final entry in _boardUnlockWins.entries)
        if (entry.value > 0)
          (atWins: entry.value, label: '${entry.key} board skin'),
      for (final avatar in profileAvatarCatalog)
        if (avatar.rarity == AvatarRarity.rare)
          (atWins: avatar.requiredWins, label: '${avatar.label} avatar'),
    ]..sort((a, b) => a.atWins.compareTo(b.atWins));
    final next = unlocks.where((unlock) => unlock.atWins > wins).firstOrNull;
    if (next == null) {
      return 'All win-tier cosmetics are unlocked. Premium cosmetics remain optional.';
    }
    final left = next.atWins - wins;
    return 'Next unlock: ${next.label} in $left ${left == 1 ? 'online win' : 'online wins'}.';
  }

  void setAutoRollEnabled(bool value) {
    if (autoRollEnabled == value) return;
    SoundService.tap();
    autoRollEnabled = value;
    _prefs.autoRollEnabled = autoRollEnabled;
    _autoRollTimer?.cancel();
    _autoRollTimer = null;
    if (value) {
      _scheduleAutoRoll(delay: const Duration(milliseconds: 220));
      _setStatus(
          'Auto roll enabled. Choose a goti when more than one can move.');
    } else {
      _setStatus('Auto roll disabled.');
    }
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

  String _normalizeSnakesBoardTheme(String value) {
    switch (value.trim().toLowerCase()) {
      case 'royal':
      case 'neon':
      case 'classic':
      case 'jungle':
        return value.trim().toLowerCase();
      case 'carnival':
      default:
        return 'carnival';
    }
  }

  String _normalizeLudoBoardTheme(String value) {
    switch (value.trim().toLowerCase()) {
      case 'royal':
      case 'neon':
      case 'classic':
        return value.trim().toLowerCase();
      case 'carnival':
      default:
        return 'carnival';
    }
  }

  String _normalizeDiceSkin(String value) {
    switch (value.trim().toLowerCase()) {
      case 'royal':
      case 'neon':
      case 'ruby':
      case 'emerald':
      case 'cosmic':
      case 'classic':
        return value.trim().toLowerCase();
      default:
        return 'classic';
    }
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  String get matchmakingRegion {
    switch (countryCode.toUpperCase()) {
      case 'IN':
      case 'PK':
      case 'BD':
      case 'LK':
        return 'south-asia';
      case 'GB':
      case 'DE':
      case 'FR':
      case 'ES':
        return 'europe';
      case 'AE':
      case 'SA':
        return 'middle-east';
      case 'AU':
        return 'east-asia';
      case 'BR':
        return 'us-east';
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
    int? age,
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
      final normalizedAvatar = avatar.clamp(0, profileAvatarCatalog.length - 1);
      if (isAvatarUnlocked(normalizedAvatar)) {
        avatarPreset = normalizedAvatar;
        _prefs.avatarPreset = avatarPreset;
        if (clearImage) {
          avatarImagePath = null;
          _prefs.avatarImagePath = null;
        }
      } else {
        _setStatus(avatarUnlockLabel(normalizedAvatar));
      }
    }
    if (age != null) {
      this.age = age.clamp(0, 120);
      _prefs.age = this.age;
    }
    if (imagePath != null && imagePath.trim().isNotEmpty) {
      avatarImagePath = imagePath;
      _prefs.avatarImagePath = imagePath;
    } else if (clearImage) {
      avatarImagePath = null;
      _prefs.avatarImagePath = null;
    }
    notifyListeners();
    unawaited(syncSocialProfile());
  }
}
