import os
import re
import shutil
import subprocess
import sys

sys.dont_write_bytecode = True
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from gen_models import ENUMS, MODELS, ROOT, parse

INITIALISMS = {"id": "ID", "ids": "IDs", "url": "URL"}


def go_name(name):
    words = re.findall(r"[A-Z]?[a-z0-9]+|[A-Z]+(?![a-z])", name)
    return "".join(INITIALISMS.get(w.lower(), w[0].upper() + w[1:]) for w in words)


def enum_type(model, fname):
    return model + go_name(fname)


def enum_const(model, fname, value):
    return enum_type(model, fname) + "".join(part[:1].upper() + part[1:] for part in value.split("_"))


def go_type(model, fname, kind, nullable):
    if (model, fname) in ENUMS:
        return ("*" if nullable else "") + enum_type(model, fname)
    scalar = {"s": "string", "i": "int", "f": "float64", "b": "bool", "t": "time.Time"}
    if kind in scalar:
        return ("*" if nullable else "") + scalar[kind]
    if kind == "[s]":
        return "[]string"
    if kind == "{f}":
        return "map[string]float64"
    if kind.startswith("["):
        return "[]" + kind[1:-1]
    if kind.startswith("{"):
        return "map[string]" + kind[1:-1]
    return "*" + kind


def go_read(model, fname, kind, nullable):
    raw = 'f["%s"]' % fname
    if (model, fname) in ENUMS:
        if nullable:
            return "(*%s)(stringPtr(%s))" % (enum_type(model, fname), raw)
        return "%s(stringValue(%s))" % (enum_type(model, fname), raw)
    scalar = {"s": "string", "i": "int", "f": "float", "b": "bool", "t": "time"}
    if kind in scalar:
        return "%s%s(%s)" % (scalar[kind], "Ptr" if nullable else "Value", raw)
    if kind == "[s]":
        return "stringList(%s)" % raw
    if kind == "{f}":
        return "floatMap(%s)" % raw
    if kind.startswith("["):
        return "listOf[%s](%s)" % (kind[1:-1], raw)
    if kind.startswith("{"):
        return "mapOf[%s](%s)" % (kind[1:-1], raw)
    return "object[%s](%s)" % (kind, raw)


def generate():
    lines = [
        "package noosh24",
        "",
        "import (",
        '\t"encoding/json"',
        '\t"time"',
        ")",
        "",
    ]
    for (model, fname), values in ENUMS.items():
        name = enum_type(model, fname)
        lines.append("type %s string" % name)
        lines.append("")
        lines.append("const (")
        for value in values:
            lines.append('\t%s %s = "%s"' % (enum_const(model, fname, value), name, value))
        lines.append(")")
        lines.append("")
    for name, _, spec in MODELS:
        fields = parse(spec)
        lines.append("type %s struct {" % name)
        for fname, kind, nullable, optional in fields:
            tag = fname + (",omitempty" if optional else "")
            lines.append('\t%s %s `json:"%s"`' % (go_name(fname), go_type(name, fname, kind, nullable), tag))
        lines.append('\tRawJSON json.RawMessage `json:"-"`')
        lines.append("}")
        lines.append("")
        lines.append("func (m *%s) UnmarshalJSON(data []byte) error {" % name)
        lines.append("\tf, ok := objectFields(data)")
        lines.append("\tif !ok {")
        lines.append("\t\t*m = %s{}" % name)
        lines.append("\t\treturn nil")
        lines.append("\t}")
        lines.append("\t*m = %s{" % name)
        for fname, kind, nullable, _ in fields:
            lines.append("\t\t%s: %s," % (go_name(fname), go_read(name, fname, kind, nullable)))
        lines.append("\t\tRawJSON: cloneRaw(data),")
        lines.append("\t}")
        lines.append("\treturn nil")
        lines.append("}")
        lines.append("")
    path = os.path.join(ROOT, "go", "models.go")
    with open(path, "w") as out:
        out.write("\n".join(lines))
    gofmt = shutil.which("gofmt")
    if gofmt:
        subprocess.run([gofmt, "-w", path], check=True)
    return path


if __name__ == "__main__":
    print(generate())
