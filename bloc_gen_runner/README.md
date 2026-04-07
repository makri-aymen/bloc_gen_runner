# bloc_gen_runner

[![pub version](https://img.shields.io/pub/v/bloc_gen_annotations.svg)](https://pub.dev/packages/bloc_gen_annotations)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![GitHub stars](https://img.shields.io/github/stars/makri-aymen/bloc_gen_runner.svg?style=flat&logo=github&colorB=deeppink&label=stars)](https://github.com/makri-aymen/bloc_gen_runner)

A `build_runner` code generator for the [BLoC](https://pub.dev/packages/bloc) state management library. Generates event classes, state classes, equality logic, `copyWith`, and event transformer wiring — all from a single sealed class declaration.

---

## Table of Contents

- [Installation](#installation)
- [Configuration](#configuration)
- [Quick Start](#quick-start)
- [Generated Output](#generated-output)
- [Transformer Wiring](#transformer-wiring)
- [BlocTransformerMixin](#bloctransformermixin)
- [State Generation](#state-generation)
- [Config Reference](#config-reference)
- [Contributing](#contributing)

---

## Installation

```yaml
# pubspec.yaml
dependencies:
  bloc: ^9.0.0
  bloc_gen_annotations: ^0.0.1

dev_dependencies:
  bloc_gen_runner: ^0.0.1
  build_runner: ^2.4.0
```

---

## Configuration

Create a `build.yaml` at the root of your project:

```yaml
targets:
  $default:
    builders:
      bloc_gen_runner:
        options:
          # Concurrency strategy applied when no transformer annotation is set.
          # concurrent() sequential() droppable() restartable()
          # debounce(milliseconds: 300)
          # debounce(milliseconds: 300, andThen: restartable())
          # throttle(seconds: 1, andThen: sequential())
          transformer: 'concurrent()'

          # Suffix generated event classes with 'Event'
          # e.g. LoginEvent instead of Login
          with_event_suffix: true

          # Suffix generated state classes with 'State'
          # e.g. LoadedState instead of Loaded
          with_state_suffix: true

          # Generate copyWith on state classes
          copy_with: true

          # Generate stateWhen on state sealed class
          state_when: true

          # Generate buildWhen — requires isBuilder: true
          build_when: true

          # Generate listenWhen — requires isListener: true
          listen_when: true

          # Extend Equatable on generated classes
          equatable: true

          # If true, this state is included in the buildWhen function
          isBuilder: true

          # If true, this state is included in the listenWhen function
          isListener: false
```

---

## Quick Start

**1. Declare your events:**

```dart
// counter_event.dart
import 'package:bloc_gen_annotations/bloc_gen_annotations.dart';

part 'counter_event.g.dart';

@BlocEvents(transformer: Restartable())
sealed class CounterEvent {
  const factory CounterEvent.increment() = IncrementEvent;
  const factory CounterEvent.decrement() = DecrementEvent;

  @BlocEvent(transformer: Debounce(Duration(milliseconds: 300)))
  const factory CounterEvent.search({required String query}) = SearchEvent;
}
```

**2. Declare your states:**

```dart
// counter_state.dart
import 'package:bloc_gen_annotations/bloc_gen_annotations.dart';

part 'counter_state.g.dart';

@BlocStates()
sealed class CounterState {
  const factory CounterState.initial() = InitialState;
  const factory CounterState.loaded({required int count}) = LoadedState;
  const factory CounterState.error({required String message}) = ErrorState;
}
```

**3. Run the generator:**

```bash
dart run build_runner build --delete-conflicting-outputs
# or watch mode
dart run build_runner watch --delete-conflicting-outputs
```

**4. Write your BLoC:**

```dart
// counter_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:bloc_gen_annotations/bloc_gen_annotations.dart';

class CounterBloc extends Bloc<CounterEvent, CounterState>
    with BlocTransformerMixin {
  CounterBloc() : super(const CounterInitialState()) {
    // No transformer: parameter needed — BlocTransformerMixin wires it automatically
    on<IncrementEvent>(_onIncrement);
    on<DecrementEvent>(_onDecrement);
    on<SearchEvent>(_onSearch);
  }

  void _onIncrement(IncrementEvent event, Emitter<CounterState> emit) { ... }
  void _onDecrement(DecrementEvent event, Emitter<CounterState> emit) { ... }
  void _onSearch(SearchEvent event, Emitter<CounterState> emit) { ... }
}
```

> ⚠️ **Passing `transformer:` manually to `on<E>()`** will no work when BlocTransformerMixin is used.

---

## Generated Output

For the events above, the generator produces:

```dart
// counter_event.g.dart

class IncrementEvent implements CounterEvent {
  const IncrementEvent();
}

class DecrementEvent implements CounterEvent {
  const DecrementEvent();
}

// SearchEvent extends EventGenerated because it carries a transformer
class SearchEvent extends EventGenerated implements CounterEvent {
  final String query;
  const SearchEvent({required this.query});

  @override
  EventTransformer? get transformer =>
      debounce(Duration(milliseconds: 300), andThen: restartable());
}
```

For the states:

```dart
// counter_state.g.dart

class CounterInitialState extends Equatable implements CounterState {
  const CounterInitialState();

  @override
  List<Object?> get props => [];
}

class CounterLoadedState extends Equatable implements CounterState {
  final int count;
  const CounterLoadedState({required this.count});

  CounterLoadedState copyWith({int? count}) =>
      CounterLoadedState(count: count ?? this.count);

  @override
  List<Object?> get props => [count];
}

class CounterErrorState extends Equatable implements CounterState {
  final String message;
  const CounterErrorState({required this.message});

  CounterErrorState copyWith({String? message}) =>
      CounterErrorState(message: message ?? this.message);

  @override
  List<Object?> get props => [message];
}
```

---

## Transformer Wiring

Transformers are resolved at three levels, each overriding the next:

```
@BlocEvent(transformer: ...)        ← highest priority
    ↓ falls back to
@BlocEvents(transformer: ...)
    ↓ falls back to
build.yaml transformer              ← lowest priority
```

`concurrent()` at any level means no transformer is injected — the BLoC default applies.

> ⚠️ **Passing `transformer:` manually to `on<E>()`** will no work when BlocTransformerMixin is used.

### Supported transformer strings in `build.yaml`

```yaml
transformer: 'concurrent()'
transformer: 'sequential()'
transformer: 'restartable()'
transformer: 'droppable()'
transformer: 'debounce(milliseconds: 300)'
transformer: 'debounce(seconds: 1, andThen: restartable())'
transformer: 'throttle(milliseconds: 500, andThen: sequential())'
```

---

## BlocTransformerMixin

The mixin intercepts `on<E>()` calls and lazily resolves the transformer from the first event instance. Events without a transformer annotation are unaffected and fall back to `concurrent()`.

```dart
class CounterBloc extends Bloc<CounterEvent, CounterState>
    with BlocTransformerMixin {
  CounterBloc() : super(const CounterInitialState()) {
    // transformer is wired automatically from the annotation — no transformer: needed
    on<IncrementEvent>(_onIncrement);
    on<DecrementEvent>(_onDecrement);
    on<SearchEvent>(_onSearch);
  }
}
```

**How the lazy gate works:**

1. `on<E>()` is called at construction time — no event instance exists yet
2. The mixin wraps the event stream in a gate that buffers incoming events
3. On the first event, `event.transformer` is read and the real pipeline is built
4. All buffered events are replayed through the resolved pipeline
5. Every subsequent event flows directly — no overhead after the first

Events without a transformer (`concurrent()` or unannotated) skip the gate entirely.

---

## State Generation

### copyWith

Generated on all state classes with fields when `copy_with: true`:

```dart
final next = state.copyWith(count: state.count + 1);
```

### stateWhen / buildWhen / listenWhen

All three are generated as extension methods on the state sealed class.

- **`stateWhen`** — covers all states, all handlers optional, requires an `orElse` fallback
- **`buildWhen`** — covers only states with `isBuilder: true`, all handlers **required** — forces you to handle every builder state explicitly, returns `null` on non-builder states
- **`listenWhen`** — covers only states with `isListener: true`, all handlers **required** — same forced exhaustiveness, returns `null` on non-listener states
- **`isBuilder` / `isListener`** — bool getters indicating whether the current state belongs to `buildWhen` / `listenWhen`

```dart
// Generated output
extension CounterStateExtension on CounterState {
  bool get isBuilder =>
      this is LoadedState ||
      this is ErrorState;

  bool get isListener =>
      this is ErrorState;

  T stateWhen<T>({
    required T Function() orElse,
    T Function()? initial,
    T Function(int count)? loaded,
    T Function(String message)? error,
  }) => switch (this) {
    InitialState _ when initial != null => initial(),
    LoadedState s when loaded != null   => loaded(s.count),
    ErrorState s when error != null     => error(s.message),
    _ => orElse(),
  };

  // All handlers required — exhaustive over isBuilder states
  T? buildWhen<T>({
    required T Function(int count) loaded,
    required T Function(String message) error,
  }) => switch (this) {
    LoadedState s => loaded(s.count),
    ErrorState s  => error(s.message),
    _ => null,
  };

  // All handlers required — exhaustive over isListener states
  T? listenWhen<T>({
    required T Function(String message) error,
  }) => switch (this) {
    ErrorState s => error(s.message),
    _ => null,
  };
}
```

```dart
// Usage in widget
BlocBuilder<CounterBloc, CounterState>(
  buildWhen: (_, current) => current.isBuilder,
  builder: (context, state) {
    return state.buildWhen(
      loaded: (count) => Text('$count'),    // required
      error: (message) => Text(message),    // required
    ) ?? const SizedBox();
  },
)

BlocListener<CounterBloc, CounterState>(
  listenWhen: (_, current) => current.isListener,
  listener: (context, state) {
    state.listenWhen(
      error: (message) => showSnackBar(context, message), // required
    );
  },
)
```

---

## Config Reference

| Option              | Type     | Default          | Description                                         |
|---------------------|----------|------------------|-----------------------------------------------------|
| `transformer`       | `String` | `'concurrent()'` | Fallback transformer for unannotated events         |
| `with_event_suffix` | `bool`   | `true`           | Suffix event class names with `Event`               |
| `with_state_suffix` | `bool`   | `true`           | Suffix state class names with `State`               |
| `copy_with`         | `bool`   | `true`           | Generate `copyWith` on state classes                |
| `state_when`        | `bool`   | `true`           | Generate `stateWhen` on the state sealed class      |
| `build_when`        | `bool`   | `true`           | Generate `buildWhen` — requires `isBuilder: true`   |
| `listen_when`       | `bool`   | `true`           | Generate `listenWhen` — requires `isListener: true` |
| `equatable`         | `bool`   | `true`           | Extend `Equatable` on generated classes             |
| `isBuilder`         | `bool`   | `true`           | Include this state in the generated `buildWhen`    |
| `isListener`        | `bool`   | `false`          | Include this state in the generated `listenWhen`   |

Options can be overridden per-annotation:

```dart
// equatable is true globally but this state class opts out
@BlocStates(equatable: false)
sealed class LargeState { ... }

// this state forces it on regardless of global config
@BlocState(equatable: true)
const factory LargeState.withData({required List<Item> items}) = WithDataState;
```

Priority: `@BlocState` → `@BlocStates` → `build.yaml`

---

## Contributing

Contributions, bug reports, and feature suggestions are very welcome! This package is still evolving and your feedback directly shapes its direction.

- **Found a bug?** [Open an issue](https://github.com/makri-aymen/bloc_gen_runner/issues) with a minimal reproduction case
- **Have an idea?** [Start a discussion](https://github.com/makri-aymen/bloc_gen_runner/issues) — no idea is too small
- **Want to contribute code?** PRs are welcome; please open an issue first so we can align on the approach
- **Using this in a real project?** Let us know — real-world feedback is invaluable

If something feels off, unclear, or missing in the generated output, don't hesitate to [open an issue](https://github.com/makri-aymen/bloc_gen_runner/issues). The goal is to make BLoC boilerplate completely invisible so you can focus entirely on business logic.

---

## License

MIT — see [LICENSE](LICENSE)

## Maintainers

- [Makri Aymen Abderraouf](https://github.com/makri-aymen)