part of 'dbus_generator_handler.dart';

extension GeneratorServiceHelper on DBusGeneratorHandler {
  void buildServiceHelper() {
    buffer.writeln('// =========================');
    buffer.writeln('// 服务对象 (Service)');
    buffer.writeln('// =========================');

    buffer.writeln('class ${classInfo.className}_ServiceHelper {');
    buildServiceIntrospect();
    buildServiceHandleMethodCall();
    buildServiceGetProperty();
    buildServiceSetProperty();
    buildServiceGetAllProperty();
    buffer.writeln('}');
  }

  void buildServiceIntrospect() {
    buffer.writeln('static DBusIntrospectInterface introspect() {');
    if (classInfo.useLog) {
      buffer.writeln('${classInfo.className}_Log.debug("introspect");');
    }
    buffer.writeln('return DBusIntrospectInterface(');
    buffer.writeln('${classInfo.className}_InterfaceName,');

    if (classInfo.methodInfoList.isNotEmpty) {
      buffer.writeln('methods: [');
      for (final methodInfo in classInfo.methodInfoList) {
        buildServiceIntrospectMethodInfo(methodInfo);
      }
      buffer.writeln('],');
    }

    if (classInfo.signalInfoList.isNotEmpty) {
      buffer.writeln('signals: [');
      for (final signalInfo in classInfo.signalInfoList) {
        buildServiceIntrospectSignalInfo(signalInfo);
      }
      buffer.writeln('],');
    }

    if (classInfo.propertyInfoMap.isNotEmpty) {
      buffer.writeln('properties: [');
      for (final entry in classInfo.propertyInfoMap.entries) {
        buildServiceIntrospectPropertyInfo(entry.key, entry.value);
      }
      buffer.writeln('],');
    }
    buffer.writeln(');');
    buffer.writeln('}');
  }

  void buildServiceIntrospectMethodInfo(MethodInfo methodInfo) {
    buffer.writeln('DBusIntrospectMethod(');
    buffer.writeln('"${methodInfo.methodName}",');
    final argList = methodInfo.argList;
    final resultList = methodInfo.resultList;
    if (argList.isNotEmpty || resultList.isNotEmpty) {
      buffer.writeln('args:[');
      final argNameList = methodInfo.method.formalParameters.map((p) => p.name).toList();
      for (var index = 0; index < argList.length; index++) {
        final arg = argList[index];
        final argName = argNameList[index];
        buffer.writeln('DBusIntrospectArgument(DBusSignature("$arg"), .in_, name: "$argName"),');
      }

      for (var index = 0; index < resultList.length; index++) {
        final result = resultList[index];
        buffer.writeln('DBusIntrospectArgument(DBusSignature("$result"), .out),');
      }
      buffer.writeln('],');
    }
    buffer.writeln('),');
  }

  void buildServiceIntrospectSignalInfo(SignalInfo signalInfo) {
    buffer.writeln('DBusIntrospectSignal(');
    buffer.writeln('"${signalInfo.signalName}",');
    final argList = signalInfo.argList;
    if (argList.isNotEmpty) {
      buffer.writeln('args:[');
      final argNameList = signalInfo.signal.formalParameters.map((p) => p.name).toList();
      for (var index = 0; index < argList.length; index++) {
        final arg = argList[index];
        final argName = argNameList[index];
        buffer.writeln('DBusIntrospectArgument(DBusSignature("$arg"), .in_, name: "$argName"),');
      }
      buffer.writeln('],');
    }
    buffer.writeln('),');
  }

  void buildServiceIntrospectPropertyInfo(String propertyName, PropertyInfo propertyInfo) {
    final String access;
    final String signature;
    if (propertyInfo.propertyGetInfo != null && propertyInfo.propertySetInfo != null) {
      access = '.readwrite';
      signature = propertyInfo.propertyGetInfo!.signature;
    } else if (propertyInfo.propertyGetInfo != null) {
      access = '.read';
      signature = propertyInfo.propertyGetInfo!.signature;
    } else {
      access = '.write';
      signature = propertyInfo.propertySetInfo!.signature;
    }
    buffer.writeln('DBusIntrospectProperty("$propertyName", DBusSignature("$signature"), access: $access),');
  }

