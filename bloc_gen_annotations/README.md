# bloc_gen_annotations

[![pub version](https://img.shields.io/pub/v/bloc_gen_annotations.svg)](https://pub.dev/packages/bloc_gen_annotations)
[![pub points](https://img.shields.io/pub/points/bloc_gen_annotations)](https://pub.dev/packages/bloc_gen_annotations/score)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![GitHub stars](https://img.shields.io/github/stars/makri-aymen/bloc_gen_runner.svg?style=flat&logo=github&colorB=deeppink&label=stars)](https://github.com/makri-aymen/bloc_gen_runner)

Annotations for [`bloc_gen_runner`](https://pub.dev/packages/bloc_gen_runner) — a code generator that eliminates BLoC boilerplate including event classes, state classes, equality logic, `copyWith`, `stateWhen`, and event transformer wiring.

---

## Table of Contents

- [Installation](#installation)
- [Annotations](#annotations)
  - [@BlocEvents](#blocevents)
  - [@BlocEvent](#blocevent)
  - [@BlocStates](#blocstates)
  - [@BlocState](#blocstate)
- [Transformer API](#transformer-api)
  - [Simple Transformers](#simple-transformers)
  - [Rate Limiters](#rate-limiters)
  - [Nesting Rules](#nesting-rules)

---

## Installation

```yaml
# pubspec.yaml
dependencies:
  bloc_gen_annotations: ^0.0.1
```

---

## Annotations

### @BlocEvents

Place on your sealed event class. Defines class-level defaults inherited by every factory constructor unless overridden by `@BlocEvent`.

```dart
import 'package:bloc_gen_annotations/bloc_gen_annotations.dart';

@BlocEvents(transformer: Restartable())
sealed class CounterEvent {
  const factory CounterEvent.increment() = IncrementEvent;
  const factory CounterEvent.decrement() = DecrementEvent;

  @BlocEvent(transformer: Debounce(Duration(milliseconds: 300)))
  const factory CounterEvent.search({required String query}) = SearchEvent;
}
```

| Parameter     | Type           | Default | Description                                             |
|---------------|----------------|---------|---------------------------------------------------------|
| `transformer` | `Transformer?` | `null`  | Default transformer applied to all events in the class  |

---

### @BlocEvent

Place on individual factory constructors to override the class-level transformer.

```dart
@BlocEvents(transformer: Concurrent())
sealed class AuthEvent {
  const factory AuthEvent.login({
    required String email,
    required String password,
  }) = LoginEvent;

  @BlocEvent(transformer: Droppable())
  const factory AuthEvent.logout() = LogoutEvent;

  @BlocEvent(transformer: Debounce(Duration(milliseconds: 400), transformer: Restartable()))
  const factory AuthEvent.checkEmail({required String email}) = CheckEmailEvent;
}
```

| Parameter     | Type           | Default | Description                                          |
|---------------|----------------|---------|------------------------------------------------------|
| `transformer` | `Transformer?` | `null`  | Overrides class-level transformer for this event     |

**Priority chain:** `@BlocEvent` → `@BlocEvents` → `build.yaml transformer`

`concurrent()` at any level means no transformer is injected — the BLoC default applies.

---

### @BlocStates

Place on your sealed state class.

```dart
@BlocStates()
sealed class CounterState {
  const factory CounterState.initial() = InitialState;
  const factory CounterState.loaded({required int count}) = LoadedState;
  const factory CounterState.error({required String message}) = ErrorState;
}
```

| Parameter    | Type    | Default | Description                                               |
|--------------|---------|---------|-----------------------------------------------------------|
| `equatable`  | `bool?` | `null`  | Override global equatable config for this class           |
| `copyWith`   | `bool?` | `null`  | Override global copyWith config for this class            |

---

### @BlocState

Place on individual factory constructors inside the sealed state class.

```dart
@BlocStates()
sealed class AuthState {
  const factory AuthState.initial() = InitialState;

  @BlocState(copyWith: false)
  const factory AuthState.loading() = LoadingState;

  @BlocState(equatable: true, isBuilder: true, isListener: true)
  const factory AuthState.authenticated({required User user}) = AuthenticatedState;

  @BlocState(isBuilder: false, isListener: false)
  const factory AuthState.error({required String message}) = AuthErrorState;
}
```

| Parameter    | Type    | Default | Description                                                              |
|--------------|---------|---------|--------------------------------------------------------------------------|
| `equatable`  | `bool?` | `null`  | Override equatable for this state                                        |
| `copyWith`   | `bool?` | `null`  | Override copyWith generation for this state                              |
| `isBuilder`  | `bool?` | `null`  | Whether this state is included in the generated `buildWhen` function     |
| `isListener` | `bool?` | `null`  | Whether this state is included in the generated `listenWhen` function    |

**Priority chain:** `@BlocState` → `@BlocStates` → `build.yaml`

---

## Transformer API

### Simple Transformers

All extend `Transformer` and can be used at any annotation level.

| Class           | Behavior                                              |
|-----------------|-------------------------------------------------------|
| `Concurrent()`  | Processes all events simultaneously (default)         |
| `Sequential()`  | Processes one event at a time, queues the rest        |
| `Restartable()` | Cancels the current handler when a new event arrives  |
| `Droppable()`   | Ignores new events while a handler is running         |

```dart
@BlocEvent(transformer: Restartable())
const factory MyEvent.search({required String query}) = SearchEvent;
```

---

### Rate Limiters

`Debounce` and `Throttle` extend `Transformer` and accept an optional inner transformer.

```dart
// Debounce only
@BlocEvent(transformer: Debounce(Duration(milliseconds: 300)))

// Throttle only
@BlocEvent(transformer: Throttle(Duration(seconds: 1)))

// Debounce + inner transformer
@BlocEvent(transformer: Debounce(Duration(milliseconds: 300), transformer: Restartable()))

// Throttle + inner transformer
@BlocEvent(transformer: Throttle(Duration(seconds: 1), transformer: Sequential()))
```

| Parameter     | Type                 | Description                                   |
|---------------|----------------------|-----------------------------------------------|
| `duration`    | `Duration`           | Rate limit window                             |
| `transformer` | `SimpleTransformer?` | Optional inner concurrency strategy           |

---

### Nesting Rules

Nesting a rate limiter inside another rate limiter is **prevented at compile time** by the type system. The inner `transformer` slot is typed as `SimpleTransformer?` — a private abstract branch that `Debounce` and `Throttle` do not extend.

```dart
// ✅ valid
Debounce(Duration(milliseconds: 300), transformer: Restartable())

// ❌ compile error — Throttle is not a SimpleTransformer
Debounce(Duration(milliseconds: 300), transformer: Throttle(Duration(seconds: 1)))
```

The sealed class hierarchy:

```
Transformer
├── _SimpleTransformer  (private — cannot be extended or named outside the library)
│   ├── Concurrent
│   ├── Sequential
│   ├── Restartable
│   └── Droppable
└── _RateLimiter        (private — same restriction)
    ├── Debounce  (transformer: _SimpleTransformer?)
    └── Throttle  (transformer: _SimpleTransformer?)
```

The private branches are purely structural guardrails — invisible to the user, enforced by the compiler.

---

## Contributing

Contributions, bug reports, and feature suggestions are very welcome!

- **Found a bug?** [Open an issue](https://github.com/makri-aymen/bloc_gen_runner/issues)
- **Have an idea?** [Start a discussion](https://github.com/makri-aymen/bloc_gen_runner/issues)
- **Want to contribute code?** PRs are welcome; please open an issue first

---

## License

MIT — see [LICENSE](LICENSE)

## Maintainers

- [Makri Aymen Abderraouf](https://github.com/makri-aymen)