import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';

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
    // We pass the handler (mapper) into our custom logic
    super.on<E>(handler, transformer: _eventDrivenTransformer<E>());
  }

  EventTransformer<E> _eventDrivenTransformer<E extends Event>() {
    return (events, mapper) {
      StreamSubscription? resolvedSub;
      StreamController<E>? relay;

      // Use dynamic or the appropriate return type for the transformer output
      late final StreamController<dynamic> output;

      output = StreamController<dynamic>(
        onListen: () {
          relay = StreamController<E>(sync: true);

          events.listen(
            (event) {
              if (resolvedSub == null) {
                final dynamic selectedTransformer = event is EventGenerated ? (event as EventGenerated).transformer : concurrent();
                final Stream<dynamic> resultStream = selectedTransformer(relay!.stream.cast<dynamic>(), mapper);
                resolvedSub = resultStream.listen(
                  output.add,
                  onError: output.addError,
                  onDone: output.close,
                );
              }
              relay?.add(event);
            },
            onDone: () => relay?.close(),
          );
        },
        onCancel: () {
          resolvedSub?.cancel();
          relay?.close();
        },
        sync: true,
      );

      return output.stream.cast<E>(); // Cast to match expected transformer return
    };
  }
}
