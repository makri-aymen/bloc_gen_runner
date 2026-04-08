import 'package:analyzer/dart/element/element.dart';
import 'package:bloc_gen_annotations/state.dart';
import 'package:bloc_gen_runner/src/bloc_generator_config.dart';
import 'package:bloc_gen_runner/src/states_visitor.dart';
import 'package:build/build.dart';
import 'package:built_collection/built_collection.dart';
import 'package:code_builder/code_builder.dart';
import 'package:source_gen/source_gen.dart';

class BlocStatesGenerator extends GeneratorForAnnotation<BlocStates> {
  final BlocGeneratorConfig blocGeneratorConfig;

  BlocStatesGenerator(this.blocGeneratorConfig);

  @override
  String generateForAnnotatedElement(Element element, ConstantReader annotation, BuildStep buildStep) {
    final visitor = StatesVisitor();
    if (element is! ClassElement) return "";
    visitor.visitClassElement(element);
    for (final constractor in element.constructors) {
      visitor.visitConstructorElement(constractor);
    }

    List<Spec> specs = [];

    // ── State Classes ────────────────────────────────────
    specs.addAll(_buildStateClasses(visitor));

    // ── Method stateWhen, buildWhen, listenWhen ────────────────────────────────────
    specs.add(_buildExtension(visitor));

    return _emit(specs);
  }

  // ── State Classes ────────────────────────────────────────────────────────

  List<Class> _buildStateClasses(StatesVisitor visitor) {
    return visitor.factories.map((constructor) {
      final prefix = blocGeneratorConfig.withStatePrefix ? "State" : "";
      final className = constructor.name![0].toUpperCase() + constructor.name!.substring(1) + prefix;
      final hasParams = constructor.formalParameters.isNotEmpty;
      bool? equatableChild = _getBlocStateFlag(constructor, 'equatable');
      final enabled = equatableChild ?? visitor.equatable ?? blocGeneratorConfig.equatable;
      return Class(
        (c) => c
          ..name = className
          ..extend = enabled ? refer('Equatable') : null
          ..implements = ListBuilder<Reference>([Reference(visitor.className)])
          ..fields = ListBuilder<Field>(
            constructor.formalParameters
                .map(
                  (param) => Field(
                    (f) => f
                      ..name = param.name
                      ..modifier = FieldModifier.final$
                      ..type = refer(
                        param.type.getDisplayString(),
                      ),
                  ),
                )
                .toList(),
          )
          ..constructors = ListBuilder<Constructor>(
            [
              Constructor(
                (co) => co
                  ..constant = true
                  ..optionalParameters = ListBuilder<Parameter>(
                    constructor.formalParameters
                        .where((item) => item.isNamed)
                        .map(
                          (p) => Parameter(
                            (p0) => p0
                              ..required = p.isRequired
                              ..named = p.isNamed
                              ..name = p.name!
                              ..toThis = true,
                          ),
                        ),
                  )
                  ..requiredParameters = ListBuilder<Parameter>(
                    constructor.formalParameters
                        .where((item) => item.isRequired && !item.isNamed)
                        .map(
                          (p) => Parameter(
                            (p0) => p0
                              ..name = p.name!
                              ..toThis = true,
                          ),
                        ),
                  ),
              ),
            ],
          )
          ..methods = ListBuilder<Method>([
            ?_copyWithMethod(constructor, visitor.copyWith, blocGeneratorConfig.copyWith, hasParams),
            ?_equatableProps(constructor, visitor.equatable, blocGeneratorConfig.equatable, hasParams),
            ?_equatableStringify(constructor, visitor.equatable, blocGeneratorConfig.equatable, hasParams),
          ]),
      );
    }).toList();
  }

  // ── equatable Methods ───────────────────────────────────────────────────────────

  Method? _equatableStringify(ConstructorElement constructor, bool? equatableParent, bool equatableGlobal, bool hasParams) {
    bool? equatable = _getBlocStateFlag(constructor, 'equatable');
    final enabled = equatable ?? equatableParent ?? equatableGlobal;
    if (!enabled) return null;

    return Method(
      (m) => m
        ..name = 'stringify'
        ..annotations = ListBuilder([refer('override')])
        ..returns = refer('bool')
        ..type = MethodType.getter
        ..lambda = true
        ..body = Code('true'),
    );
  }