  void buildServiceHandleMethodCall() {
    buffer.writeln(
        'static Future<DBusMethodResponse> handleMethodCall(${classInfo.className} instance, DBusMethodCall methodCall, {DBusMethodErrorResponse? Function(Object e, StackTrace s)? interceptError}) async {');
    if (classInfo.useLog) {
      buffer.writeln('${classInfo.className}_Log.trace("handleMethodCall -> \$methodCall");');
    }
    buffer.writeln();
    buffer.writeln('if (methodCall.interface != ${classInfo.className}_InterfaceName) {');
    buffer.writeln('return DBusMethodErrorResponse.unknownInterface(methodCall.interface);');
    buffer.writeln('}');
    buffer.writeln();

    buffer.writeln('try {');

    buffer.writeln('switch (methodCall.name) {');
    for (final methodInfo in classInfo.methodInfoList) {
      buildServiceHandleMethodCallMethod(methodInfo);
    }
    buffer.writeln('default:');
    buffer.writeln('return DBusMethodErrorResponse.unknownMethod(methodCall.name);');
    buffer.writeln('}');

    buffer.writeln('} catch (e, s) {');

    buffer.writeln('final errResp = interceptError?.call(e, s);');
    buffer.writeln('if (errResp != null) {return errResp;}');
    if (classInfo.useLog) {
      buffer.writeln('${classInfo.className}_Log.warning("handleMethodCall err", e, s);');
    }
    buffer.writeln('return DBusMethodErrorResponse.failed(e.toString());');

    buffer.writeln('}');
    buffer.writeln('}');
  }

  void buildServiceHandleMethodCallMethod(MethodInfo methodInfo) {
    buffer.writeln('case "${methodInfo.methodName}":');

    final argList = methodInfo.argList;
    final argNameList = methodInfo.method.formalParameters.map((p) => p.name).toList();
    final resultList = methodInfo.resultList;

    for (var index = 0; index < argList.length; index++) {
      final arg = argList[index];
      final argName = argNameList[index];
      buffer.writeln('final $argName = methodCall.values[$index]${dbusSignatureToNative(arg)};');
    }
    buffer.writeln('final ${resultList.isEmpty ? "_" : "result"} = await instance.${methodInfo.method.displayName}(${argNameList.join(', ')});');

    if (resultList.length > 1) {
      final resultStrList = <String>[];
      for (var index = 0; index < resultList.length; index++) {
        resultStrList.add(nativeToDBusValue('result.\$${index + 1}', resultList[index]));
      }
      buffer.writeln('return DBusMethodSuccessResponse([${resultStrList.join(', ')}]);');
    } else if (resultList.isNotEmpty) {
      buffer.writeln('return DBusMethodSuccessResponse([${nativeToDBusValue('result', resultList.first)}]);');
    } else {
      buffer.writeln('return DBusMethodSuccessResponse();');
    }
  }

  void buildServiceGetProperty() {
    buffer.writeln('static Future<DBusMethodResponse> getProperty(${classInfo.className} instance, String ifaceName, String name) async {');
    if (classInfo.useLog) {
      buffer.writeln('${classInfo.className}_Log.trace("getProperty -> \$ifaceName \$name");');
    }
    buffer.writeln();
    buffer.writeln('if (ifaceName != ${classInfo.className}_InterfaceName) {');
    buffer.writeln('return DBusMethodErrorResponse.unknownInterface(ifaceName);');
    buffer.writeln('}');
    buffer.writeln();
    buffer.writeln('switch (name) {');

    final propertyList = classInfo.propertyInfoMap.entries.toList();
    propertyList.sort((a, b) {
      if (a.value.propertyGetInfo == null && b.value.propertyGetInfo == null) {
        return 0;
      } else if (a.value.propertyGetInfo != null && b.value.propertyGetInfo != null) {
        return 0;
      } else if (a.value.propertyGetInfo == null) {
        return 1;
      } else if (b.value.propertyGetInfo == null) {
        return -1;
      }
      return 0;
    });

    for (final propertyInfo in propertyList) {
      buildServiceGetPropertyInfo(propertyInfo.key, propertyInfo.value);
    }
    buffer.writeln('default:');
    buffer.writeln('return DBusMethodErrorResponse.unknownProperty(name);');
    buffer.writeln('}');
    buffer.writeln('}');
  }

