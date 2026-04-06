import 'package:bloc_gen_annotations/bloc_generator_annotations.dart';
import 'package:example/bloc/test_event_and_state.dart';

class TestBloc extends Bloc<TestEvent, TestState> with BlocTransformerMixin {
  TestBloc() : super(LoadingState()) {
    on<InitializeEvent>(
      (event, emit) {
        print("Initialize is called");
      },
    );

    on<ReloadEvent>((event, emit) {});
  }
}
