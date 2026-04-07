// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_event_and_state.dart';

class InitializeEvent extends EventGenerated implements TestEvent {
  const InitializeEvent({required this.userId});

  final int userId;

  @override
  EventTransformer? get transformer => debounce(Duration(milliseconds: 700));
}

class ReloadEvent extends EventGenerated implements TestEvent {
  const ReloadEvent(this.count);

  final int? count;

  @override
  EventTransformer? get transformer => debounce(Duration(milliseconds: 700));
}

class MainState extends Equatable implements TestState {
  const MainState({required this.names, required this.birthDay, this.ages});

  final List<String> names;

  final DateTime birthDay;

  final List<int>? ages;

  MainState copyWith({
    List<String>? names,
    DateTime? birthDay,
    List<int>? ages,
  }) => MainState(
    names: names ?? this.names,
    birthDay: birthDay ?? this.birthDay,
    ages: ages ?? this.ages,
  );

  @override
  List<Object?> get props => [names, birthDay, ages];

  @override
  bool get stringify => true;
}

class LoadingState extends Equatable implements TestState {
  const LoadingState();

  @override
  List<Object?> get props => [];

  @override
  bool get stringify => true;
}

class ErrorState extends Equatable implements TestState {
  const ErrorState({required this.exception});

  final Exception exception;

  ErrorState copyWith({Exception? exception}) =>
      ErrorState(exception: exception ?? this.exception);

  @override
  List<Object?> get props => [exception];

  @override
  bool get stringify => true;
}

class EmptyState extends Equatable implements TestState {
  const EmptyState();

  @override
  List<Object?> get props => [];

  @override
  bool get stringify => true;
}

extension TestStateExtension on TestState {
  bool get isBuilder =>
      this is MainState || this is LoadingState || this is EmptyState;

  bool get isListener =>
      this is MainState ||
      this is LoadingState ||
      this is ErrorState ||
      this is EmptyState;

  T stateWhen<T>({
    required T Function() orElse,
    T Function(List<String> names, DateTime birthDay, List<int>? ages)? main,
    T Function()? loading,
    T Function(Exception exception)? error,
    T Function()? empty,
  }) => switch (this) {
    MainState mainS when main != null => main(
      mainS.names,
      mainS.birthDay,
      mainS.ages,
    ),
    LoadingState _ when loading != null => loading(),
    ErrorState errorS when error != null => error(errorS.exception),
    EmptyState _ when empty != null => empty(),
    _ => orElse(),
  };

  T? buildWhen<T>({
    required T Function(List<String> names, DateTime birthDay, List<int>? ages)
    main,
    required T Function() loading,
    required T Function() empty,
  }) => switch (this) {
    MainState mainS => main(mainS.names, mainS.birthDay, mainS.ages),
    LoadingState _ => loading(),
    EmptyState _ => empty(),
    _ => null,
  };

  T? listenWhen<T>({
    required T Function(List<String> names, DateTime birthDay, List<int>? ages)
    main,
    required T Function() loading,
    required T Function(Exception exception) error,
    required T Function() empty,
  }) => switch (this) {
    MainState mainS => main(mainS.names, mainS.birthDay, mainS.ages),
    LoadingState _ => loading(),
    ErrorState errorS => error(errorS.exception),
    EmptyState _ => empty(),
  };
}
