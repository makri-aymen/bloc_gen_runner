import 'dart:async';

import 'package:bloc/bloc.dart';

// ── Public API ─────────────────────────────────────────────────────────────

/// Throttle: processes the **first** event immediately, then ignores every
/// subsequent event for [duration] (leading-edge throttle).
///
/// Optionally compose with another transformer via [andThen]:
/// ```dart
/// throttle(500.ms, andThen: droppable())   // throttle → droppable
/// throttle(500.ms)                          // standalone (sequential map)
/// ```
EventTransformer<Event> throttle<Event>(
  Duration duration, {
  EventTransformer<Event>? andThen,
}) {
  return (events, mapper) {
    final throttled = events.transform(_ThrottleStreamTransformer(duration));
    return andThen != null ? andThen(throttled, mapper) : throttled.asyncExpand(mapper);
  };
}

// ── Throttle stream transformer ────────────────────────────────────────────

/// Passes the first item through immediately, then suppresses items for
/// [duration] (leading-edge / head throttle).
class _ThrottleStreamTransformer<T> extends StreamTransformerBase<T, T> {
  _ThrottleStreamTransformer(this.duration);

  final Duration duration;

  @override
  Stream<T> bind(Stream<T> stream) {
    Timer? cooldown;
    late StreamSubscription<T> subscription;

    final controller = StreamController<T>(
      onCancel: () {
        cooldown?.cancel();
        return subscription.cancel();
      },
      sync: true,
    );

    subscription = stream.listen(
      (event) {
        // While the cooldown is active, drop the event entirely.
        if (cooldown != null) return;

        controller.add(event);
        // Start the silence window; null it out when it expires so the
        // next event passes through again.
        cooldown = Timer(duration, () => cooldown = null);
      },
      onError: controller.addError,
      onDone: () {
        cooldown?.cancel();
        controller.close();
      },
    );

    return controller.stream;
  }
}
