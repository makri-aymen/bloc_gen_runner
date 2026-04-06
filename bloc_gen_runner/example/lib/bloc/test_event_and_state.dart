
import 'package:bloc_gen_annotations/bloc_generator_annotations.dart';

part 'test_event_and_state.g.dart';

@BlocEvents()
sealed class TestEvent {
  // @BlocEvent(transformer: Debounce(Duration(milliseconds: 400)))
  const factory TestEvent.initialize({required int userId}) = InitializeEvent;
  // @BlocEvent(transformer: Sequential())
  const factory TestEvent.reload(int? count) = ReloadEvent;
}

@BlocStates(
  copyWith: true,
  stateWhen: true,
  buildWhen: true,
  listenWhen: true,
)
sealed class TestState {
  @BlocState(isBuilder: true, copyWith: true)
  const factory TestState.main({required List<String> names, required DateTime birthDay, List<int>? ages}) = MainState;
  @BlocState(isBuilder: true)
  const factory TestState.loading() = LoadingState;
  @BlocState(isListener: true)
  const factory TestState.error({required Exception exception}) = ErrorState;
  @BlocState(isListener: true, isBuilder: true)
  const factory TestState.empty() = EmptyState;
}
