import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';

class MethodInfo {
  late MethodElement method;
  late ConstantReader methodAnn;

  String get methodName => methodAnn.read('methodName').stringValue;

  List<String> get argList => methodAnn.read('argList').listValue.map((item) => item.toStringValue()!).toList();

  List<String> get resultList => methodAnn.read('resultList').listValue.map((item) => item.toStringValue()!).toList();
}
