import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:ludo_rush/models/game_snapshot.dart';
import 'package:ludo_rush/screens/game_screen.dart';
import 'package:ludo_rush/screens/shop_screen.dart';
import 'package:ludo_rush/services/prefs_service.dart';
import 'package:ludo_rush/services/websocket_service.dart';
import 'package:ludo_rush/state/app_state.dart';

class FixedDice implements math.Random {
  final int value;
  FixedDice(this.value);
  @override
  int nextInt(int max) => value - 1;
  @override
  bool nextBool() => false;
  @override
  double nextDouble() => 0;
}

class FakeSocket implements WebSocketChannel {
  final incoming = StreamController<dynamic>();
  final handshake = Completer<void>();
  @override
  late final FakeSink sink = FakeSink();
  @override
  Stream<dynamic> get stream => incoming.stream;
  @override
  Future<void> get ready => handshake.future;
  @override
  String? get protocol => null;
  @override
  int? get closeCode => null;
  @override
  String? get closeReason => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  void complete() => handshake.complete();
}

class FakeSink implements WebSocketSink {
  final sent = <Map<String, dynamic>>[];
  final closed = Completer<void>();
  @override
  void add(dynamic data) =>
      sent.add(jsonDecode(data as String) as Map<String, dynamic>);
  @override
  void addError(Object error, [StackTrace? stackTrace]) {}
  @override
  Future<void> addStream(Stream<dynamic> stream) async {
    await for (final item in stream) {
      add(item);
    }
  }

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {
    if (!closed.isCompleted) closed.complete();
  }

  @override
  Future<void> get done => closed.future;
}

Map<String, dynamic> onlineSnapshot({int dice = 0}) => {
      'status': 'playing',
      'mode': 'classic_2p',
      'currentTurnSeat': 0,
      'diceValue': dice,
      'seats': [
        {'seat': 0, 'playerId': 'me', 'displayName': 'Me', 'isBot': false},
        {'seat': 1, 'playerId': 'other', 'displayName': 'Other', 'isBot': false}
      ],
      'pieces': [
        {
          'pieceId': 's0_p0',
          'seat': 0,
          'state': 'yard',
          'progress': -1,
          'trackIndex': -1
        }
      ],
      'availableMoves': dice == 6 ? ['s0_p0'] : <String>[],
    };

Map<String, dynamic> onlineSnakesSnapshot({int dice = 0, int progress = 1}) => {
      'roomId': 'snakes_room',
      'status': 'playing',
      'mode': AppState.snakesLaddersMode,
      'currentTurnSeat': 0,
      'diceValue': dice,
      'turnDeadlineAt': DateTime.now()
          .add(const Duration(seconds: 25))
          .millisecondsSinceEpoch,
      'seats': [
        for (var seat = 0; seat < 4; seat++)
          {
            'seat': seat,
            'playerId': seat == 0 ? 'me' : 'other_$seat',
            'displayName': seat == 0 ? 'Me' : 'Other $seat',
            'isBot': false,
            'connected': true,
          }
      ],
      'pieces': [
        for (var seat = 0; seat < 4; seat++)
          {
            'pieceId': 's${seat}_snake',
            'seat': seat,
            'state': 'track',
            'progress': seat == 0 ? progress : 1,
            'trackIndex': seat == 0 ? progress : 1,
          }
      ],
      'availableMoves': dice > 0 ? ['s0_snake'] : <String>[],
    };

