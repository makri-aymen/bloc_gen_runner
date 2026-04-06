// ── Base ──────────────────────────────────────────────────────────────────────

sealed class Transformer {
  const Transformer();
}

// ── Private Branches (structural, not for users) ──────────────────────────────

sealed class SimpleTransformer extends Transformer {
  const SimpleTransformer();
}

sealed class RateLimiter extends Transformer {
  final Duration duration;
  final SimpleTransformer? transformer;
  const RateLimiter(this.duration, {this.transformer});
}

// ── Public Leaf Classes ───────────────────────────────────────────────────────

class Concurrent extends SimpleTransformer {
  const Concurrent();
}

class Sequential extends SimpleTransformer {
  const Sequential();
}

class Restartable extends SimpleTransformer {
  const Restartable();
}

class Droppable extends SimpleTransformer {
  const Droppable();
}

class Debounce extends RateLimiter {
  // ignore: library_private_types_in_public_api
  const Debounce(super.duration, {super.transformer});
}

class Throttle extends RateLimiter {
  // ignore: library_private_types_in_public_api
  const Throttle(super.duration, {super.transformer});
}

// ── Annotations ───────────────────────────────────────────────────────────────

class BlocEvents {
  final Transformer? transformer;

  const BlocEvents({
    this.transformer,
  });
}

class BlocEvent {
  final Transformer? transformer;
  const BlocEvent({this.transformer});
}
