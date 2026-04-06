import 'package:build/build.dart';

class BlocGeneratorConfig {
  final String defaultTransformer;
  final bool withEventPrefix;
  final bool withStatePrefix;
  final bool copyWith;
  final bool stateWhen;
  final bool buildWhen;
  final bool listenWhen;
  final bool equatable;
  final bool isBuilder;
  final bool isListener;

  const BlocGeneratorConfig({
    this.defaultTransformer = 'concurrent()',
    this.withEventPrefix = true,
    this.withStatePrefix = true,
    this.copyWith = true,
    this.stateWhen = true,
    this.buildWhen = true,
    this.listenWhen = true,
    this.equatable = true,
    this.isBuilder = true,
    this.isListener = false,
  });

  factory BlocGeneratorConfig.fromOptions(BuilderOptions options) {
    final c = options.config;
    return BlocGeneratorConfig(
      defaultTransformer: _parseTransformerExpr(
        options.config['transformer'] as String? ?? 'concurrent()',
      ),
      withEventPrefix: c['with_event_prefix'] as bool? ?? true,
      withStatePrefix: c['with_state_prefix'] as bool? ?? true,
      copyWith: c['copy_with'] as bool? ?? true,
      stateWhen: c['state_when'] as bool? ?? true,
      buildWhen: c['build_when'] as bool? ?? true,
      listenWhen: c['listen_when'] as bool? ?? true,
      equatable: c['equatable'] as bool? ?? true,
      isBuilder: c['is_builder'] as bool? ?? true,
      isListener: c['is_listener'] as bool? ?? false,
    );
  }

  static String _parseTransformerExpr(String value) {
    final trimmed = value.trim();

    // Simple transformers
    switch (trimmed) {
      case 'concurrent()':
        return "concurrent()";
      case 'sequential()':
        return 'sequential()';
      case 'restartable()':
        return 'restartable()';
      case 'droppable()':
        return 'droppable()';
    }

    // Rate limiters
    final rateMatch = RegExp(
      r'^(debounce|throttle)\(\s*'
      r'(milliseconds|seconds|microseconds)\s*:\s*(\d+)'
      r'(?:\s*,\s*andThen\s*:\s*(concurrent|sequential|restartable|droppable)\(\))?\s*\)$',
    ).firstMatch(trimmed);

    if (rateMatch != null) {
      final fn = rateMatch.group(1)!;
      final unit = rateMatch.group(2)!;
      final amount = rateMatch.group(3)!;
      final andThen = rateMatch.group(4);

      final duration = 'Duration($unit: $amount)';
      final inner = _resolveInnerExpr(andThen);
      final suffix = inner != null ? ', andThen: $inner' : '';

      return '$fn($duration$suffix)';
    }

    return "concurrent()";
  }

  static String? _resolveInnerExpr(String? name) => switch (name) {
    'sequential' => 'sequential()',
    'restartable' => 'restartable()',
    'droppable' => 'droppable()',
    'concurrent' => 'concurrent()',
    _ => null,
  };
}
