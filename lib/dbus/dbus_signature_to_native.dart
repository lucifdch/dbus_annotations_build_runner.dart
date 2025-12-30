String dbusSignatureToNative(String signature) {
  final p = _SigParser(signature);
  final node = p.parseType();
  p.expectEof();

  // 生成时假设当前 DBusValue 变量名是 "value"
  // 返回的是后缀（以 "." 开头），和你示例一致
  return _Gen().suffixFor(node, varName: 'value', depth: 0).replaceFirst('value', '');
}

sealed class _T {}

class _Prim extends _T {
  final String code; // 's','u','b','y','i'...
  _Prim(this.code);
}

class _Array extends _T {
  final _T elem;

  _Array(this.elem);
}

class _Dict extends _T {
  final _T key;
  final _T value;

  _Dict(this.key, this.value);
}

class _Struct extends _T {
  final List<_T> fields;

  _Struct(this.fields);
}

class _SigParser {
  final String s;
  int i = 0;

  _SigParser(this.s);

  bool get eof => i >= s.length;

  String peek() => s[i];

  void expect(String ch) {
    if (eof || s[i] != ch) {
      throw FormatException('Expected "$ch" at $i in "$s"');
    }
    i++;
  }

  void expectEof() {
    if (!eof) {
      throw FormatException('Trailing signature at $i in "$s": "${s.substring(i)}"');
    }
  }

  _T parseType() {
    if (eof) throw FormatException('Unexpected EOF in "$s"');

    final ch = peek();

    // Array or Dict
    if (ch == 'a') {
      i++;
      if (!eof && peek() == '{') {
        // dict entry a{KV}
        i++; // skip '{'
        final k = parseType();
        final v = parseType();
        expect('}');
        return _Dict(k, v);
      }
      final elem = parseType();
      return _Array(elem);
    }

    // Struct
    if (ch == '(') {
      i++; // skip '('
      final fields = <_T>[];
      while (!eof && peek() != ')') {
        fields.add(parseType());
      }
      expect(')');
      return _Struct(fields);
    }

    // Primitive / basic / variant etc. (single letter)
    // DBus basic types include: y b n q i u x t d s o g h v
    // (可以按需扩展)
    i++;
    return _Prim(ch);
  }
}

class _Gen {
  String suffixFor(_T t, {required String varName, required int depth}) {
    if (t is _Prim) return _primSuffix(t.code);

    if (t is _Array) {
      final itemVar = 'i${depth + 1}';
      final base = '$varName.asArray()';

      final itemExpr = exprFor(t.elem, varName: itemVar, depth: depth + 1);

      // 单元素 map + toList
      return '$base.map(($itemVar) => $itemExpr).toList()';
    }

    if (t is _Dict) {
      final kVar = 'k${depth + 1}';
      final vVar = 'v${depth + 1}';
      final base = '$varName.asDict()';

      final kExpr = exprFor(t.key, varName: kVar, depth: depth + 1, isDictKey: true);
      final vExpr = exprFor(t.value, varName: vVar, depth: depth + 1);

      return '$base.map(($kVar, $vVar) => MapEntry($kExpr, $vExpr))';
    }

    if (t is _Struct) {
      // 生成一个立即执行闭包，避免污染外部变量名
      final sVar = 's${depth + 1}';
      final items = <String>[];
      for (var idx = 0; idx < t.fields.length; idx++) {
        final fieldVar = '$sVar[$idx]';
        items.add(exprFor(t.fields[idx], varName: fieldVar, depth: depth + 1));
      }

      // 用 Dart record 表达 (a, b, c)
      final record = '(${items.join(', ')})';
      return '(() { final $sVar = $varName.asStruct(); return $record; })()';
    }

    throw StateError('Unknown type node: $t');
  }

  /// 生成“完整表达式”（含 varName），用于 map/MapEntry 的 RHS
  String exprFor(_T t, {required String varName, required int depth, bool isDictKey = false}) {
    if (t is _Prim) {
      final suf = _primSuffix(t.code);
      // suf 形如 ".asUint32()"，所以这里直接拼在变量后面
      return '$varName$suf';
    }

    // 复杂类型：直接递归生成完整表达式（suffixFor 返回的是 "varName.xxx" 形式）
    return suffixFor(t, varName: varName, depth: depth);
  }

  String _primSuffix(String code) {
    switch (code) {
      case 'y':
        return '.asByte()';
      case 'b':
        return '.asBoolean()';
      case 'n':
        return '.asInt16()';
      case 'q':
        return '.asUint16()';
      case 'i':
        return '.asInt32()';
      case 'u':
        return '.asUint32()';
      case 'x':
        return '.asInt64()';
      case 't':
        return '.asUint64()';
      case 'd':
        return '.asDouble()';
      case 's':
        return '.asString()';
      case 'o':
        return '.asObjectPath()';
      case 'g':
        return '.asSignatureString()';
      case 'v':
        return '.asVariant()';
      // case 'm':
      //   return '.asMaybe()';
      case 'h':
        return '.asUnixFd()';
      default:
        throw UnsupportedError('Unsupported DBus type code: "$code"');
    }
  }
}