  void buildServiceGetPropertyInfo(String propertyName, PropertyInfo propertyInfo) {
    buffer.writeln('case "$propertyName":');
    if (propertyInfo.propertyGetInfo != null) {
      buffer.writeln('return DBusMethodSuccessResponse([${nativeToDBusValue("(await instance.${propertyInfo.propertyGetInfo!.property.displayName}())", propertyInfo.propertyGetInfo!.signature)}]);');
    } else {
      buffer.writeln('return DBusMethodErrorResponse.propertyWriteOnly("\$ifaceName \$name");');
    }
  }

  void buildServiceSetProperty() {
    buffer.writeln('static Future<DBusMethodResponse> setProperty(${classInfo.className} instance, String ifaceName, String name, DBusValue value) async {');
    if (classInfo.useLog) {
      buffer.writeln('${classInfo.className}_Log.trace("setProperty -> \$ifaceName \$name \$value");');
    }
    buffer.writeln();
    buffer.writeln('if (ifaceName != ${classInfo.className}_InterfaceName) {');
    buffer.writeln('return DBusMethodErrorResponse.unknownInterface(ifaceName);');
    buffer.writeln('}');
    buffer.writeln();
    buffer.writeln('switch (name) {');

    final propertyList = classInfo.propertyInfoMap.entries.toList();
    propertyList.sort((a, b) {
      if (a.value.propertySetInfo == null && b.value.propertySetInfo == null) {
        return 0;
      } else if (a.value.propertySetInfo != null && b.value.propertySetInfo != null) {
        return 0;
      } else if (a.value.propertySetInfo == null) {
        return 1;
      } else if (b.value.propertySetInfo == null) {
        return -1;
      }
      return 0;
    });

    for (final propertyInfo in propertyList) {
      buildServiceSetPropertyInfo(propertyInfo.key, propertyInfo.value);
    }
    buffer.writeln('default:');
    buffer.writeln('return DBusMethodErrorResponse.unknownProperty(name);');
    buffer.writeln('}');
    buffer.writeln('}');
  }

  void buildServiceSetPropertyInfo(String propertyName, PropertyInfo propertyInfo) {
    buffer.writeln('case "$propertyName":');
    if (propertyInfo.propertySetInfo != null) {
      buffer.writeln('await instance.${propertyInfo.propertySetInfo!.property.displayName}(value${dbusSignatureToNative(propertyInfo.propertySetInfo!.signature)});');
      buffer.writeln('return DBusMethodSuccessResponse();');
    } else {
      buffer.writeln('return DBusMethodErrorResponse.propertyReadOnly("\$ifaceName \$name");');
    }
  }

  void buildServiceGetAllProperty() {
    buffer.writeln('static Future<DBusMethodResponse> getAllProperties(${classInfo.className} instance, String ifaceName) async {');
    if (classInfo.useLog) {
      buffer.writeln('${classInfo.className}_Log.trace("getAllProperties -> \$ifaceName");');
    }
    buffer.writeln();
    buffer.writeln('if (ifaceName != ${classInfo.className}_InterfaceName) {');
    buffer.writeln('return DBusMethodErrorResponse.unknownInterface(ifaceName);');
    buffer.writeln('}');
    buffer.writeln();
    buffer.writeln('final allProperties = <String, DBusValue>{};');

    for (final propertyInfo in classInfo.propertyInfoMap.entries) {
      buildServiceGetAllPropertyInfo(propertyInfo.key, propertyInfo.value);
      buffer.writeln();
    }

    buffer.writeln('return DBusGetAllPropertiesResponse(allProperties);');
    buffer.writeln('}');
  }

  void buildServiceGetAllPropertyInfo(String propertyName, PropertyInfo propertyInfo) {
    if (propertyInfo.propertyGetInfo == null) {
      buffer.writeln('// $propertyName write only');
      return;
    }

    buffer.writeln('try {');
    buffer.writeln('allProperties["$propertyName"] = ${nativeToDBusValue('(await instance.${propertyInfo.propertyGetInfo!.property.displayName}())', propertyInfo.propertyGetInfo!.signature)};');
    buffer.writeln('} catch (e, s) {');
    if (classInfo.useLog) {
      buffer.writeln('${classInfo.className}_Log.warning("Error getting property -> $propertyName", e, s);');
    } else {
      buffer.writeln('// get property $propertyName fail.');
    }
    buffer.writeln('}');
  }
}
