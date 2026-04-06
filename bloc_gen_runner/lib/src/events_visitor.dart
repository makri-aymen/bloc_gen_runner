import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:bloc_gen_runner/src/bloc_generator_config.dart';
import 'package:source_gen/source_gen.dart';

class EventsVisitor extends ElementVisitor2<void> {
  String className = '';
  String? classTransformerExpr; // from @BlocEvents
  final List<(ConstructorElement, String?)> factories = []; // (ctor, transformerExpr)
  final BlocGeneratorConfig config;

  EventsVisitor(this.config);

  @override
  void visitClassElement(ClassElement element) {
    className = element.name.toString();

    final annotation = element.metadata.annotations.firstWhere(
      (m) => m.element?.displayName == 'BlocEvents',
      orElse: () => throw Exception("No BlocEvents annotation found on $className"),
    );

    final reader = ConstantReader(annotation.computeConstantValue());
    final transformerValue = reader.peek('transformer');

    classTransformerExpr = (transformerValue == null || transformerValue.isNull) ? null : _readTransformerExpr(transformerValue.objectValue);
  }

  @override
  void visitConstructorElement(ConstructorElement element) {
    if (element.name == null || element.name!.isEmpty) return;

    // Read per-event @BlocEvent annotation if present
    final annotation = element.metadata.annotations.where((m) => m.element?.displayName == 'BlocEvent').firstOrNull;

    String? transformerExpr;
    if (annotation != null) {
      final reader = ConstantReader(annotation.computeConstantValue());
      final transformerValue = reader.peek('transformer');
      if (transformerValue != null && !transformerValue.isNull) {
        transformerExpr = _readTransformerExpr(transformerValue.objectValue);
      }
    }

    // Fall back to class-level transformer if no event-level one
    final resolved = transformerExpr ?? classTransformerExpr ?? config.defaultTransformer;
    factories.add((element, resolved == 'concurrent()' ? null : resolved));
  }

  String? _readTransformerExpr(DartObject obj) {
    final typeName = obj.type?.element?.name;
    return switch (typeName) {
      'Concurrent' => 'concurrent()',
      'Sequential' => 'sequential()',
      'Restartable' => 'restartable()',
      'Droppable' => 'droppable()',
      'Debounce' => _rateExpr('debounce', obj),
      'Throttle' => _rateExpr('throttle', obj),
      _ => null,
    };
  }

  String _rateExpr(String fn, DartObject obj) {
    final duration = _readDurationExpr(obj);
    final inner = obj.getField('transformer');
    final innerExpr = (inner == null || inner.isNull) ? null : _readTransformerExpr(inner);
    final andThen = innerExpr != null ? ', andThen: $innerExpr' : '';
    return '$fn($duration$andThen)';
  }

  String _readDurationExpr(DartObject obj) {
    final microseconds =
        obj
            .getField('(super)') // _RateLimiter
            ?.getField('duration') // Duration object
            ?.getField('_duration') // internal microseconds
            ?.toIntValue() ??
        0;

    if (microseconds % Duration.microsecondsPerSecond == 0) {
      return 'Duration(seconds: ${microseconds ~/ Duration.microsecondsPerSecond})';
    }
    if (microseconds % Duration.microsecondsPerMillisecond == 0) {
      return 'Duration(milliseconds: ${microseconds ~/ Duration.microsecondsPerMillisecond})';
    }
    return 'Duration(microseconds: $microseconds)';
  }

  @override
  void visitEnumElement(EnumElement element) {}

  @override
  void visitExtensionElement(ExtensionElement element) {}

  @override
  void visitExtensionTypeElement(ExtensionTypeElement element) {}

  @override
  void visitFieldElement(FieldElement element) {}

  @override
  void visitFieldFormalParameterElement(FieldFormalParameterElement element) {}

  @override
  void visitFormalParameterElement(FormalParameterElement element) {}

  @override
  void visitGenericFunctionTypeElement(GenericFunctionTypeElement element) {}

  @override
  void visitGetterElement(GetterElement element) {}

  @override
  void visitLabelElement(LabelElement element) {}

  @override
  void visitLibraryElement(LibraryElement element) {}

  @override
  void visitLocalFunctionElement(LocalFunctionElement element) {}

  @override
  void visitLocalVariableElement(LocalVariableElement element) {}

  @override
  void visitMethodElement(MethodElement element) {}

  @override
  void visitMixinElement(MixinElement element) {}

  @override
  void visitMultiplyDefinedElement(MultiplyDefinedElement element) {}

  @override
  void visitPrefixElement(PrefixElement element) {}

  @override
  void visitSetterElement(SetterElement element) {}

  @override
  void visitSuperFormalParameterElement(SuperFormalParameterElement element) {}

  @override
  void visitTopLevelFunctionElement(TopLevelFunctionElement element) {}

  @override
  void visitTopLevelVariableElement(TopLevelVariableElement element) {}

  @override
  void visitTypeAliasElement(TypeAliasElement element) {}

  @override
  void visitTypeParameterElement(TypeParameterElement element) {}
}
