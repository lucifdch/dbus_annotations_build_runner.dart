part of 'dbus_generator_handler.dart';

extension GeneratorClientLocalProperties on DBusGeneratorHandler {
  void buildClientLocalProperties() {
    if (classInfo.propertyInfoMap.isNotEmpty && classInfo.useLocalProperties) {
      buffer.writeln('// =========================');
      buffer.writeln('// 本地属性操作 (Local Properties)');
      buffer.writeln('// =========================');
      buffer.writeln('class ${classInfo.className}_ClientLocalProperties extends DBusClientLocalProperties {');

      bool isUseValueNotifier = false;

      for (final p in classInfo.propertyInfoMap.entries) {
        final propertyInfo = p.value;

        final DartType dartType;
        final String propertyName;
        final String signature;
        final bool useValueNotifier;
        if (propertyInfo.propertyGetInfo != null) {
          final returnType = propertyInfo.propertyGetInfo!.property.returnType as InterfaceType;

          dartType = returnType.typeArguments.first;
          propertyName = propertyInfo.propertyGetInfo!.propertyName;
          signature = propertyInfo.propertyGetInfo!.signature;
          useValueNotifier = propertyInfo.propertyGetInfo!.useValueNotifier;
        } else {
          dartType = propertyInfo.propertySetInfo!.property.formalParameters.first.type;
          propertyName = propertyInfo.propertySetInfo!.propertyName;
          signature = propertyInfo.propertySetInfo!.signature;
          useValueNotifier = propertyInfo.propertySetInfo!.useValueNotifier;
        }

        if (useValueNotifier) {
          buildClientLocalPropertyVN(dartType, propertyName, signature);
          isUseValueNotifier = true;
        } else {
          buildClientLocalProperty(dartType, propertyName, signature);
        }
      }

      buffer.writeln();
      buffer.writeln('@override');
      buffer.writeln('bool setValue(String key, DBusValue? value) {');
      if (classInfo.useLog) {
        buffer.writeln('${classInfo.className}_Log.trace("setValue -> key: \$key value: \$value");');
        buffer.writeln();
      }
      buffer.writeln('switch (key) {');
      for (final p in classInfo.propertyInfoMap.entries) {
        final propertyInfo = p.value;

        final String propertyName;
        final String signature;
        final bool useValueNotifier;
        if (propertyInfo.propertyGetInfo != null) {
          propertyName = propertyInfo.propertyGetInfo!.propertyName;
          signature = propertyInfo.propertyGetInfo!.signature;
          useValueNotifier = propertyInfo.propertyGetInfo!.useValueNotifier;
        } else {
          propertyName = propertyInfo.propertySetInfo!.propertyName;
          signature = propertyInfo.propertySetInfo!.signature;
          useValueNotifier = propertyInfo.propertySetInfo!.useValueNotifier;
        }

        if (useValueNotifier) {
          buildClientLocalPropertySetValueVN(propertyName, signature);
        } else {
          buildClientLocalPropertySetValue(propertyName, signature);
        }
      }
      buffer.writeln('default:');
      buffer.writeln('return super.setValue(key, value);');
      buffer.writeln('}');
      buffer.writeln('}');

      buffer.writeln('@override');
      buffer.writeln('Object? getValue(String key) => switch (key) {');
      for (final p in classInfo.propertyInfoMap.entries) {
        final propertyInfo = p.value;

        final String propertyName;
        final bool useValueNotifier;
        if (propertyInfo.propertyGetInfo != null) {
          propertyName = propertyInfo.propertyGetInfo!.propertyName;
          useValueNotifier = propertyInfo.propertyGetInfo!.useValueNotifier;
        } else {
          propertyName = propertyInfo.propertySetInfo!.propertyName;
          useValueNotifier = propertyInfo.propertySetInfo!.useValueNotifier;
        }

        if (useValueNotifier) {
          buildClientLocalPropertyGetValueVN(propertyName);
        } else {
          buildClientLocalPropertyGetValue(propertyName);
        }
      }
      buffer.writeln('_ => super.getValue(key),');
      buffer.writeln('};');

      if (isUseValueNotifier) {
        buffer.writeln('@override');
        buffer.writeln('void release() {');
        if (classInfo.useLog) {
          buffer.writeln('${classInfo.className}_Log.trace("release");');
          buffer.writeln();
        }

        for (final p in classInfo.propertyInfoMap.entries) {
          final propertyInfo = p.value;

          final String propertyName;
          final bool useValueNotifier;
          if (propertyInfo.propertyGetInfo != null) {
            propertyName = propertyInfo.propertyGetInfo!.propertyName;
            useValueNotifier = propertyInfo.propertyGetInfo!.useValueNotifier;
          } else {
            propertyName = propertyInfo.propertySetInfo!.propertyName;
            useValueNotifier = propertyInfo.propertySetInfo!.useValueNotifier;
          }

          if (useValueNotifier) {
            buildClientReleaseVN(propertyName);
          }
        }
        buffer.writeln('}');
      }

      buffer.writeln('}');
    }
  }

  void buildClientLocalPropertyVN(DartType dartType, String name, String signature) {
    var typeName = dartType.getDisplayString();
    if (!typeName.endsWith("?")) {
      typeName += "?";
    }
    buffer.writeln('final ${name}_ValueNotifier = ValueNotifier<$typeName>(null);');
  }

  void buildClientLocalProperty(DartType dartType, String name, String signature) {
    var typeName = dartType.getDisplayString();
    if (!typeName.endsWith("?")) {
      typeName += "?";
    }
    buffer.writeln('$typeName $name;');
  }

  void buildClientLocalPropertySetValueVN(String name, String signature) {
    buffer.writeln('case "$name":');
    buffer.writeln('final newValue = value?${dbusSignatureToNative(signature)};');
    buffer.writeln('final isUpdated = ${name}_ValueNotifier.value != newValue;');
    buffer.writeln('if (isUpdated) {');
    buffer.writeln('${name}_ValueNotifier.value = newValue;');
    buffer.writeln('}');
    buffer.writeln('return isUpdated;');
  }

  void buildClientLocalPropertySetValue(String name, String signature) {
    buffer.writeln('case "$name":');
    buffer.writeln('final newValue = value?${dbusSignatureToNative(signature)};');
    buffer.writeln('final isUpdated = $name != newValue;');
    buffer.writeln('if (isUpdated) {');
    buffer.writeln('$name = newValue;');
    buffer.writeln('}');
    buffer.writeln('return isUpdated;');
  }

  void buildClientLocalPropertyGetValueVN(String name) {
    buffer.writeln('"$name" => ${name}_ValueNotifier.value,');
  }

  void buildClientLocalPropertyGetValue(String name) {
    buffer.writeln('"$name" => $name,');
  }

  void buildClientReleaseVN(String name) {
    buffer.writeln('${name}_ValueNotifier.dispose();');
  }
}
