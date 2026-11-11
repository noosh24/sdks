import os

from gen_models import ENUMS, MODELS, ROOT, parse, write

OUT = "dotnet/src/Noosh24.OpenApi"


def pascal(name):
    return "".join(part[:1].upper() + part[1:] for part in name.split("_") if part)


def cs_type(kind):
    if kind == "s":
        return "string?"
    if kind == "i":
        return "int?"
    if kind == "f":
        return "double?"
    if kind == "b":
        return "bool?"
    if kind == "t":
        return "DateTimeOffset?"
    if kind == "[s]":
        return "IReadOnlyList<string>?"
    if kind == "{f}":
        return "IReadOnlyDictionary<string, double>?"
    if kind.startswith("["):
        return "IReadOnlyList<%s>?" % kind[1:-1]
    if kind.startswith("{"):
        return "IReadOnlyDictionary<string, %s>?" % kind[1:-1]
    return kind + "?"


def gen_models():
    lines = [
        "using System.Text.Json;",
        "using System.Text.Json.Serialization;",
        "",
        "namespace Noosh24.OpenApi;",
        "",
    ]
    for name, _, spec in MODELS:
        lines.append("public sealed record %s" % name)
        lines.append("{")
        for fname, kind, _, _ in parse(spec):
            lines.append('    [JsonPropertyName("%s")]' % fname)
            lines.append("    public %s %s { get; init; }" % (cs_type(kind), pascal(fname)))
            lines.append("")
        lines.append("    [JsonExtensionData]")
        lines.append("    [JsonInclude]")
        lines.append("    public IDictionary<string, JsonElement>? ExtensionData { get; internal set; }")
        lines.append("}")
        lines.append("")
    write(OUT + "/Models.cs", "\n".join(lines).rstrip() + "\n")


def gen_enums():
    lines = ["namespace Noosh24.OpenApi;", ""]
    for (model, fname), values in ENUMS.items():
        lines.append("public static class %s%s" % (model, pascal(fname)))
        lines.append("{")
        for value in values:
            lines.append('    public const string %s = "%s";' % (pascal(value), value))
        lines.append("}")
        lines.append("")
    write(OUT + "/Enums.cs", "\n".join(lines).rstrip() + "\n")


def gen_context():
    lines = [
        "using System.Text.Json;",
        "using System.Text.Json.Serialization;",
        "",
        "namespace Noosh24.OpenApi;",
        "",
    ]
    for name, _, _ in MODELS:
        lines.append("[JsonSerializable(typeof(%s))]" % name)
    lines += [
        "[JsonSerializable(typeof(NewReservation))]",
        "[JsonSerializable(typeof(Dictionary<string, JsonElement>))]",
        "internal sealed partial class Noosh24JsonContext : JsonSerializerContext",
        "{",
        "}",
        "",
    ]
    write(OUT + "/Noosh24JsonContext.cs", "\n".join(lines))


if __name__ == "__main__":
    gen_models()
    gen_enums()
    gen_context()
    print("wrote", os.path.join(ROOT, OUT))
