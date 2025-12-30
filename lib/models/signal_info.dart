import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';

class SignalInfo {
  late MethodElement signal;
  late ConstantReader signalAnn;

  String get signalName => signalAnn.read('signalName').stringValue;

  List<String> get argList => signalAnn.read('argList').listValue.map((item) => item.toStringValue()!).toList();
}
