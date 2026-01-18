import 'dart:collection';

import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';

import 'method_info.dart';
import 'property_info.dart';
import 'signal_info.dart';

class ClassInfo {
  late ClassElement interface;
  late ConstantReader interfaceAnn;

  String get className => interface.displayName;

  String get interfaceName => interfaceAnn.read('interfaceName').stringValue;

  bool get useLog => interfaceAnn.read('useLog').boolValue;

  bool get useLocalProperties => interfaceAnn.read('useLocalProperties').boolValue;

  List<String> get buildList => interfaceAnn.read('buildList').listValue.map((i) => i.getField('_name')!.toStringValue()!).toList();

  final methodInfoList = <MethodInfo>[];
  final signalInfoList = <SignalInfo>[];
  final propertyInfoMap = LinkedHashMap<String, PropertyInfo>();
}
