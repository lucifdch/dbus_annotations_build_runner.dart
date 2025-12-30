import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:dbus_annotations/dbus_annotations.dart';
import 'package:source_gen/source_gen.dart';

import 'generator/dbus_generator_handler.dart';

Builder dbusBuilder(BuilderOptions options) {
  print(options);
  return SharedPartBuilder([DBusGenerator()], 'dbus');
}

class DBusGenerator extends GeneratorForAnnotation<DBusDocInterface> {
  @override
  generateForAnnotatedElement(Element element, ConstantReader annotation, BuildStep buildStep) {
    if (element is! ClassElement) {
      return '';
    }

    return DBusGeneratorHandler(
      classElement: element,
      annotation: annotation,
      buildStep: buildStep,
    ).run();
  }
}
