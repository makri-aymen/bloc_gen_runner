import 'package:bloc_gen_annotations/bloc_generator_annotations.dart';

part 'counter_bloc.g.dart';

@BlocEvents(transformer: Droppable())
sealed class CounterEvent {
  const factory CounterEvent.increment() = IncrementEvent;
  const factory CounterEvent.decrement() = DecrementEvent;
  @BlocEvent(transformer: Debounce(Duration(milliseconds: 300), transformer: Sequential()))
  const factory CounterEvent.restart() = RestartEvent;
}

@BlocStates(
  copyWith: true,
  stateWhen: true,
  buildWhen: true,
  listenWhen: true,
)
sealed class CounterState {
  @BlocState(isBuilder: true, isListener: false)
  const factory CounterState.main({required int count}) = MainState;
  @BlocState(isListener: true, isBuilder: false)
  const factory CounterState.evenNumber() = EvenNumberState;
  @BlocState(isListener: true, isBuilder: false)
  const factory CounterState.oddNumber() = OddNumberState;
}

class CounterBloc extends Bloc<CounterEvent, CounterState> with BlocTransformerMixin {
  int counter = 0;
  CounterBloc() : super(MainState(count: 0)) {
    on<IncrementEvent>((event, emit) {
      counter = counter + 1;
      emit(MainState(count: counter));
      if (counter % 2 == 0) {
        emit(EvenNumberState());
      } else {
        emit(OddNumberState());
      }
    });

    on<DecrementEvent>((event, emit) {
      counter = counter - 1;
      emit(MainState(count: counter));
      if (counter % 2 == 0) {
        emit(EvenNumberState());
      } else {
        emit(OddNumberState());
      }
    });

    on<RestartEvent>((event, emit) {
      counter = 0;
      emit(MainState(count: counter));
    });
  }
}