  Method? _equatableProps(ConstructorElement constructor, bool? equatableParent, bool equatableGlobal, bool hasParams) {
    final params = constructor.formalParameters;
    final propsList = params.map((p) => p.name!).join(', ');

    bool? equatable = _getBlocStateFlag(constructor, 'equatable');
    final enabled = equatable ?? equatableParent ?? equatableGlobal;
    if (!enabled) return null;

    return Method(
      (m) => m
        ..name = 'props'
        ..annotations = ListBuilder([refer('override')])
        ..returns = refer('List<Object?>')
        ..type = MethodType.getter
        ..lambda = true
        ..body = Code('[$propsList]'),
    );
  }

  // ── copyWith Method ───────────────────────────────────────────────────────────

  Method? _copyWithMethod(ConstructorElement constructor, bool? copyWithParent, bool copyWithGlobal, bool hasParams) {
    if (hasParams == false) return null;
    final prefix = blocGeneratorConfig.withStatePrefix ? "State" : "";
    final className = constructor.name![0].toUpperCase() + constructor.name!.substring(1) + prefix;
    final params = constructor.formalParameters;

    bool? copyWith = _getBlocStateFlag(constructor, 'copyWith');
    final enabled = copyWith ?? copyWithParent ?? copyWithGlobal;
    if (!enabled) return null;

    // Parameters: all become optional+named with nullable type
    final methodParams = params.map((p) {
      final baseType = p.type.getDisplayString();
      // Make it nullable if not already (for copyWith signature)
      final nullableType = baseType.endsWith('?') ? baseType : '$baseType?';

      return Parameter(
        (p0) => p0
          ..name = p.name!
          ..named = true
          ..type = refer(nullableType),
      );
    }).toList();

    // Body: ClassName(param: param ?? this.param, ...)
    final args = params
        .map((p) {
          final name = p.name!;
          if (p.isNamed) {
            return '$name: $name ?? this.$name';
          } else {
            return '$name ?? this.$name';
          }
        })
        .join(', ');

    return Method(
      (m) => m
        ..name = 'copyWith'
        ..returns = refer(className)
        ..lambda = true
        ..optionalParameters = ListBuilder<Parameter>(methodParams)
        ..body = Code('$className($args,)'),
    );
  }

  // ── Extension builder ────────────────────────────────────────────────────────

  bool? _getBlocStateFlag(ConstructorElement constructor, String field) {
    final ElementAnnotation? blocStateAnnotation = constructor.metadata.annotations.where((item) => item.element?.displayName == 'BlocState').firstOrNull;
    if (blocStateAnnotation == null) return null;
    final reader = ConstantReader(blocStateAnnotation.computeConstantValue());
    final value = reader.read(field);
    return value.isNull ? null : value.boolValue;
  }

  // ── Extension builder ────────────────────────────────────────────────────────

  Set<String> _stateNames(List<ConstructorElement> list) => list.map((s) => s.name!).toSet();

