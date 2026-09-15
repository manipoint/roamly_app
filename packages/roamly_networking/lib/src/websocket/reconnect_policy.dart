import 'dart:math';

/// Calculates bounded exponential backoff with equal jitter.
///
/// Retry attempts are one-based. Returns null when attempts are exhausted.
final class ReconnectPolicy {
  ReconnectPolicy({
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
    this.maxAttempts = 8,
    Random? random,
  }) : _random = random ?? Random() {
    if (initialDelay <= Duration.zero) {
      throw ArgumentError.value(
        initialDelay,
        'initialDelay',
        'Must be greater than zero.',
      );
    }

    if (maxDelay < initialDelay) {
      throw ArgumentError.value(
        maxDelay,
        'maxDelay',
        'Must be at least initialDelay.',
      );
    }

    if (maxAttempts < 0) {
      throw ArgumentError.value(
        maxAttempts,
        'maxAttempts',
        'Must not be negative.',
      );
    }
  }

  final Duration initialDelay;
  final Duration maxDelay;
  final int maxAttempts;

  final Random _random;

  Duration? delayForRetry(int attempt) {
    if (attempt < 1) {
      throw ArgumentError.value(
        attempt,
        'attempt',
        'Retry attempts start at one.',
      );
    }

    if (attempt > maxAttempts) {
      return null;
    }

    final maximumMicros = maxDelay.inMicroseconds;
    var ceilingMicros = initialDelay.inMicroseconds;

    for (var step = 1; step < attempt; step++) {
      if (ceilingMicros >= maximumMicros) {
        break;
      }

      // Cap before multiplication to avoid integer overflow.
      if (ceilingMicros > maximumMicros ~/ 2) {
        ceilingMicros = maximumMicros;
        break;
      }

      ceilingMicros *= 2;
    }

    // Equal jitter: wait between half and the full backoff ceiling.
    // Rounding upward also keeps very small delays above zero.
    final minimumMicros = ceilingMicros - ceilingMicros ~/ 2;
    final jitterRange = ceilingMicros - minimumMicros;
    final jitterMicros = (_random.nextDouble() * jitterRange).floor();

    return Duration(microseconds: minimumMicros + jitterMicros);
  }
}
