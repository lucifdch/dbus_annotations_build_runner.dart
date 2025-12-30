<!-- 
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages). 

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages). 
-->

TODO: Put a short description of the package here that helps potential users
know whether this package might be useful for them.

## Features

TODO: List what your package can do. Maybe include images, gifs, or videos.

## Getting started

TODO: List prerequisites and provide or point to information on how to
start using the package.

## Usage

TODO: Include short and useful examples for package users. Add longer examples
to `/example` folder. 

```dart
const like = 'sample';
```

## Additional information

TODO: Tell users more about the package: where to find more information, how to 
contribute to the package, how to file issues, what response they can expect 
from the package authors, and more.


实现反向功能：通过参数名以及dbus的类型签名，生成对应的转换DBus值的方法。

String nativeToDBusValue(String name, String signature) {
// ....
}


final toNative = nativeToDBusValue("value", "s");
// 输出
// "DBusString(value)";

final toNative = nativeToDBusValue("value", "u");
// 输出
// "DBusUint32(value)";

final toNative = nativeToDBusValue("value", "n");
// 输出
// "DBusInt16(value)";

final toNative = nativeToDBusValue("value", "b");
// 输出
// "DBusBoolean(value)";

final toNative = nativeToDBusValue("value", "h");
// 输出
// "DBusUnixFd(value)";

final toNative = nativeToDBusValue("value", "as");
// 输出
// "DBusArray(DBusSignature("s"), value.map((i1) => DBusString(i1)))";

final toNative = nativeToDBusValue("value", "a{sv}");
// 输出
// "DBusDict(DBusSignature("s"), DBusSignature("v"), value.map((k1, v1) => MapEntry(DBusString(k1), DBusVariant(v1))))"

final toNative = nativeToDBusValue("value", "a{sa{sv}}");
// 输出
// "DBusDict(DBusSignature("s"), DBusSignature("a{sv}"), value.map((k1, v1) => MapEntry(DBusString(k1), DBusDict(DBusSignature("s"), DBusSignature("v"), v1.map((k2, v2) => MapEntry(DBusString(k2), DBusVariant(v2)))))))"

final toNative = nativeToDBusValue("value", "a(yya(y))");
// 输出
// "DBusArray(DBusSignature("a(yya(y))"), value.map((i1) => DBusStruct([DBusByte(i1.$1), DBusByte(i1.$2), DBusArray(DBusSignature("b"), i1.$3.map((i2) => DBusByte(i2)))])))"


类型为"o"时，需要特殊处理，因为输入类型必定为"DBusObjectPath"。

final toNative = nativeToDBusValue("value", "o");
// 输出
// "value"

final toNative = nativeToDBusValue("value", "ao");
// 输出
// "DBusArray(DBusSignature("o"), value)"
