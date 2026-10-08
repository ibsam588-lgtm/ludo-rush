import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_rush/services/review_prompt_policy.dart';

class _MemoryReviewStore implements ReviewPromptStore {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async {
    this.value = value;
  }

  Map<String, dynamic> get state => value == null
      ? <String, dynamic>{}
      : jsonDecode(value!) as Map<String, dynamic>;
}

class _FakeClock {
  DateTime value = DateTime.utc(2026, 1, 1);
  Future<DateTime> now() async => value;
}

ReviewPromptPolicy _policy({
  required _MemoryReviewStore store,
  required _FakeClock clock,
  required String session,
  required List<String> requests,
  Future<void> Function()? requestReview,
}) =>
    ReviewPromptPolicy(
      store: store,
      appSessionId: session,
      now: clock.now,
      requestReview: requestReview ?? () async => requests.add(session),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('waits for four post-onboarding successful app sessions', () async {
    final store = _MemoryReviewStore();
    final clock = _FakeClock();
    final requests = <String>[];

    expect(
      await _policy(
              store: store, clock: clock, session: 's0', requests: requests)
          .recordCompletedMatch(
        matchId: 'before-onboarding',
        onboardingComplete: false,
        safeToPrompt: true,
      ),
      ReviewPromptDecision.ignored,
    );

    for (var i = 1; i <= 3; i++) {
      expect(
        await _policy(
                store: store, clock: clock, session: 's$i', requests: requests)
            .recordCompletedMatch(
          matchId: 'match-$i',
          onboardingComplete: true,
          safeToPrompt: true,
        ),
        ReviewPromptDecision.recorded,
      );
    }
    expect(requests, isEmpty);

    expect(
      await _policy(
              store: store, clock: clock, session: 's4', requests: requests)
          .recordCompletedMatch(
        matchId: 'match-4',
        onboardingComplete: true,
        safeToPrompt: true,
      ),
      ReviewPromptDecision.requested,
    );
    expect(requests, ['s4']);
    expect(store.state['successfulSessions'], 4);
    expect(store.state['attempts'], 1);
    expect(store.state.containsKey('hasReviewed'), isFalse);
  });

  test('counts at most one successful session and one request per match',
      () async {
    final store = _MemoryReviewStore();
    final clock = _FakeClock();
    final requests = <String>[];
    final policy = _policy(
      store: store,
      clock: clock,
      session: 'same-session',
      requests: requests,
    );

    expect(
      await policy.recordCompletedMatch(
        matchId: 'same-match',
        onboardingComplete: true,
        safeToPrompt: true,
      ),
      ReviewPromptDecision.recorded,
    );
    expect(
      await policy.recordCompletedMatch(
        matchId: 'same-match',
        onboardingComplete: true,
        safeToPrompt: true,
      ),
      ReviewPromptDecision.duplicate,
    );
    await policy.recordCompletedMatch(
      matchId: 'another-match-this-session',
      onboardingComplete: true,
      safeToPrompt: true,
    );

    expect(store.state['successfulSessions'], 1);
    expect(store.state['attempts'], 0);
  });

  test('serializes concurrent duplicate result callbacks', () async {
    final store = _MemoryReviewStore();
    final clock = _FakeClock();
    final requests = <String>[];
    final policy = _policy(
      store: store,
      clock: clock,
      session: 'one-session',
      requests: requests,
    );

    final results = await Future.wait([
      policy.recordCompletedMatch(
        matchId: 'one-match',
        onboardingComplete: true,
        safeToPrompt: true,
      ),
      policy.recordCompletedMatch(
        matchId: 'one-match',
        onboardingComplete: true,
        safeToPrompt: true,
      ),
    ]);

    expect(results,
        [ReviewPromptDecision.recorded, ReviewPromptDecision.duplicate]);
    expect(store.state['successfulSessions'], 1);
    expect(requests, isEmpty);
  });

  test('requires four more successful sessions and thirty days per retry',
      () async {
    final store = _MemoryReviewStore();
    final clock = _FakeClock();
    final requests = <String>[];

    Future<ReviewPromptDecision> finish(int index) => _policy(
                store: store,
                clock: clock,
                session: 's$index',
                requests: requests)
            .recordCompletedMatch(
          matchId: 'm$index',
          onboardingComplete: true,
          safeToPrompt: true,
        );

    for (var i = 1; i <= 4; i++) {
      await finish(i);
    }
    expect(requests.length, 1);

    clock.value = clock.value.add(const Duration(days: 10));
    for (var i = 5; i <= 7; i++) {
      expect(await finish(i), ReviewPromptDecision.recorded);
    }
    expect(requests.length, 1);
    expect(await finish(8), ReviewPromptDecision.recorded);
    expect(requests.length, 1);
    clock.value = clock.value.add(const Duration(days: 20));
    expect(await finish(9), ReviewPromptDecision.requested);
    expect(requests.length, 2);

    clock.value = clock.value.add(const Duration(days: 10));
    for (var i = 10; i <= 13; i++) {
      expect(await finish(i), ReviewPromptDecision.recorded);
    }
    expect(requests.length, 2);
    clock.value = clock.value.add(const Duration(days: 20));
    expect(await finish(14), ReviewPromptDecision.requested);
    expect(requests.length, 3);
  });

  test('defers unsafe UI and records failed API calls as attempts', () async {
    final store = _MemoryReviewStore();
    final clock = _FakeClock();
    final requests = <String>[];
    for (var i = 1; i <= 3; i++) {
      await _policy(
              store: store, clock: clock, session: 's$i', requests: requests)
          .recordCompletedMatch(
        matchId: 'm$i',
        onboardingComplete: true,
        safeToPrompt: true,
      );
    }

    expect(
      await _policy(
              store: store, clock: clock, session: 's4', requests: requests)
          .recordCompletedMatch(
        matchId: 'm4',
        onboardingComplete: true,
        safeToPrompt: false,
      ),
      ReviewPromptDecision.deferred,
    );
    expect(store.state['attempts'], 0);
    expect(
      await _policy(
        store: store,
        clock: clock,
        session: 's5',
        requests: requests,
        requestReview: () async => throw StateError('platform unavailable'),
      ).recordCompletedMatch(
        matchId: 'm5',
        onboardingComplete: true,
        safeToPrompt: true,
      ),
      ReviewPromptDecision.requested,
    );
    expect(store.state['attempts'], 1);
    expect(requests, isEmpty);
  });
}
