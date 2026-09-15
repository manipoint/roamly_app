import 'dart:math';

import 'package:roamly_networking/src/websocket/reconnect_policy.dart';
import 'package:test/test.dart';

void main() {
  group('ReconnectPolicy', () {
    test('uses exponential windows and caps the delay', () {
      final policy = ReconnectPolicy(random: Random(42));
      const ceilings = [1, 2, 4, 8, 16, 30, 30, 30];

      for (var attempt = 1; attempt <= ceilings.length; attempt++) {
        final ceiling = Duration(seconds: ceilings[attempt - 1]);
        for (var sample = 0; sample < 50; sample++) {
          final delay = policy.delayForRetry(attempt)!;
          expect(
            delay.inMicroseconds,
            inInclusiveRange(
              ceiling.inMicroseconds ~/ 2,
              ceiling.inMicroseconds,
            ),
          );
        }
      }
    });

    test('jitter produces different delays within one retry window', () {
      final policy = ReconnectPolicy(random: Random(42));
      final delays = List.generate(20, (_) => policy.delayForRetry(3));
      expect(delays.toSet().length, greaterThan(1));
    });

    test('allows eight retries after the initial attempt', () {
      final policy = ReconnectPolicy();
      expect(policy.delayForRetry(8), isNotNull);
      expect(policy.delayForRetry(9), isNull);
      expect(policy.delayForRetry(100), isNull);
    });

    test('supports disabling retries', () {
      final policy = ReconnectPolicy(maxAttempts: 0);
      expect(policy.delayForRetry(1), isNull);
    });

    test('supports custom delay caps and attempt limits', () {
      final policy = ReconnectPolicy(
        initialDelay: const Duration(milliseconds: 200),
        maxDelay: const Duration(milliseconds: 750),
        maxAttempts: 4,
        random: Random(42),
      );
      const ceilings = [200000, 400000, 750000, 750000];
      for (var attempt = 1; attempt <= 4; attempt++) {
        final ceiling = ceilings[attempt - 1];
        expect(
          policy.delayForRetry(attempt)!.inMicroseconds,
          inInclusiveRange(ceiling ~/ 2, ceiling),
        );
      }
      expect(policy.delayForRetry(5), isNull);
    });

    test('keeps microsecond delays positive', () {
      final policy = ReconnectPolicy(
        initialDelay: const Duration(microseconds: 1),
        maxDelay: const Duration(microseconds: 1),
      );
      expect(policy.delayForRetry(1), const Duration(microseconds: 1));
      expect(policy.delayForRetry(8), const Duration(microseconds: 1));
    });

    test('caps very large retry indices without exponential overflow', () {
      final policy = ReconnectPolicy(maxAttempts: 1000000000);
      expect(
        policy.delayForRetry(1000000000)!.inMicroseconds,
        inInclusiveRange(15000000, 30000000),
      );
    });

    test('can reproduce delays with an injected random source', () {
      final first = ReconnectPolicy(random: Random(42));
      final second = ReconnectPolicy(random: Random(42));
      for (var attempt = 1; attempt <= 8; attempt++) {
        expect(first.delayForRetry(attempt), second.delayForRetry(attempt));
      }
    });

    for (final delay in [Duration.zero, const Duration(microseconds: -1)]) {
      test('rejects non-positive initial delay: $delay', () {
        expect(() => ReconnectPolicy(initialDelay: delay), throwsArgumentError);
      });
    }

    test('rejects a maximum below the initial delay', () {
      expect(
        () => ReconnectPolicy(maxDelay: const Duration(milliseconds: 500)),
        throwsArgumentError,
      );
    });

    test('rejects a negative retry limit', () {
      expect(() => ReconnectPolicy(maxAttempts: -1), throwsArgumentError);
    });

    for (final attempt in [0, -1]) {
      test('rejects invalid retry index: $attempt', () {
        expect(
          () => ReconnectPolicy().delayForRetry(attempt),
          throwsArgumentError,
        );
      });
    }
  });
}
