import 'package:analyzer/dart/element/element.dart';
import 'package:bloc_gen_annotations/event.dart';
import 'package:bloc_gen_runner/src/bloc_generator_config.dart';
import 'package:bloc_gen_runner/src/events_visitor.dart';
import 'package:build/build.dart';
import 'package:built_collection/built_collection.dart';
import 'package:code_builder/code_builder.dart';
import 'package:source_gen/source_gen.dart';

class BlocEventsGenerator extends GeneratorForAnnotation<BlocEvents> {
  final BlocGeneratorConfig blocGeneratorConfig;

  BlocEventsGenerator(this.blocGeneratorConfig);

  @override
  String generateForAnnotatedElement(Element element, ConstantReader annotation, BuildStep buildStep) {
    final visitor = EventsVisitor(blocGeneratorConfig);
    if (element is! ClassElement) return '';
    visitor.visitClassElement(element);
    for (final constructor in element.constructors) {
      visitor.visitConstructorElement(constructor);
    }

    final events = visitor.factories.map((record) {
      final (ctor, transformerExpr) = record;
      final prefix = blocGeneratorConfig.withStatePrefix ? "Event" : "";
      final className = ctor.name![0].toUpperCase() + ctor.name!.substring(1) + prefix;
      return Class(
        (c) => c
          ..name = className
          ..implements = ListBuilder<Reference>([Reference(visitor.className)])
          // Only extend EventGenerated when a transformer is present
          ..extend = transformerExpr != null ? Reference('EventGenerated') : null
          ..fields = ListBuilder<Field>(
            ctor.formalParameters
                .map(
                  (param) => Field(
                    (f) => f
                      ..name = param.name
                      ..modifier = FieldModifier.final$
                      ..type = refer(param.type.getDisplayString()),
                  ),
                )
                .toList(),
          )
          ..constructors = ListBuilder<Constructor>([
            Constructor(
              (co) => co
                ..constant = true
                ..optionalParameters = ListBuilder<Parameter>(
                  ctor.formalParameters
                      .where((p) => p.isNamed)
                      .map(
                        (p) => Parameter(
                          (p0) => p0
                            ..required = p.isRequired
                            ..named = true
                            ..name = p.name!
                            ..toThis = true,
                        ),
                      ),
                )
                ..requiredParameters = ListBuilder<Parameter>(
                  ctor.formalParameters
                      .where((p) => p.isRequired && !p.isNamed)
                      .map(
                        (p) => Parameter(
                          (p0) => p0
                            ..name = p.name!
                            ..toThis = true,
                        ),
                      ),
                ),
            ),
          ])
          // Only emit the getter when a transformer is configured
          ..methods = ListBuilder<Method>(
            transformerExpr == null
                ? []
                : [
                    Method(
                      (m) => m
                        ..annotations = ListBuilder([refer('override')])
                        ..returns = refer('EventTransformer?')
                        ..type = MethodType.getter
                        ..name = 'transformer'
                        ..lambda = true
                        ..body = Code(transformerExpr),
                    ),
                  ],
          ),
      );
    }).toList();

    return _emit(events);
  }
}

final _emitter = DartEmitter(useNullSafetySyntax: true);

String _emit(List<Spec> specs) {
  final lib = Library((b) => b.body.addAll(specs));
  return lib.accept(_emitter).toString();
}