void main() {
  testWidgets(
      'a complete seeded Snakes match finishes without manual token moves',
      (tester) async {
    final state = AppState(PrefsService(), random: math.Random(42))
      ..playerId = 'me'
      ..autoRollEnabled = true;
    await state.startOfflineMatch(AppState.snakesLaddersMode);
    for (var tick = 0;
        tick < 2000 && state.lastSnapshot!.status != 'finished';
        tick++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(state.lastSnapshot!.status, 'finished');
    expect(state.lastSnapshot!.pieces.any((p) => p.progress == 100), isTrue);
    expect(state.lastMatchRewards!.practice, isTrue);
    expect(state.coins, 500);
    expect(state.rating, 1000);
    state.dispose();
  });

  testWidgets('replay cancels a pending automatic Snakes move', (tester) async {
    final state = AppState(PrefsService(), random: FixedDice(5))
      ..playerId = 'me';
    await state.startOfflineMatch(AppState.snakesLaddersMode);
    state.rollDice();
    await tester.pump(const Duration(milliseconds: 200));
    state.resign();
    await state.startOfflineMatch(AppState.snakesLaddersMode);
    await tester.pump(const Duration(seconds: 1));
    expect(state.lastSnapshot!.pieces.first.progress, 1);
    expect(state.lastSnapshot!.diceValue, 0);
    state.dispose();
  });

  testWidgets('online search gives humans time to join and remains cancellable',
      (tester) async {
    var requests = 0;
    final state =
        AppState(PrefsService(), matchmakingClient: MockClient((_) async {
      requests++;
      return http.Response(
          jsonEncode({'status': 'waiting', 'ticketId': 'waiting'}), 200);
    }))
          ..playerId = 'me'
          ..authToken = 'test-token';
    await state.startQuickMatch('classic_4p');
    await tester.pump();
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(seconds: 2));
    }
    expect(state.connecting, isTrue);
    expect(state.currentMatchIsBot, isFalse);
    expect(state.fallbackBotStarted, isFalse);
    state.cancelMatchmaking();
    await tester.pump();
    final cancelledRequests = requests;
    await tester.pump(const Duration(seconds: 5));
    expect(requests, cancelledRequests);
    expect(state.connecting, isFalse);
    state.dispose();
  });

  testWidgets(
      'Snakes shop scroll reaches the last live board and opens its preview',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 480));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final state = AppState(PrefsService());
    final equipped = state.snakesBoardTheme;
    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: state, child: const MaterialApp(home: ShopScreen())));
    await tester.tap(find.byKey(const ValueKey('shop-category-Snakes')));
    await tester.pump();
    final scroll = find
        .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable))
        .first;
    final board = find.byKey(const ValueKey('snakes-theme-volcano'));
    await tester.scrollUntilVisible(board, 200, scrollable: scroll);
    await tester.tap(board);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('LIVE PREVIEW'), findsOneWidget);
    expect(state.snakesBoardTheme, equipped);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    state.dispose();
  });

  testWidgets(
      'Snakes board scrolls on short phones and plays complete turns with one dice tap',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 480));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final state = AppState(PrefsService(), random: FixedDice(5))
      ..playerId = 'me';
    await state.startOfflineMatch(AppState.snakesLaddersMode);
    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: state, child: const MaterialApp(home: GameScreen())));
    await tester.pump();
    final scrolling = tester.state<ScrollableState>(find
        .descendant(
            of: find.byKey(const ValueKey('match-board-scroll')),
            matching: find.byType(Scrollable))
        .first);
    expect(scrolling.position.maxScrollExtent, greaterThan(100));
    expect(scrolling.position.pixels, scrolling.position.maxScrollExtent);
    expect(find.byKey(const ValueKey('find-my-token')), findsOneWidget);
    expect(find.byKey(const ValueKey('turn-timer')), findsOneWidget);
    await tester.drag(
        find.byKey(const ValueKey('match-board-scroll')), const Offset(0, 100));
    await tester.pump(const Duration(milliseconds: 100));
    expect(scrolling.position.pixels,
        lessThan(scrolling.position.maxScrollExtent));
    expect(state.lastRollSequence, 0);
    final before = state.lastSnapshot!.pieces.first.progress;
    await tester.tap(find.text('Tap to Roll'));
    await tester.pump();
    expect(state.lastRollValue, 5);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(state.lastSnapshot!.pieces.first.progress, 26);
    expect(state.lastSnapshot!.pieces.first.progress, greaterThan(before));
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(state.lastSnapshot!.currentTurnSeat, state.mySeat);
    expect(find.text('Tap to Roll'), findsOneWidget);
    await tester.tap(find.text('Tap to Roll'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(state.lastSnapshot!.pieces.first.progress, 31);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    state.dispose();
  });

  testWidgets(
      'Snakes exact finish and overshoot remain playable without a second tap',
      (tester) async {
    for (final value in [1, 6]) {
      final state = AppState(PrefsService(), random: FixedDice(value))
        ..playerId = 'me';
      await state.startOfflineMatch(AppState.snakesLaddersMode);
      final snap = state.lastSnapshot!;
      state.lastSnapshot = GameSnapshot(
          seats: snap.seats,
          pieces: [
            for (final piece in snap.pieces)
              if (piece.seat == 0)
                PieceState(
                    pieceId: piece.pieceId,
                    seat: 0,
                    state: 'track',
                    progress: 99,
                    trackIndex: 99)
              else
                piece
          ],
          diceValue: 0,
          currentTurnSeat: 0,
          status: 'playing',
          availableMoves: const [],
          winnerPlayerId: '',
          mode: snap.mode);
      state.rollDice();
      await tester.pump(const Duration(milliseconds: 800));
      expect(state.lastSnapshot!.pieces.first.progress, value == 1 ? 100 : 99);
      expect(state.lastSnapshot!.status, value == 1 ? 'finished' : 'playing');
      if (value == 1) expect(state.lastMatchRewards!.coins, 0);
      state.dispose();
    }
  });

  testWidgets('local turn timer advances an idle player safely',
      (tester) async {
    final state = AppState(PrefsService())..playerId = 'me';
    await state.startOfflineMatch(AppState.snakesLaddersMode);
    final snap = state.lastSnapshot!;
    state.lastSnapshot = GameSnapshot(
      roomId: snap.roomId,
      seats: snap.seats,
      pieces: snap.pieces,
      diceValue: 0,
      currentTurnSeat: 0,
      status: 'playing',
      availableMoves: const [],
      winnerPlayerId: '',
      mode: snap.mode,
      turnStartedAt: DateTime.now().millisecondsSinceEpoch - 31000,
      turnDeadlineAt: DateTime.now().millisecondsSinceEpoch - 1000,
    );

    state.expireLocalTurnIfNeeded();

    expect(state.lastSnapshot!.currentTurnSeat, 1);
    expect(state.statusText, contains('Time is up'));
    state.dispose();
  });

  testWidgets(
      'Snakes quick match connects online and auto-moves the single token',
      (tester) async {
    final socket = FakeSocket();
    final service = WebSocketService(connector: (_) => socket);
    String? requestedMode;
    final state = AppState(PrefsService(), webSocketService: service,
        matchmakingClient: MockClient((request) async {
      requestedMode =
          (jsonDecode(request.body) as Map<String, dynamic>)['mode'] as String?;
      return http.Response(
          jsonEncode({'status': 'matched', 'socketUrl': '/room/snakes'}), 200);
    }))
      ..playerId = 'me'
      ..authToken = 'test-token';

    await state.startQuickMatch(AppState.snakesLaddersMode);
    await tester.pump();
    expect(requestedMode, AppState.snakesLaddersMode);
    expect(state.localMatchActive, isFalse);
    expect(state.currentMatchIsBot, isFalse);
    socket.complete();
    await tester.pump();
    socket.incoming.add(jsonEncode({
      'type': 'snapshot',
      'snapshot': onlineSnakesSnapshot(),
    }));
    await tester.pump();
    socket.incoming.add(jsonEncode({
      'type': 'dice_rolled',
      'playerId': 'me',
      'value': 5,
      'snapshot': onlineSnakesSnapshot(dice: 5),
    }));
    await tester.pump(const Duration(milliseconds: 800));
    expect(socket.sink.sent.map((message) => message['type']),
        containsAllInOrder(['join', 'move_piece']));
    expect(socket.sink.sent.last['pieceId'], 's0_snake');
    state.dispose();
  });

  testWidgets(
      'websocket waits for handshake, rejoins after drop, and ignores replaced connections',
      (tester) async {
    final sockets = <FakeSocket>[];
    final service = WebSocketService(connector: (_) {
      final socket = FakeSocket();
      sockets.add(socket);
      return socket;
    })
      ..playerId = 'me';
    service.connect('/room/one');
    await tester.pump(const Duration(seconds: 1));
    expect(service.isConnected, isFalse);
    expect(sockets.first.sink.sent, isEmpty);
    sockets.first.complete();
    await tester.pump();
    expect(service.isConnected, isTrue);
    expect(sockets.first.sink.sent.single['type'], 'join');
    await sockets.first.incoming.close();
    await tester.pump();
    expect(service.isConnected, isFalse);
    await tester.pump(const Duration(seconds: 3));
    sockets.last.complete();
    await tester.pump();
    expect(sockets.last.sink.sent.single['type'], 'join');
    service.connect('/room/two');
    service.disconnect();
    sockets.last.complete();
    await tester.pump(const Duration(seconds: 5));
    expect(service.isConnected, isFalse);
    expect(sockets.last.sink.sent, isEmpty);
    expect(sockets.length, 3);
    service.dispose();
  });

  testWidgets('spectator websocket remains read-only after reconnect',
      (tester) async {
    final sockets = <FakeSocket>[];
    final service = WebSocketService(connector: (_) {
      final socket = FakeSocket();
      sockets.add(socket);
      return socket;
    })
      ..playerId = 'viewer'
      ..displayName = 'Viewer'
      ..spectator = true;

    service.connect('/room/watch?spectator=1');
    sockets.first.complete();
    await tester.pump();
    expect(sockets.first.sink.sent.single['type'], 'spectate');

    await sockets.first.incoming.close();
    await tester.pump(const Duration(seconds: 3));
    sockets.last.complete();
    await tester.pump();
    expect(sockets.last.sink.sent.single['type'], 'spectate');
    expect(service.phase, SocketConnectionPhase.connected);
    service.dispose();
  });

  testWidgets(
      'online match keeps human seats and auto-roll sends a server action',
      (tester) async {
    final socket = FakeSocket();
    final service = WebSocketService(connector: (_) => socket);
    final state = AppState(PrefsService(),
        webSocketService: service,
        matchmakingClient: MockClient((_) async => http.Response(
            jsonEncode({'status': 'matched', 'socketUrl': '/room/test'}), 200)))
      ..playerId = 'me'
      ..authToken = 'test-token';
    await state.startQuickMatch('classic_2p');
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(state.connecting, isTrue);
    expect(socket.sink.sent, isEmpty);
    socket.complete();
    await tester.pump();
    socket.incoming
        .add(jsonEncode({'type': 'snapshot', 'snapshot': onlineSnapshot()}));
    await tester.pump();
    expect(state.connecting, isFalse);
    state.setAutoRollEnabled(true);
    await tester.pump(const Duration(milliseconds: 230));
    expect(socket.sink.sent.map((m) => m['type']), ['join', 'roll_dice']);
    expect(state.lastSnapshot!.diceValue, 0);
    expect(state.lastRollSequence, 0);
    expect(state.localMatchActive, isFalse);
    socket.incoming.add(jsonEncode({
      'type': 'dice_rolled',
      'playerId': 'me',
      'value': 6,
      'snapshot': onlineSnapshot(dice: 6)
    }));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(socket.sink.sent.last['type'], 'move_piece');
    expect(socket.sink.sent.any((m) => m['type'] == 'fill_bots'), isFalse);
    state.dispose();
  });
}
