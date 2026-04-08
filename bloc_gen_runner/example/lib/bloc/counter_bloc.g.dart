// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'counter_bloc.dart';

class IncrementEvent extends EventGenerated implements CounterEvent {
  const IncrementEvent();

  @override
  EventTransformer? get transformer => droppable();
}

class DecrementEvent extends EventGenerated implements CounterEvent {
  const DecrementEvent();

  @override
  EventTransformer? get transformer => droppable();
}

class RestartEvent extends EventGenerated implements CounterEvent {
  const RestartEvent();

  @override
  EventTransformer? get transformer => debounce(Duration(milliseconds: 300));
}

class MainState extends Equatable implements CounterState {
  const MainState({required this.count});

  final int count;

  MainState copyWith({int? count}) => MainState(count: count ?? this.count);

  @override
  List<Object?> get props => [count];

  @override
  bool get stringify => true;
}

class EvenNumberState extends Equatable implements CounterState {
  const EvenNumberState();

  @override
  List<Object?> get props => [];

  @override
  bool get stringify => true;
}

class OddNumberState extends Equatable implements CounterState {
  const OddNumberState();

  @override
  List<Object?> get props => [];

  @override
  bool get stringify => true;
}

extension CounterStateExtension on CounterState {
  bool get isBuilder => this is MainState;

  bool get isListener => this is EvenNumberState || this is OddNumberState;

  T stateWhen<T>({
    required T Function() orElse,
    T Function(int count)? main,
    T Function()? evenNumber,
    T Function()? oddNumber,
  }) => switch (this) {
    MainState mainS when main != null => main(mainS.count),
    EvenNumberState _ when evenNumber != null => evenNumber(),
    OddNumberState _ when oddNumber != null => oddNumber(),
    _ => orElse(),
  };

  T buildWhen<T>({
    required T Function() orElse,
    required T Function(int count) main,
  }) => switch (this) {
    MainState mainS => main(mainS.count),
    _ => orElse(),
  };

  T? listenWhen<T>({
    required T Function() evenNumber,
    required T Function() oddNumber,
  }) => switch (this) {
    EvenNumberState _ => evenNumber(),
    OddNumberState _ => oddNumber(),
    _ => null,
  };
}
