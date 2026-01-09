import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import '../dbus/dbus_signature_to_native.dart';
import '../models/class_info.dart';
import '../models/method_info.dart';
import '../models/property_info.dart';
import '../models/signal_info.dart';

part 'generator_client.dart';
part 'generator_service.dart';

const annotationsPackage = 'package:dbus_annotations/src/annotations.dart';

final checkerInterface = TypeChecker.fromUrl('$annotationsPackage#DBusDocInterface');
final checkerMethod = TypeChecker.fromUrl('$annotationsPackage#DBusDocMethod');
final checkerSignal = TypeChecker.fromUrl('$annotationsPackage#DBusDocSignal');
final checkerPropertyGet = TypeChecker.fromUrl('$annotationsPackage#DBusDocProperty_Get');
final checkerPropertySet = TypeChecker.fromUrl('$annotationsPackage#DBusDocProperty_Set');

class DBusGeneratorHandler {
  final ClassElement classElement;
  final ConstantReader annotation;
  final BuildStep buildStep;

  late final ClassInfo classInfo;
  final buffer = StringBuffer();

  DBusGeneratorHandler({required this.classElement, required this.annotation, required this.buildStep});

  String run() {
    dataSummary();
    buildTitle();

    final buildList = classInfo.buildList;

    if (buildList.contains('client')) {
      buildClientHelper();
    }

    if (buildList.contains('service')) {
      buildServiceHelper();
    }
    return buffer.toString();
  }

  void dataSummary() {
    classInfo = ClassInfo()
      ..interface = classElement
      ..interfaceAnn = annotation;

    for (final method in classElement.methods) {
      final methodAnn = checkerMethod.firstAnnotationOfExact(method);
      if (methodAnn != null) {
        classInfo.methodInfoList.add(
          MethodInfo()
            ..method = method
            ..methodAnn = ConstantReader(methodAnn),
        );
      }

      final signalAnn = checkerSignal.firstAnnotationOfExact(method);
      if (signalAnn != null) {
        classInfo.signalInfoList.add(
          SignalInfo()
            ..signal = method
            ..signalAnn = ConstantReader(signalAnn),
        );
      }

      final propertyGetAnn = checkerPropertyGet.firstAnnotationOfExact(method);
      if (propertyGetAnn != null) {
        final propertyName = propertyGetAnn.getField('propertyName')!.toStringValue()!;
        classInfo.propertyInfoMap[propertyName] ??= PropertyInfo();
        classInfo.propertyInfoMap[propertyName]!.propertyGetInfo = PropertyGeSetInfo()
          ..property = method
          ..propertyAnn = ConstantReader(propertyGetAnn);
      }

      final propertySetAnn = checkerPropertySet.firstAnnotationOfExact(method);
      if (propertySetAnn != null) {
        final propertyName = propertySetAnn.getField('propertyName')!.toStringValue()!;
        classInfo.propertyInfoMap[propertyName] ??= PropertyInfo();
        classInfo.propertyInfoMap[propertyName]!.propertySetInfo = PropertyGeSetInfo()
          ..property = method
          ..propertyAnn = ConstantReader(propertySetAnn);
      }

      // 检测get于set属性签名是否相等
      for (final kv in classInfo.propertyInfoMap.entries) {
        if (kv.value.propertyGetInfo != null && kv.value.propertySetInfo != null) {
          //
          if (kv.value.propertyGetInfo!.useValueNotifier != kv.value.propertySetInfo!.useValueNotifier) {
            throw StateError('property "${kv.key}" useValueNotifier not equal, get is (${kv.value.propertyGetInfo!.useValueNotifier}); set is (${kv.value.propertySetInfo!.useValueNotifier}).');
          }

          //
          if (kv.value.propertyGetInfo!.signature != kv.value.propertySetInfo!.signature) {
            throw StateError('property "${kv.key}" signature not equal, get is (${kv.value.propertyGetInfo!.signature}); set is (${kv.value.propertySetInfo!.signature}).');
          }
        }
      }
    }
  }

  void buildTitle() {
    buffer.writeln('const ${classInfo.className}_InterfaceName = "${classInfo.interfaceName}";');
    if (classInfo.useLog) {
      buffer.writeln('final ${classInfo.className}_Log = DBusLogger("${classInfo.className}");');
    }
  }
}
