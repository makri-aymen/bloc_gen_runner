class BlocStates {
  final bool? copyWith;
  final bool? stateWhen;
  final bool? buildWhen;
  final bool? listenWhen;
  final bool? equatable;

  const BlocStates({
    this.copyWith,
    this.stateWhen,
    this.buildWhen,
    this.listenWhen,
    this.equatable,
  });
}

class BlocState {
  final bool? equatable; // null = inherit from BlocEvents
  final bool? copyWith; // null = inherit from BlocEvents
  final bool? isBuilder;
  final bool? isListener;

  const BlocState({
    this.equatable,
    this.copyWith,
    this.isBuilder,
    this.isListener,
  });
}
