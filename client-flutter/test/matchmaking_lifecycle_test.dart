import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:ludo_rush/models/game_snapshot.dart';
import 'package:ludo_rush/screens/matchmaking_screen.dart';
import 'package:ludo_rush/services/prefs_service.dart';
import 'package:ludo_rush/state/app_state.dart';

class RecordingState extends AppState {
  RecordingState(http.Client client)
      : super(PrefsService(), matchmakingClient: client) {
    playerId = 'test-player';
    authToken = 'test-token';
  }
  final routes = <String>[];
  @override
  void replaceWith(String route, {Object? arguments}) => routes.add(route);
  @override
  void navigateTo(String route, {Object? arguments}) => routes.add(route);
}

http.Response response(Map<String, dynamic> value) =>
    http.Response(jsonEncode(value), 200);

void main() {
  for (final lateResponse in ['matched', 'error']) {
    testWidgets('cancel ignores late quick-match $lateResponse',
        (tester) async {
      final pending = Completer<http.Response>();
      final state = RecordingState(MockClient((_) => pending.future));
      await state.startQuickMatch('classic_2p');
      await tester.pump();
      state.cancelMatchmaking();
      if (lateResponse == 'matched') {
        pending
            .complete(response({'status': 'matched', 'socketUrl': '/ws/old'}));
      } else {
        pending.completeError(Exception('offline'));
      }
      await tester.pump(const Duration(seconds: 10));
      expect(state.connecting, isFalse);
      expect(state.fallbackBotStarted, isFalse);
      expect(state.lastSnapshot, isNull);
      expect(state.routes, isEmpty);
      state.dispose();
    });
  }

  testWidgets(
      'same-mode retry ignores the previous request and cancels its ticket',
      (tester) async {
    final first = Completer<http.Response>();
    final second = Completer<http.Response>();
    final cancellations = <String>[];
    var requests = 0;
    final state = RecordingState(MockClient((request) {
      if (request.url.path.endsWith('/cancel')) {
        cancellations.add(request.url.path);
        return Future.value(response({'status': 'cancelled'}));
      }
      return requests++ == 0 ? first.future : second.future;
    }));
    await state.startQuickMatch('classic_2p');
    await tester.pump();
    state.cancelMatchmaking();
    await state.startQuickMatch('classic_2p');
    await tester.pump();
    first.complete(response({'status': 'waiting', 'ticketId': 'old-ticket'}));
    await tester.pump();
    expect(state.connecting, isTrue);
    expect(state.fallbackBotStarted, isFalse);
    expect(cancellations.single, endsWith('/old-ticket/cancel'));
    state.cancelMatchmaking();
    second.complete(response({'status': 'matched', 'socketUrl': '/ws/new'}));
    await tester.pump(const Duration(seconds: 10));
    expect(state.routes, isEmpty);
    state.dispose();
  });

  testWidgets('cancel stops ticket polling and removes the server queue entry',
      (tester) async {
    final paths = <String>[];
    final state = RecordingState(MockClient((request) async {
      paths.add(request.url.path);
      return response({'status': 'waiting', 'ticketId': 'queued'});
    }));
    await state.startQuickMatch('classic_2p');
    await tester.pump();
    state.cancelMatchmaking();
    await tester.pump(const Duration(seconds: 10));
    expect(paths, [
      '/api/v1/matchmaking/quick',
      '/api/v1/matchmaking/tickets/queued/cancel'
    ]);
    expect(state.routes, isEmpty);
    state.dispose();
  });

  testWidgets('in-flight ticket result cannot replace a new offline game',
      (tester) async {
    final poll = Completer<http.Response>();
    final state = RecordingState(MockClient((request) async {
      if (request.method == 'GET') return poll.future;
      return response({'status': 'waiting', 'ticketId': 'queued'});
    }));
    await state.startQuickMatch('classic_2p');
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    state.cancelMatchmaking();
    await state.startOfflineMatch(AppState.snakesLaddersMode);
    final game = state.lastSnapshot;
    poll.complete(response({'status': 'matched', 'socketUrl': '/ws/stale'}));
    await tester.pump();
    expect(identical(state.lastSnapshot, game), isTrue);
    expect(state.routes, ['/game']);
    expect(state.localMatchActive, isTrue);
    state.dispose();
  });

  testWidgets('disposing while matchmaking ignores late responses',
      (tester) async {
    final pending = Completer<http.Response>();
    final state = RecordingState(MockClient((_) => pending.future));
    await state.startQuickMatch('classic_2p');
    state.dispose();
    pending.complete(response({'status': 'matched', 'socketUrl': '/ws/stale'}));
    await tester.pump(const Duration(seconds: 10));
    expect(state.routes, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('network failure starts a cancellable practice fallback',
      (tester) async {
    final state =
        RecordingState(MockClient((_) async => http.Response('', 503)));
    await state.startQuickMatch('classic_2p');
    await tester.pump();
    expect(state.statusText, 'Preparing your table...');
    expect(state.currentMatchIsBot, isTrue);
    state.cancelMatchmaking();
    await tester.pump(const Duration(seconds: 2));
    expect(state.routes, isEmpty);
    state.dispose();
  });

  testWidgets('matching banner omits no-live-players copy', (tester) async {
    final state = RecordingState(MockClient((_) async => response({})))
      ..connecting = true
      ..statusText = 'No live player found. Starting a bot match...';
    await tester.pumpWidget(ChangeNotifierProvider<AppState>.value(
      value: state,
      child: const MaterialApp(home: MatchmakingScreen()),
    ));
    expect(find.textContaining('No live player'), findsNothing);
    expect(find.text('Finding your table...'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    state.dispose();
  });

  testWidgets('a finished game cannot open results over its replay',
      (tester) async {
    final state = RecordingState(MockClient((_) async => response({})));
    await state.startOfflineMatch(AppState.snakesLaddersMode);
    final snap = state.lastSnapshot!;
    final piece = snap.pieces.firstWhere((p) => p.seat == state.mySeat);
    state.lastSnapshot = GameSnapshot(
      seats: snap.seats,
      pieces: [
        for (final p in snap.pieces)
          p == piece
              ? PieceState(
                  pieceId: p.pieceId,
                  seat: p.seat,
                  state: 'track',
                  progress: 99,
                  trackIndex: 99)
              : p
      ],
      diceValue: 1,
      currentTurnSeat: piece.seat,
      status: 'playing',
      availableMoves: [piece.pieceId],
      winnerPlayerId: '',
      mode: snap.mode,
    );
    state.movePiece(piece.pieceId);
    expect(state.lastSnapshot!.status, 'finished');
    expect(state.coins, 500);
    expect(state.wins, 0);
    expect(state.lastMatchRewards!.practice, isTrue);
    expect(state.lastMatchRewards!.coins, 0);
    expect(state.lastMatchRewards!.rating, 0);
    await state.startOfflineMatch(AppState.snakesLaddersMode);
    expect(state.lastMatchRewards, isNull);
    await tester.pump(const Duration(seconds: 2));
    expect(state.routes, ['/game', '/game']);
    expect(state.lastSnapshot!.status, 'playing');
    state.dispose();
  });
}