  Extension _buildExtension(StatesVisitor visitor) {
    final states = visitor.factories;
    final className = visitor.className;
    final prefix = blocGeneratorConfig.withStatePrefix ? "State" : "";

    // Filter states based on annotation flags
    final builderStates = states.where((s) => _getBlocStateFlag(s, 'isBuilder') ?? blocGeneratorConfig.isBuilder).toList();
    final listenerStates = states.where((s) => _getBlocStateFlag(s, 'isListener') ?? blocGeneratorConfig.isListener).toList();

    final exhaustiveBuilderStates = _stateNames(builderStates).join(", ") == _stateNames(states).join(", ");
    final exhaustiveListenerStates = _stateNames(listenerStates).join(", ") == _stateNames(states).join(", ");

    // isBuilder: this is Main || this is Loading || ...
    final isBuilderBody = builderStates
        .map((s) {
          final name = s.name![0].toUpperCase() + s.name!.substring(1);
          return 'this is $name$prefix';
        })
        .join(' || ');

    // isListener: this is Error || this is Empty || ...
    final isListenerBody = listenerStates
        .map((s) {
          final name = s.name![0].toUpperCase() + s.name!.substring(1);
          return 'this is $name$prefix';
        })
        .join(' || ');

    final isBuilderGetter = Method(
      (m) => m
        ..name = 'isBuilder'
        ..returns = refer('bool')
        ..type = MethodType.getter
        ..lambda = true
        ..body = Code(isBuilderBody),
    );

    final isListenerGetter = Method(
      (m) => m
        ..name = 'isListener'
        ..returns = refer('bool')
        ..type = MethodType.getter
        ..lambda = true
        ..body = Code(isListenerBody),
    );

    // buildWhen
    // listenWhen

    return Extension(
      (e) => e
        ..name = '${className}Extension'
        ..on = refer(className)
        ..methods = ListBuilder<Method>([
          if (builderStates.isNotEmpty) isBuilderGetter,
          if (listenerStates.isNotEmpty) isListenerGetter,
          if ((visitor.stateWhen ?? blocGeneratorConfig.stateWhen) && states.isNotEmpty) _stateWhenMethod(states),
          if ((visitor.buildWhen ?? blocGeneratorConfig.buildWhen) && builderStates.isNotEmpty) _buildWhenMethod(builderStates, exhaustiveBuilderStates),
          if ((visitor.listenWhen ?? blocGeneratorConfig.listenWhen) && states.isNotEmpty) _listenWhenMethod(listenerStates, exhaustiveListenerStates),
        ]),
    );
  }

  // ── stateWhen Method ──────────────────────────────────────────────────────────────────

  Method _buildWhenMethod(List<ConstructorElement> states, bool exhaustive) {
    final prefix = blocGeneratorConfig.withStatePrefix ? "State" : "";
    // stateWhen<T> parameters
    final methodParams = <Parameter>[
      Parameter(
        (p) => p
          ..name = 'orElse'
          ..named = true
          ..required = true
          ..type = refer('T Function()'),
      ),
      // one optional callback per state
      ...states.map((s) {
        final paramName = s.name!; // e.g. "main"
        final funcParams = s.formalParameters;

        // Build "T Function(List<String> names)?" style type string
        final funcArgs = funcParams.map((p) => '${p.type.getDisplayString()} ${p.name!}').join(', ');
        final funcType = 'required T Function($funcArgs)';

        return Parameter(
          (p) => p
            ..name = paramName
            ..named = true
            ..type = refer(funcType),
        );
      }),
    ];

    // switch cases
    final cases = states
        .map((s) {
          final className = s.name![0].toUpperCase() + s.name!.substring(1) + prefix;
          final callbackName = s.name!; // e.g. "main"
          final params = s.formalParameters;

          if (params.isEmpty) {
            // Loading _ when loading != null => loading(),
            return '$className _ => $callbackName()';
          } else {
            // Use first letter of class name as the pattern variable, e.g. "m" for Main
            final varName = '${callbackName}S';
            final args = params.map((p) => '$varName.${p.name!}').join(', ');
            // Main m when main != null => main(m.names),
            return '$className $varName => $callbackName($args)';
          }
        })
        .join(',\n      ');

    final buildWhenBody = Code('''
  switch (this) {
      $cases,
      _ => orElse(),
    }''');

    return Method(
      (m) => m
        ..name = 'buildWhen'
        ..types = ListBuilder<Reference>([refer('T')])
        ..returns = refer('T')
        ..lambda = true
        ..optionalParameters = ListBuilder<Parameter>(methodParams)
        ..body = buildWhenBody,
    );
  }

  // ── stateWhen Method ──────────────────────────────────────────────────────────────────