String nativeToDBusValue(String name, String signature) {
  final p = _SigParser(signature);
  final node = p.parseType();
  p.expectEof();

  return _NativeToDbusGen(fullSignature: signature).exprFor(node, varName: name, depth: 0);
}

class _NativeToDbusGen {
  final String fullSignature;

  _NativeToDbusGen({required this.fullSignature});

  /// 生成“把本地值 varName 转成 DBusValue”的完整表达式
  String exprFor(_T t, {required String varName, required int depth}) {
    if (t is _Prim) return _primExpr(t.code, varName);

    if (t is _Array) {
      // 特殊：ao -> DBusArray(DBusSignature("o"), value)（不 map）
      if (_isObjectPathPrim(t.elem)) {
        return 'DBusArray(DBusSignature("o"), $varName)';
      }

      final itemVar = 'i${depth + 1}';
      final elemSig = signatureOf(t.elem);

      // 你给的示例里：a(yya(y)) 用了 "a(yya(y))"（而不是 "(yya(y))"）
      // 这里按示例：若数组元素是 struct，则用 fullSignature；否则用元素签名
      final sigForArrayCtor = (t.elem is _Struct) ? fullSignature : elemSig;

      final itemExpr = exprFor(t.elem, varName: itemVar, depth: depth + 1);
      return 'DBusArray(DBusSignature("$sigForArrayCtor"), $varName.map(($itemVar) => $itemExpr))';
    }

    if (t is _Dict) {
      final kVar = 'k${depth + 1}';
      final vVar = 'v${depth + 1}';
      final kSig = signatureOf(t.key);
      final vSig = signatureOf(t.value);

      final kExpr = exprFor(t.key, varName: kVar, depth: depth + 1);
      final vExpr = exprFor(t.value, varName: vVar, depth: depth + 1);

      return 'DBusDict(DBusSignature("$kSig"), DBusSignature("$vSig"), '
          '$varName.map(($kVar, $vVar) => MapEntry($kExpr, $vExpr)))';
    }

    if (t is _Struct) {
      // 结构体输入按 record：i1.$1, i1.$2, ...
      final parts = <String>[];
      for (var idx = 0; idx < t.fields.length; idx++) {
        final fieldVar = '$varName.\$${idx + 1}';
        parts.add(exprFor(t.fields[idx], varName: fieldVar, depth: depth + 1));
      }
      return 'DBusStruct([${parts.join(', ')}])';
    }

    throw StateError('Unknown type node: $t');
  }

  /// 节点还原成 DBus signature 字符串（用于 DBusSignature("...")）
  String signatureOf(_T t) {
    if (t is _Prim) return t.code;

    if (t is _Array) {
      // 标准还原：a + elemSig
      // dict 在 parser 里已经单独处理成 _Dict
      return 'a${signatureOf(t.elem)}';
    }

    if (t is _Dict) {
      return 'a{${signatureOf(t.key)}${signatureOf(t.value)}}';
    }

    if (t is _Struct) {
      return '(${t.fields.map(signatureOf).join()})';
    }

    throw StateError('Unknown type node: $t');
  }

  bool _isObjectPathPrim(_T t) => t is _Prim && t.code == 'o';

  String _primExpr(String code, String varName) {
    switch (code) {
      case 's':
        return 'DBusString($varName)';
      case 'u':
        return 'DBusUint32($varName)';
      case 'n':
        return 'DBusInt16($varName)';
      case 'b':
        return 'DBusBoolean($varName)';
      case 'h':
        return 'DBusUnixFd($varName)';

      // 你要求：类型为 "o" 时输入必定为 DBusObjectPath，直接返回变量
      case 'o':
        return varName;

      // 其它基础类型（按你现有 asXxx 对应补齐）
      case 'y':
        return 'DBusByte($varName)';
      case 'q':
        return 'DBusUint16($varName)';
      case 'i':
        return 'DBusInt32($varName)';
      case 'x':
        return 'DBusInt64($varName)';
      case 't':
        return 'DBusUint64($varName)';
      case 'd':
        return 'DBusDouble($varName)';
      case 'g':
        return 'DBusSignature($varName)'; // 如果你项目里不是这样，改成对应构造
      case 'v':
        return 'DBusVariant($varName)';

      default:
        throw UnsupportedError('Unsupported DBus type code: "$code"');
    }
  }
}
