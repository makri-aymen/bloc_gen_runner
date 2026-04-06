import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';

// ── Contract ───────────────────────────────────────────────────────────────

abstract class EventGenerated {
  const EventGenerated();

  EventTransformer? get transformer => null;
}

mixin BlocTransformerMixin<Event, State> on Bloc<Event, State> {
  @override
  void on<E extends Event>(
    EventHandler<E, State> handler, {
    EventTransformer<E>? transformer,
  }) {
    super.on<E>(handler, transformer: _eventDrivenTransformer<E>());
  }

  EventTransformer<E> _eventDrivenTransformer<E extends Event>() {
    return (events, mapper) {
      EventTransformer<E>? resolved;
      StreamSubscription<E>? eventSub;
      StreamSubscription<dynamic>? resolvedSub;
      StreamController<E>? relay;

      late final StreamController<E> output;
      output = StreamController<E>(
        onListen: () {
          relay = StreamController<E>(sync: true);

          eventSub = events.listen(
            (event) {
              if (resolved == null) {
                // Only events that extend EventGenerated carry a transformer
                final configuredTransformer = event is EventGenerated ? (event as EventGenerated).transformer : null;

                resolved = (configuredTransformer ?? concurrent()) as EventTransformer<E>;

                resolvedSub = resolved!(relay!.stream, mapper).listen(
                  output.add,
                  onError: output.addError,
                  onDone: output.close,
                );
              }
              relay!.add(event);
            },
            onError: (Object e, StackTrace st) => relay!.addError(e, st),
            onDone: relay!.close,
          );
        },
        onCancel: () async {
          await eventSub?.cancel();
          await resolvedSub?.cancel();
          if (relay?.isClosed == false) relay?.close();
        },
        sync: true,
      );

      return output.stream;
    };
  }
}
