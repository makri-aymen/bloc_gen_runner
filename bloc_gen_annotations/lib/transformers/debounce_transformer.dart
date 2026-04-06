import 'dart:async';

import 'package:bloc/bloc.dart';

// ── Public API ─────────────────────────────────────────────────────────────

/// Debounce: waits [duration] of silence after the last event, then processes
/// the most recent one.
///
/// Optionally compose with another transformer via [andThen]:
/// ```dart
/// debounce(300.ms, andThen: droppable())   // debounce → droppable
/// debounce(300.ms)                          // standalone (sequential map)
/// ```
EventTransformer<Event> debounce<Event>(
  Duration duration, {
  EventTransformer<Event>? andThen,
}) {
  return (events, mapper) {
    final debounced = events.transform(_DebounceStreamTransformer(duration));
    // If a downstream transformer is provided, pipe the debounced stream into
    // it so the caller controls concurrency (droppable, restartable, …).
    // Otherwise fall back to sequential (asyncExpand).
    return andThen != null ? andThen(debounced, mapper) : debounced.asyncExpand(mapper);
  };
}

// ── Debounce stream transformer ────────────────────────────────────────────

/// Delays each item until [duration] has passed with no new items.
/// If a new item arrives before the timer fires the previous item is discarded
/// and the timer restarts.
class _DebounceStreamTransformer<T> extends StreamTransformerBase<T, T> {
  _DebounceStreamTransformer(this.duration);

  final Duration duration;

  @override
  Stream<T> bind(Stream<T> stream) {
    Timer? timer;
    late StreamSubscription<T> subscription;

    final controller = StreamController<T>(
      onCancel: () {
        timer?.cancel();
        return subscription.cancel();
      },
      sync: true,
    );

    subscription = stream.listen(
      (event) {
        // Cancel the pending flush and start a fresh countdown.
        timer?.cancel();
        timer = Timer(duration, () => controller.add(event));
      },
      onError: controller.addError,
      onDone: () {
        // Do NOT flush the pending event on close — debounce semantics
        // mean the event was never "settled". Cancel and close cleanly.
        timer?.cancel();
        controller.close();
      },
    );

    return controller.stream;
  }
}
