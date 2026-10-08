import 'dart:async';
import 'dart:convert';

abstract interface class ReviewPromptStore {
  Future<String?> read();
  Future<void> write(String value);
}

enum ReviewPromptDecision { ignored, recorded, duplicate, deferred, requested }

/// Persistent, serialized policy for Play review requests.
///
/// A successful match counts once per app process/session. Review API
/// completion is never treated as evidence that a dialog appeared or a review
/// was submitted.
class ReviewPromptPolicy {
  ReviewPromptPolicy({
    required ReviewPromptStore store,
    required String appSessionId,
    required Future<DateTime> Function() now,
    required Future<void> Function() requestReview,
    this.minimumSessionsBeforeFirstRequest = 4,
    this.sessionsBetweenRequests = 4,
    this.minimumCooldown = const Duration(days: 30),
  }) : _store = store,
       _appSessionId = appSessionId,
       _now = now,
       _requestReview = requestReview;

  static const int _matchHistoryLimit = 256;

  final ReviewPromptStore _store;
  final String _appSessionId;
  final Future<DateTime> Function() _now;
  final Future<void> Function() _requestReview;
  final int minimumSessionsBeforeFirstRequest;
  final int sessionsBetweenRequests;
  final Duration minimumCooldown;
  Future<void> _queue = Future<void>.value();

  Future<ReviewPromptDecision> recordCompletedMatch({
    required String matchId,
    required bool onboardingComplete,
    required bool safeToPrompt,
  }) {
    final result = Completer<ReviewPromptDecision>();
    _queue = _queue.then((_) async {
      try {
        result.complete(
          await _record(
            matchId: matchId,
            onboardingComplete: onboardingComplete,
            safeToPrompt: safeToPrompt,
          ),
        );
      } catch (error, stack) {
        result.completeError(error, stack);
      }
    });
    return result.future;
  }

  Future<ReviewPromptDecision> _record({
    required String matchId,
    required bool onboardingComplete,
    required bool safeToPrompt,
  }) async {
    final id = matchId.trim();
    if (!onboardingComplete || id.isEmpty) return ReviewPromptDecision.ignored;

    final state = _decode(await _store.read());
    state['successfulSessions'] = _readInt(state['successfulSessions']);
    state['attempts'] = _readInt(state['attempts']);
    state['lastAttemptAt'] = _readInt(state['lastAttemptAt']);
    state['lastAttemptSession'] = _readInt(state['lastAttemptSession']);
    final matches = (state['matches'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList(growable: true);
    if (matches.contains(id)) return ReviewPromptDecision.duplicate;

    matches.add(id);
    if (matches.length > _matchHistoryLimit) {
      matches.removeRange(0, matches.length - _matchHistoryLimit);
    }
    state['matches'] = matches;

    if (state['lastCountedSession'] != _appSessionId) {
      state['successfulSessions'] = _readInt(state['successfulSessions']) + 1;
      state['lastCountedSession'] = _appSessionId;
    }

    final successfulSessions = _readInt(state['successfulSessions']);
    final attempts = _readInt(state['attempts']);
    final lastAttemptAt = _readInt(state['lastAttemptAt']);
    final lastAttemptSession = _readInt(state['lastAttemptSession']);
    final now = await _now();

    final eligible = attempts == 0
        ? successfulSessions >= minimumSessionsBeforeFirstRequest
        : successfulSessions - lastAttemptSession >= sessionsBetweenRequests &&
              lastAttemptAt > 0 &&
              !now.isBefore(
                DateTime.fromMillisecondsSinceEpoch(
                  lastAttemptAt,
                ).add(minimumCooldown),
              );

    if (!eligible || !safeToPrompt) {
      await _store.write(jsonEncode(state));
      return safeToPrompt
          ? ReviewPromptDecision.recorded
          : ReviewPromptDecision.deferred;
    }

    // Persist the attempt before crossing the platform boundary so a crash,
    // duplicate widget, or thrown API call cannot prompt twice.
    state['attempts'] = attempts + 1;
    state['lastAttemptAt'] = now.millisecondsSinceEpoch;
    state['lastAttemptSession'] = successfulSessions;
    await _store.write(jsonEncode(state));
    try {
      await _requestReview();
    } catch (_) {
      // The API does not report whether Play displayed or received a review.
    }
    return ReviewPromptDecision.requested;
  }

  static Map<String, dynamic> _decode(String? raw) {
    if (raw == null || raw.isEmpty) return <String, dynamic>{};
    try {
      final value = jsonDecode(raw);
      return value is Map<String, dynamic> ? value : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  static int _readInt(dynamic value) => value is int ? value : 0;
}
