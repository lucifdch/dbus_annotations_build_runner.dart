import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';

class PropertyInfo {
  PropertyGeSetInfo? propertyGetInfo;
  PropertyGeSetInfo? propertySetInfo;
}

class PropertyGeSetInfo {
  late MethodElement property;
  late ConstantReader propertyAnn;

  bool get useValueNotifier => propertyAnn.read('useValueNotifier').boolValue;

  String get propertyName => propertyAnn.read('propertyName').stringValue;

  String get signature => propertyAnn.read('signature').stringValue;
}
