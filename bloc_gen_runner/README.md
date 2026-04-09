
<div align="center">


<h1>bloc_gen_runner</h1>

<br>

[![pub version](https://img.shields.io/pub/v/bloc_gen_runner.svg)](https://pub.dev/packages/bloc_gen_runner)
[![pub points](https://img.shields.io/pub/points/bloc_gen_runner)](https://pub.dev/packages/bloc_gen_runner/score)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![GitHub stars](https://img.shields.io/github/stars/makri-aymen/bloc_gen_runner.svg?style=flat&logo=github&colorB=deeppink&label=stars)](https://github.com/makri-aymen/bloc_gen_runner)
[![Tests](https://github.com/makri-aymen/bloc_gen_runner/actions/workflows/tests.yml/badge.svg?branch=main)](https://github.com/makri-aymen/bloc_gen_runner/actions/workflows/tests.yml)
[![build](https://img.shields.io/github/actions/workflow/status/makri-aymen/bloc_gen_runner/main.yaml?branch=main&logo=github&label=build)](https://github.com/makri-aymen/bloc_gen_runner/actions/workflows/main.yaml)
[![codecov](https://img.shields.io/codecov/c/github/makri-aymen/bloc_gen_runner?logo=codecov&label=codecov)](https://codecov.io/gh/makri-aymen/bloc_gen_runner)
[![Support me on Ko-fi](https://img.shields.io/badge/Support%20me%20on%20Ko--fi-%23FFDD00.svg?style=flat&logo=ko-fi&logoColor=black)](https://ko-fi.com/aymenmak)

<br>

<p align="center">⭐ Please star this repository to support the project! ⭐</p>

<br>

A `build_runner` code generator for the [BLoC](https://pub.dev/packages/bloc) state management library. Generates event classes, state classes, equality logic, `copyWith`, and event transformer wiring — all from a single sealed class declaration.

<br>
</div>

## Table of Contents

- [Installation](#installation)
- [Global Configuration (Optional)](#configuration)
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

## Global Configuration (Optional)

Create a `build.yaml` at the root of your project, and edit the global config of the generator

```yaml
targets:
  $default:
    builders:
      bloc_gen_runner:
        options:
          # Transformer that will be applied globaly on every event
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
          is_builder: true

          # If true, this state is included in the listenWhen function
          is_listener: false
```

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

## Quick Start

**1. Declare your events and states:**

```dart
import 'package:bloc_gen_annotations/bloc_gen_annotations.dart';

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
```

**3. Run the generator:**

```bash
dart run build_runner build --delete-conflicting-outputs
# or watch mode
dart run build_runner watch --delete-conflicting-outputs
```

**4. Write your BLoC:**

```dart
// counter_bloc.dart (continued)
class CounterBloc extends Bloc<CounterEvent, CounterState>
    with BlocTransformerMixin {
  CounterBloc() : super(const MainState(count: 0)) {
    // No transformer: parameter needed — BlocTransformerMixin wires it automatically
    on<IncrementEvent>(_onIncrement);
    on<DecrementEvent>(_onDecrement);
    on<RestartEvent>(_onRestart);
  }

  void _onIncrement(IncrementEvent event, Emitter<CounterState> emit) {
    final current = state;
    if (current is! MainState) return;
    final next = current.count + 1;
    emit(MainState(count: next));
    emit(next.isEven ? const EvenNumberState() : const OddNumberState());
    emit(MainState(count: next));
  }

  void _onDecrement(DecrementEvent event, Emitter<CounterState> emit) {
    final current = state;
    if (current is! MainState) return;
    final next = current.count - 1;
    emit(MainState(count: next));
    emit(next.isEven ? const EvenNumberState() : const OddNumberState());
    emit(MainState(count: next));
  }

  void _onRestart(RestartEvent event, Emitter<CounterState> emit) {
    emit(const MainState(count: 0));
  }
}
```

> ⚠️ **Passing `transformer:` manually to `on<E>()`** will no work when BlocTransformerMixin is used.

---

## Generated Output

For the events above, the generator produces:

```dart
// counter_bloc.g.dart

// ─── Events ───────────────────────────────────────────────────────────────────

// Inherits Droppable() from @BlocEvents
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

// Overrides with its own @BlocEvent transformer
class RestartEvent extends EventGenerated implements CounterEvent {
  const RestartEvent();

  @override
  EventTransformer? get transformer =>
      debounce(Duration(milliseconds: 300), andThen: sequential());
}

// ─── States ───────────────────────────────────────────────────────────────────

class MainState extends Equatable implements CounterState {
  const MainState({required this.count});

  final int count;

  MainState copyWith({int? count}) =>
      MainState(count: count ?? this.count);

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

// ─── Extension ────────────────────────────────────────────────────────────────

extension CounterStateExtension on CounterState {
  // true only for states annotated with isBuilder: true
  bool get isBuilder => this is MainState;

  // true only for states annotated with isListener: true
  bool get isListener => this is EvenNumberState || this is OddNumberState;

  T stateWhen<T>({
    required T Function() orElse,
    T Function(int count)? main,
    T Function()? evenNumber,
    T Function()? oddNumber,
  }) => switch (this) {
    MainState mainS when main != null     => main(mainS.count),
    EvenNumberState _ when evenNumber != null => evenNumber(),
    OddNumberState _ when oddNumber != null   => oddNumber(),
    _ => orElse(),
  };

  // All handlers required — exhaustive over isBuilder states
  T buildWhen<T>({
    required T Function() orElse,
    required T Function(int count) main,
  }) => switch (this) {
    MainState mainS => main(mainS.count),
    _ => orElse(),
  };

  // All handlers required — exhaustive over isListener states
  T? listenWhen<T>({
    required T Function() evenNumber,
    required T Function() oddNumber,
  }) => switch (this) {
    EvenNumberState _ => evenNumber(),
    OddNumberState _ => oddNumber(),
    _ => null,
  };
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
- **`buildWhen`** — covers only states with `isBuilder: true`, all handlers **required** — forces you to handle every builder state explicitly, returns the orElse value on non-builder states
- **`listenWhen`** — covers only states with `isListener: true`, all handlers **required** — same forced exhaustiveness, returns `null` on non-listener states
- **`isBuilder` / `isListener`** — bool getters indicating whether the current state belongs to `buildWhen` / `listenWhen`

```dart
// In a BlocConsumer
buildWhen: (previous, current) => current.isBuilder,
builder: (context, state) => state.buildWhen(
  main: (count) => Text('$count'),  // required — compiler enforced
  orElse: () => const SizedBox(),
),

listenWhen: (previous, current) => current.isListener,
listener: (context, state) => state.listenWhen(
  evenNumber: () => showSnackBar(context, 'Even number'),  // required
  oddNumber:  () => showSnackBar(context, 'Odd number'),   // required
),
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
| `is_builder`         | `bool`   | `true`           | Include this state in the generated `buildWhen`    |
| `is_listener`        | `bool`   | `false`          | Include this state in the generated `listenWhen`   |

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