  Method _listenWhenMethod(List<ConstructorElement> states, bool exhaustive) {
    final prefix = blocGeneratorConfig.withStatePrefix ? "State" : "";
    // stateWhen<T> parameters
    final methodParams = <Parameter>[
      // one optional callback per state
      ...states.map((s) {
        final paramName = s.name!; // e.g. "main"
        final funcParams = s.formalParameters;

        // Build "T Function(List<String> names)?" style type string
        final funcArgs = funcParams.map((p) => '${p.type.getDisplayString()} ${p.name!}').join(', ');
        final funcType = 'required T Function($funcArgs)';

        return Parameter(
          (p) => p
            ..name = paramName
            ..named = true
            ..type = refer(funcType),
        );
      }),
    ];

    // switch cases
    final cases = states
        .map((s) {
          final className = s.name![0].toUpperCase() + s.name!.substring(1) + prefix;
          final callbackName = s.name!; // e.g. "main"
          final params = s.formalParameters;

          if (params.isEmpty) {
            // Loading _ when loading != null => loading(),
            return '$className _ => $callbackName()';
          } else {
            // Use first letter of class name as the pattern variable, e.g. "m" for Main
            final varName = '${callbackName}S';
            final args = params.map((p) => '$varName.${p.name!}').join(', ');
            // Main m when main != null => main(m.names),
            return '$className $varName => $callbackName($args)';
          }
        })
        .join(',\n      ');

    final wildcard = exhaustive ? '' : '\n      _ => null,';

    final listenWhenBody = Code('''
  switch (this) {
      $cases,$wildcard
    }''');

    return Method(
      (m) => m
        ..name = 'listenWhen'
        ..types = ListBuilder<Reference>([refer('T')])
        ..returns = refer('T?')
        ..lambda = true
        ..optionalParameters = ListBuilder<Parameter>(methodParams)
        ..body = listenWhenBody,
    );
  }

  // ── stateWhen Method ──────────────────────────────────────────────────────────────────

  Method _stateWhenMethod(List<ConstructorElement> states) {
    final prefix = blocGeneratorConfig.withStatePrefix ? "State" : "";
    // stateWhen<T> parameters
    final methodParams = <Parameter>[
      // required orElse
      Parameter(
        (p) => p
          ..name = 'orElse'
          ..named = true
          ..required = true
          ..type = refer('T Function()'),
      ),
      // one optional callback per state
      ...states.map((s) {
        final paramName = s.name!; // e.g. "main"
        final funcParams = s.formalParameters;

        // Build "T Function(List<String> names)?" style type string
        final funcArgs = funcParams.map((p) => '${p.type.getDisplayString()} ${p.name!}').join(', ');
        final funcType = 'T Function($funcArgs)?';

        return Parameter(
          (p) => p
            ..name = paramName
            ..named = true
            ..type = refer(funcType),
        );
      }),
    ];

    // switch cases
    final cases = states
        .map((s) {
          final className = s.name![0].toUpperCase() + s.name!.substring(1) + prefix;
          final callbackName = s.name!; // e.g. "main"
          final params = s.formalParameters;

          if (params.isEmpty) {
            // Loading _ when loading != null => loading(),
            return '$className _ when $callbackName != null => $callbackName()';
          } else {
            // Use first letter of class name as the pattern variable, e.g. "m" for Main
            final varName = '${callbackName}S';
            final args = params.map((p) => '$varName.${p.name!}').join(', ');
            // Main m when main != null => main(m.names),
            return '$className $varName when $callbackName != null => $callbackName($args)';
          }
        })
        .join(',\n      ');

    final stateWhenBody = Code('''
  switch (this) {
      $cases,
      _ => orElse(),
    }''');

    return Method(
      (m) => m
        ..name = 'stateWhen'
        ..types = ListBuilder<Reference>([refer('T')])
        ..returns = refer('T')
        ..lambda = true
        ..optionalParameters = ListBuilder<Parameter>(methodParams)
        ..body = stateWhenBody,
    );
  }

  // ── Emitter ──────────────────────────────────────────────────────────────────

  final _emitter = DartEmitter(useNullSafetySyntax: true);

  String _emit(List<Spec> specs) {
    final lib = Library((b) => b.body.addAll(specs));
    return lib.accept(_emitter).toString();
  }
}
