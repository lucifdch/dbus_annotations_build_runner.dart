part of 'dbus_generator_handler.dart';

extension GeneratorClientHelper on DBusGeneratorHandler {
  void buildClientHelper() {
    if (classInfo.signalInfoList.isNotEmpty) {
      buffer.writeln('// =========================');
      buffer.writeln('// 信号声明 (Signal Declaration)');
      buffer.writeln('// =========================');
    }

    for (final s in classInfo.signalInfoList) {
      buildClientSignalDeclaration(s);
    }

    buffer.writeln('// =========================');
    buffer.writeln('// 调用对象 (Client)');
    buffer.writeln('// =========================');
    buffer.writeln('class ${classInfo.className}_ClientHelper extends DBusClientHelper implements ${classInfo.className} {');
    buffer.writeln('${classInfo.className}_ClientHelper(super.remoteObject) : super(interfaceName: ${classInfo.className}_InterfaceName);');

    if (classInfo.methodInfoList.isNotEmpty) {
      buffer.writeln('// =========================');
      buffer.writeln('// 方法 (Methods)');
      buffer.writeln('// =========================');

      for (final m in classInfo.methodInfoList) {
        buildClientMethod(m);
      }
    }

    if (classInfo.signalInfoList.isNotEmpty) {
      buffer.writeln('// =========================');
      buffer.writeln('// 信号 (Signals)');
      buffer.writeln('// =========================');

      for (final s in classInfo.signalInfoList) {
        buildClientSignal(s);
      }
    }

    if (classInfo.propertyInfoMap.isNotEmpty) {
      buffer.writeln('// =========================');
      buffer.writeln('// 属性 (Properties)');
      buffer.writeln('// =========================');

      for (final p in classInfo.propertyInfoMap.entries) {
        final propertyInfo = p.value;

        if (propertyInfo.propertyGetInfo != null) {
          buildClientProperty_Get(propertyInfo.propertyGetInfo!);
        }

        if (propertyInfo.propertySetInfo != null) {
          buildClientProperty_Set(propertyInfo.propertySetInfo!);
        }
      }
    }

    if (classInfo.propertyInfoMap.isNotEmpty && classInfo.useLocalProperties) {
      buffer.writeln('final _localProperties = ${classInfo.className}_ClientLocalProperties();');
      buffer.writeln('@override');
      buffer.writeln('${classInfo.className}_ClientLocalProperties get localProperties => _localProperties;');
    } else {
      buffer.writeln('@override');
      buffer.writeln('DBusClientLocalProperties? get localProperties => null;');
    }

    buffer.writeln('}');
  }

  void buildClientSignalDeclaration(SignalInfo signalInfo) {
    buffer.writeln('class ${classInfo.className}_${signalInfo.signalName}Signal extends DBusSignal {');

    final argList = signalInfo.argList;
    final pmList = signalInfo.signal.formalParameters;

    for (var index = 0; index < argList.length; index++) {
      final arg = argList[index];
      final pm = pmList[index];
      buffer.writeln('${pm.type.getDisplayString()} get ${pm.displayName} => values[$index]${dbusSignatureToNative(arg)};');
    }

    buffer.writeln(
        '${classInfo.className}_${signalInfo.signalName}Signal(DBusSignal signal) : super(sender: signal.sender, path: signal.path, interface: signal.interface, name: signal.name, values: signal.values);');
    buffer.writeln('}');
  }

  void buildClientMethod(MethodInfo methodInfo) {
    final args = methodInfo.argList;
    final resultList = methodInfo.resultList;
    final resultSignature = resultList.join("");

    final pms = <String>[];
    final dbusValuePms = <String>[];

    for (var index = 0; index < methodInfo.method.formalParameters.length; index++) {
      final p = methodInfo.method.formalParameters[index];
      pms.add(p.displayString(preferTypeAlias: true));
      dbusValuePms.add(nativeToDBusValue(p.name!, args[index]));
    }

    buffer.writeln('@override');
    buffer.writeln('${methodInfo.method.returnType.getDisplayString()} ${methodInfo.method.displayName}(${pms.join(", ")}) async {');
    if (classInfo.useLog) {
      buffer.writeln('${classInfo.className}_Log.trace("Method ${methodInfo.methodName}(${args.join("")}) -> ($resultSignature)");');
    }

    buffer.writeln('final ${resultList.isEmpty ? "_" : "result"} = await callMethod("${methodInfo.methodName}", [${dbusValuePms.join(", ")}], replySignature: DBusSignature("$resultSignature"));');
    if (resultList.length == 1) {
      buffer.writeln('return result.values[0]${dbusSignatureToNative(resultList[0])};');
    } else if (resultList.length > 1) {
      int argIndex = 0;
      final result = resultList.map((arg) => 'result.values[$argIndex]${dbusSignatureToNative(resultList[argIndex++])}').join(', ');
      buffer.writeln('return ($result);');
    }

    buffer.writeln('}');
  }

  void buildClientSignal(SignalInfo signalInfo) {
    final pms = signalInfo.signal.formalParameters.map((p) => p.displayString(preferTypeAlias: true)).join(', ');

    buffer.writeln('@override');
    buffer.writeln('${signalInfo.signal.returnType.getDisplayString()} ${signalInfo.signal.displayName}($pms) async {');
    buffer.writeln('throw UnimplementedError("Do not call this method. use ${signalInfo.signal.displayName}Signal.");');
    buffer.writeln('}');

    buffer.writeln('late final Stream<${classInfo.className}_${signalInfo.signalName}Signal> ${signalInfo.signal.displayName}Signal;');

    buffer.writeln('void ${signalInfo.signal.displayName}SignalInit() {');
    buffer.writeln(
        '${signalInfo.signal.displayName}Signal = buildSignal("${signalInfo.signalName}", signature: DBusSignature("${signalInfo.argList.join('')}")).map((signal) => ${classInfo.className}_${signalInfo.signalName}Signal(signal));');
    buffer.writeln('}');
  }

  void buildClientProperty_Get(PropertyGeSetInfo propertyInfo) {
    buffer.writeln('@override');
    buffer.writeln('${propertyInfo.property.returnType.getDisplayString()} ${propertyInfo.property.displayName}() async {');
    if (classInfo.useLog) {
      buffer.writeln('${classInfo.className}_Log.trace("Property Get ${propertyInfo.propertyName} -> ${propertyInfo.signature}");');
    }
    buffer.writeln('return (await getProperty("${propertyInfo.propertyName}", signature: DBusSignature("${propertyInfo.signature}")))${dbusSignatureToNative(propertyInfo.signature)};');
    buffer.writeln('}');
  }

  void buildClientProperty_Set(PropertyGeSetInfo propertyInfo) {
    final p = propertyInfo.property.formalParameters.first;

    buffer.writeln('@override');
    buffer.writeln('Future<void> ${propertyInfo.property.displayName}(${p.displayString(preferTypeAlias: true)}) async {');
    if (classInfo.useLog) {
      buffer.writeln('${classInfo.className}_Log.trace("Property Set ${propertyInfo.propertyName} = ${propertyInfo.signature}");');
    }
    buffer.writeln('await setProperty("${propertyInfo.propertyName}", ${nativeToDBusValue(p.displayName, propertyInfo.signature)});');
    buffer.writeln('}');
  }
}
