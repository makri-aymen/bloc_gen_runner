import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';

class StatesVisitor extends ElementVisitor2<void> {
  String className = '';

  // BlocStates annotation fields
  late final bool? stateWhen;
  late final bool? buildWhen;
  late final bool? listenWhen;
  late final bool? copyWith;
  late final bool? equatable;

  final List<ConstructorElement> factories = [];

  @override
  void visitClassElement(ClassElement element) {
    className = element.name.toString();

    final annotation = element.metadata.annotations.firstWhere(
      (m) => m.element?.displayName == 'BlocStates',
      orElse: () => throw Exception('No BlocStates annotation found on $className'),
    );

    final reader = ConstantReader(annotation.computeConstantValue());

    copyWith = reader.peek('copyWith')?.boolValue;
    stateWhen = reader.peek('stateWhen')?.boolValue;
    equatable = reader.peek('equatable')?.boolValue;
    buildWhen = reader.peek('buildWhen')?.boolValue;
    listenWhen = reader.peek('listenWhen')?.boolValue;
  }

  @override
  void visitConstructorElement(ConstructorElement element) {
    if (element.isFactory) factories.add(element);
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
