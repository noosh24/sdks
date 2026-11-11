import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from gen_models import MODELS, parse, write  # noqa: E402

PACKAGE = "com.noosh24.openapi.model"
OUT = "java/src/main/java/com/noosh24/openapi/model/%s.java"

SCALARS = {
    "s": ("String", "string"),
    "i": ("Integer", "integer"),
    "f": ("Double", "number"),
    "b": ("Boolean", "bool"),
    "t": ("OffsetDateTime", "dateTime"),
}


def java_type(kind):
    if kind in SCALARS:
        return "@Nullable " + SCALARS[kind][0]
    if kind == "[s]":
        return "List<String>"
    if kind == "{f}":
        return "Map<String, Double>"
    if kind.startswith("["):
        return "List<%s>" % kind[1:-1]
    if kind.startswith("{"):
        return "Map<String, %s>" % kind[1:-1]
    return "@Nullable " + kind


def java_read(name, kind):
    key = '"%s"' % name
    if kind in SCALARS:
        return "Fields.%s(n, %s)" % (SCALARS[kind][1], key)
    if kind == "[s]":
        return "Fields.strings(n, %s)" % key
    if kind == "{f}":
        return "Fields.doubles(n, %s)" % key
    if kind.startswith("["):
        return "Fields.list(n, %s, %s::from)" % (key, kind[1:-1])
    if kind.startswith("{"):
        return "Fields.map(n, %s, %s::from)" % (key, kind[1:-1])
    return "Fields.object(n, %s, %s::from)" % (key, kind)


def is_collection(kind):
    return kind.startswith("[") or kind.startswith("{")


def gen_model(name, spec):
    fields = parse(spec)
    kinds = [kind for _, kind, _, _ in fields]
    imports = [
        "com.fasterxml.jackson.annotation.JsonIgnore",
        "com.fasterxml.jackson.annotation.JsonIgnoreProperties",
    ]
    if "t" in kinds:
        imports.append("java.time.OffsetDateTime")
    if any(k.startswith("[") for k in kinds):
        imports.append("java.util.List")
    if any(k.startswith("{") for k in kinds):
        imports.append("java.util.Map")
    imports += ["org.jspecify.annotations.Nullable", "tools.jackson.databind.JsonNode"]

    lines = ["package %s;" % PACKAGE, ""]
    lines += ["import %s;" % item for item in imports]
    lines += ["", "@JsonIgnoreProperties(ignoreUnknown = true)", "public record %s(" % name]
    for fname, kind, _, _ in fields:
        lines.append("        %s %s," % (java_type(kind), fname))
    lines.append("        @JsonIgnore @Nullable JsonNode raw) {")
    collections = [fname for fname, kind, _, _ in fields if is_collection(kind)]
    if collections:
        lines.append("")
        lines.append("    public %s {" % name)
        for fname in collections:
            lines.append("        %s = Fields.copy(%s);" % (fname, fname))
        lines.append("    }")
    lines += [
        "",
        "    public static %s from(@Nullable JsonNode node) {" % name,
        "        JsonNode n = Fields.object(node);",
        "        return new %s(" % name,
    ]
    for fname, kind, _, _ in fields:
        lines.append("                %s," % java_read(fname, kind))
    lines += ["                n);", "    }", "}", ""]
    write(OUT % name, "\n".join(lines))


def main():
    for name, _, spec in MODELS:
        gen_model(name, spec)


if __name__ == "__main__":
    main()
