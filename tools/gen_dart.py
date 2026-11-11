import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from gen_models import MODELS, parse, write  # noqa: E402

OUT = "dart/lib/src/models.dart"


def dart_type(kind):
    if kind == "s":
        return "String?"
    if kind == "i":
        return "int?"
    if kind == "f":
        return "double?"
    if kind == "b":
        return "bool?"
    if kind == "t":
        return "DateTime?"
    if kind == "[s]":
        return "List<String>"
    if kind == "{f}":
        return "Map<String, double>"
    if kind.startswith("["):
        return "List<%s>" % kind[1:-1]
    if kind.startswith("{"):
        return "Map<String, %s>" % kind[1:-1]
    return kind + "?"


def dart_default(kind):
    if kind.startswith("["):
        return " = const []"
    if kind.startswith("{"):
        return " = const {}"
    return ""


def dart_read(fname, kind):
    value = "json['%s']" % fname
    if kind == "s":
        return "readString(%s)" % value
    if kind == "i":
        return "readInt(%s)" % value
    if kind == "f":
        return "readDouble(%s)" % value
    if kind == "b":
        return "readBool(%s)" % value
    if kind == "t":
        return "readDateTime(%s)" % value
    if kind == "[s]":
        return "readStrings(%s)" % value
    if kind == "{f}":
        return "readDoubles(%s)" % value
    if kind.startswith("["):
        return "readList(%s, %s.fromJson)" % (value, kind[1:-1])
    if kind.startswith("{"):
        return "readMap(%s, %s.fromJson)" % (value, kind[1:-1])
    return "readObject(%s, %s.fromJson)" % (value, kind)


def gen():
    lines = ["import 'convert.dart';", "", "typedef ZReport = Map<String, dynamic>;", ""]
    for name, _, spec in MODELS:
        fields = parse(spec)
        lines.append("class %s {" % name)
        lines.append("  const %s({" % name)
        for fname, kind, _, _ in fields:
            lines.append("    this.%s%s," % (fname, dart_default(kind)))
        lines.append("    this.raw = const {},")
        lines.append("  });")
        lines.append("")
        lines.append("  factory %s.fromJson(Map<String, dynamic> json) => %s(" % (name, name))
        for fname, kind, _, _ in fields:
            lines.append("    %s: %s," % (fname, dart_read(fname, kind)))
        lines.append("    raw: Map.unmodifiable(json),")
        lines.append("  );")
        lines.append("")
        for fname, kind, _, _ in fields:
            lines.append("  final %s %s;" % (dart_type(kind), fname))
        lines.append("  final Map<String, dynamic> raw;")
        lines.append("}")
        lines.append("")
    write(OUT, "\n".join(lines).rstrip() + "\n")


if __name__ == "__main__":
    gen()
