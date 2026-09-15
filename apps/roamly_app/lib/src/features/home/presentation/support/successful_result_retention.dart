import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

final class SuccessfulResultRetention {
  SuccessfulResultRetention({required Ref ref, required Duration duration})
    : _ref = ref,
      _duration = duration {
    if (duration <= Duration.zero) {
      throw ArgumentError.value(
        duration,
        'duration',
        'Cache duration must be positive.',
      );
    }

    ref.onDispose(_release);
  }

  final Ref _ref;
  final Duration _duration;

  KeepAliveLink? _link;
  Timer? _timer;

  void retain() {
    if (!_ref.mounted) return;
    _link ??= _ref.keepAlive();
    _timer?.cancel();
    _timer = Timer(_duration, () {
      _link?.close();
      _link = null;
      _timer = null;
    });
  }

  void _release() {
    _timer?.cancel();
    _timer = null;
    _link = null;
  }
}
